import '../../../../core/time/server_clock.dart';
import 'department.dart';

/// Lifecycle of a ticket. Backend statuses (NEW, ACCEPTED, IN_PROGRESS,
/// ON_HOLD, DONE, CANCELED, EXPIRED, BACKLOG) map to these enum values.
/// EXPIRED folds into [canceled] for now until a dedicated UI is added.
enum TicketStatus { incoming, accepted, inProgress, onHold, done, canceled, backlog }

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

/// Per-kind data carried alongside a [Ticket]. Exactly one subtype is
/// populated for any given ticket; pick by [Ticket.kind].
sealed class TicketKindData {
  const TicketKindData();
}

class UniversalKindData extends TicketKindData {
  /// Fallback display name (typically the `item` field). Use [resolveName]
  /// to pick the locale-appropriate value.
  final String displayName;
  final String? thumbnailUrl;
  final String? emoji;
  final int itemCount;

  /// Localized name map — `{ "en": "Pillows", "es": "Almohadas" }`. Empty
  /// when the backend didn't ship a preset.
  final Map<String, String> nameI18n;

  /// ETA range from the active preset (e.g. eta_start=5, eta_end=15 → "5–15 min").
  final int etaStart;
  final int etaEnd;

  const UniversalKindData({
    required this.displayName,
    this.thumbnailUrl,
    this.emoji,
    required this.itemCount,
    this.nameI18n = const {},
    this.etaStart = 0,
    this.etaEnd = 0,
  });

  /// Picks the best display name for [languageCode] — exact match, then
  /// `en`, then [displayName].
  String resolveName(String languageCode) {
    final exact = nameI18n[languageCode];
    if (exact != null && exact.isNotEmpty) return exact;
    final en = nameI18n['en'];
    if (en != null && en.isNotEmpty) return en;
    return displayName;
  }
}

class CatalogKindData extends TicketKindData {
  final String catalogName;
  final String? logoUrl;
  final String? brandColorHex;
  final double grandTotal;
  final String currency;
  final int itemCount;
  final List<String> itemThumbnails;
  final List<String> itemNames;

  const CatalogKindData({
    required this.catalogName,
    this.logoUrl,
    this.brandColorHex,
    required this.grandTotal,
    required this.currency,
    required this.itemCount,
    required this.itemThumbnails,
    required this.itemNames,
  });
}

class ManualKindData extends TicketKindData {
  final String summary;
  final String details;

  const ManualKindData({required this.summary, required this.details});
}

/// Domain ticket model. Immutable; mutations go through the repository.
class Ticket {
  final String id; // internal id (e.g. t1)
  final String code; // human-facing (e.g. TKT-3042)
  final String title;
  final TicketKind kind;
  final TicketStatus status;
  final Department department;
  final String? departmentName;
  final String? departmentEmoji;
  final String? departmentIconUrl;
  final Room room;
  final Guest? guest;
  final List<RequestItem> items;
  final String? note;
  final String? assigneeName;
  final TicketPriority priority;
  final TicketSource? source;
  final bool isTransitioning;
  final TicketKindData? kindData;

  /// Source-of-truth timestamps. UI computes "X minutes ago" from them.
  final DateTime createdAt;
  final String? createdTime; // Formatted string from API (e.g., "May 23, 2026 01:47:06 pm")
  final DateTime? acceptedAt;
  final DateTime? doneAt;
  final DateTime? eta;

  /// `due_at_with_grace` from the API — the authoritative overdue threshold.
  /// Overdue starts when `now >= dueAtWithGrace`. Null when not set.
  final DateTime? dueAtWithGrace;

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
    this.createdTime,
    this.departmentName,
    this.departmentEmoji,
    this.departmentIconUrl,
    this.guest,
    this.note,
    this.assigneeName,
    this.acceptedAt,
    this.doneAt,
    this.eta,
    this.dueAtWithGrace,
    this.workStartedAt,
    this.priority = TicketPriority.p2,
    this.source,
    this.isTransitioning = false,
    this.kindData,
  });

  bool get isOverdue {
    if (eta == null) return false;
    if (status == TicketStatus.done || status == TicketStatus.canceled) {
      return false;
    }
    return ServerClock.now().isAfter(eta!);
  }

  Ticket copyWith({
    TicketStatus? status,
    Department? department,
    String? departmentName,
    String? departmentEmoji,
    String? departmentIconUrl,
    String? note,
    String? assigneeName,
    DateTime? acceptedAt,
    String? createdTime,
    DateTime? doneAt,
    DateTime? eta,
    DateTime? dueAtWithGrace,
    DateTime? workStartedAt,
    TicketPriority? priority,
    TicketSource? source,
    bool? isTransitioning,
    TicketKindData? kindData,
  }) {
    return Ticket(
      id: id,
      code: code,
      title: title,
      kind: kind,
      status: status ?? this.status,
      department: department ?? this.department,
      departmentName: departmentName ?? this.departmentName,
      departmentEmoji: departmentEmoji ?? this.departmentEmoji,
      departmentIconUrl: departmentIconUrl ?? this.departmentIconUrl,
      room: room,
      guest: guest,
      items: items,
      createdAt: createdAt,
      note: note ?? this.note,
      assigneeName: assigneeName ?? this.assigneeName,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      createdTime: createdTime ?? this.createdTime,
      doneAt: doneAt ?? this.doneAt,
      eta: eta ?? this.eta,
      dueAtWithGrace: dueAtWithGrace ?? this.dueAtWithGrace,
      workStartedAt: workStartedAt ?? this.workStartedAt,
      priority: priority ?? this.priority,
      source: source ?? this.source,
      isTransitioning: isTransitioning ?? this.isTransitioning,
      kindData: kindData ?? this.kindData,
    );
  }
}
