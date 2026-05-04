import 'department.dart';

/// Lifecycle of a ticket from open → done. Mirrors the prototype's grouping.
enum TicketStatus { incoming, accepted, inProgress, done, cancelled }

/// What category of ticket this is. Drives the chip colour on the card.
enum TicketKind { universal, catalog, manual }

/// Priority bucket. Drives the trailing pill in the detail header
/// (P1 red, P2 orange, P3 neutral). Stored as enum so the label is
/// resolved at render time and stays locale-independent.
enum TicketPriority { p1, p2, p3 }

/// Where the ticket originated — guest call, in-app catalog, walk-in, etc.
/// Domain enum so display labels stay locale-aware.
enum TicketSource { whatsApp, guestApp, frontDesk, phone, walkIn, system }

/// A single requested item line inside a ticket (e.g. *Towels · Bath ×2*).
/// Catalog lines additionally carry pricing + option summary.
class RequestItem {
  final String id;
  final String title;
  final String subtitle;
  final int quantity;

  /// Per-unit price (catalog lines). 0 for free items / non-priced flows.
  final double unitPrice;

  /// Total for this line (unitPrice × quantity). 0 if not priced.
  final double lineTotal;

  /// Human-readable summary of options, e.g. "Yes, Agege Bread".
  final String? optionsSummary;

  /// Display index inside its catalog group (#1, #2…). Null for non-catalog.
  final int? lineIndex;

  /// Emoji for catalog item rendering. Optional.
  final String? emoji;

  const RequestItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.quantity,
    this.unitPrice = 0,
    this.lineTotal = 0,
    this.optionsSummary,
    this.lineIndex,
    this.emoji,
  });
}

/// Room context for a ticket.
class Room {
  final String id;
  final String number;
  final int floor;
  final String? type; // "Deluxe", "Suite" etc.

  const Room({
    required this.id,
    required this.number,
    required this.floor,
    this.type,
  });
}

/// Guest context for a ticket — minimal display info only.
class Guest {
  final String id;
  final String displayName;
  final String? statusLine; // e.g. "Check-out tomorrow"

  const Guest({required this.id, required this.displayName, this.statusLine});
}

/// Domain ticket model. Immutable; mutations go through the repository.
class Ticket {
  final String id; // internal id (e.g. t1)
  final String code; // human-facing (e.g. TKT-3042)
  final String title;
  final TicketKind kind;
  final TicketStatus status;
  final Department department;
  final Room room;
  final Guest? guest;
  final List<RequestItem> items;
  final String? note;
  final String? assigneeName;
  final TicketPriority priority;
  final TicketSource? source;

  /// Source-of-truth timestamps. UI computes "X minutes ago" from them.
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? doneAt;
  final DateTime? eta;

  /// When IN_PROGRESS started — used for the elapsed work timer.
  /// Populated from statusChangedAt override when available, else acknowledgedAt.
  final DateTime? workStartedAt;

  const Ticket({
    required this.id,
    required this.code,
    required this.title,
    required this.kind,
    required this.status,
    required this.department,
    required this.room,
    required this.items,
    required this.createdAt,
    this.guest,
    this.note,
    this.assigneeName,
    this.acceptedAt,
    this.doneAt,
    this.eta,
    this.workStartedAt,
    this.priority = TicketPriority.p2,
    this.source,
  });

  bool get isOverdue {
    if (eta == null) return false;
    if (status == TicketStatus.done || status == TicketStatus.cancelled) {
      return false;
    }
    return DateTime.now().isAfter(eta!);
  }

  Ticket copyWith({
    TicketStatus? status,
    Department? department,
    String? note,
    String? assigneeName,
    DateTime? acceptedAt,
    DateTime? doneAt,
    DateTime? eta,
    DateTime? workStartedAt,
    TicketPriority? priority,
    TicketSource? source,
  }) {
    return Ticket(
      id: id,
      code: code,
      title: title,
      kind: kind,
      status: status ?? this.status,
      department: department ?? this.department,
      room: room,
      guest: guest,
      items: items,
      createdAt: createdAt,
      note: note ?? this.note,
      assigneeName: assigneeName ?? this.assigneeName,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      doneAt: doneAt ?? this.doneAt,
      eta: eta ?? this.eta,
      workStartedAt: workStartedAt ?? this.workStartedAt,
      priority: priority ?? this.priority,
      source: source ?? this.source,
    );
  }
}
