import '../../../../core/time/server_clock.dart';

/// One ordered universal-request item, captured from
/// `_universal_request_order_details[i]` in the my-tickets response.
class UniversalTicketItem {
  final String id;
  final String item;
  final String emoji;
  final String? thumbnailUrl;
  final Map<String, String> nameI18n;
  final int etaStart;
  final int etaEnd;
  final int slaTargetMinutes;

  const UniversalTicketItem({
    required this.id,
    required this.item,
    required this.emoji,
    this.thumbnailUrl,
    this.nameI18n = const {},
    this.etaStart = 0,
    this.etaEnd = 0,
    this.slaTargetMinutes = 0,
  });
}

/// One catalog item line captured from
/// `_service_catalog_order_details.order_item_details.items[i]`.
class CatalogTicketItem {
  final String itemName;
  final String? imageUrl;
  final int quantity;
  final double unitPrice;
  final double lineTotal;

  const CatalogTicketItem({
    required this.itemName,
    this.imageUrl,
    this.quantity = 1,
    this.unitPrice = 0,
    this.lineTotal = 0,
  });
}

/// Trimmed catalog order summary captured from
/// `_service_catalog_order_details`. Only fields the list view needs.
class CatalogTicketDetails {
  final String catalogName;
  final String? logoUrl;
  final String? brandColorHex;
  final double grandTotal;
  final String currency;
  final List<CatalogTicketItem> items;
  final int slaTargetMinutes;

  const CatalogTicketDetails({
    required this.catalogName,
    this.logoUrl,
    this.brandColorHex,
    required this.grandTotal,
    required this.currency,
    required this.items,
    this.slaTargetMinutes = 0,
  });
}

/// Manual ticket payload captured from `_manual_ticket_details`. The
/// real `summary` and `details` live here for manual tickets — the
/// top-level `issue_summary` / `issue_details` are typically empty.
class ManualTicketDetails {
  final String summary;
  final String details;

  const ManualTicketDetails({required this.summary, required this.details});
}

/// Domain entity for My Ticket from get_my_tickets API.
class MyTicket {
  final String id;
  final String opsTicketId;
  final int createdAt;
  final int updatedAt;
  final int lastTransitionAt;
  final bool slaBreached;
  final bool overdue;
  final bool needsAttention;
  final String hotelId;
  final String departmentId;
  final String? departmentName;
  final String? departmentMobileIcon;
  final String? departmentIconUrl;
  final String? departmentCode;
  final String? assignedToUserId;
  /// Resolved display name from the `_user` block (e.g. "Kiran R. C.").
  final String? assigneeName;
  final String createdByUserId;
  final bool createdByAi;
  final String type;
  final String? ticketType;
  final String status;
  final int dueAt;
  final int dueAtWithGrace;
  final String category;
  final String priority;
  final String issueSummary;
  final String issueDetails;
  final bool isIncident;
  final String incidentNotes;
  final String room;
  final String guestName;
  final String? acknowledgedByUserId;
  final int acknowledgedAt;
  final String resolutionCode;
  final String resolutionNotes;
  final int confirmedAt;
  final String? closedAt;
  final RoomDetails? roomDetails;
  final bool isTransitioning;

  /// Per-kind detail blocks. Exactly one is populated for any given
  /// ticket — pick by [ticketType].
  final List<UniversalTicketItem> universalItems;
  final CatalogTicketDetails? catalogDetails;
  final ManualTicketDetails? manualDetails;

  const MyTicket({
    required this.id,
    this.opsTicketId = '',
    required this.createdAt,
    this.updatedAt = 0,
    this.lastTransitionAt = 0,
    this.slaBreached = false,
    this.overdue = false,
    this.needsAttention = false,
    required this.hotelId,
    required this.departmentId,
    this.departmentName,
    this.departmentMobileIcon,
    this.departmentIconUrl,
    this.departmentCode,
    this.assignedToUserId,
    this.assigneeName,
    required this.createdByUserId,
    required this.createdByAi,
    required this.type,
    this.ticketType,
    required this.status,
    required this.dueAt,
    this.dueAtWithGrace = 0,
    required this.category,
    required this.priority,
    required this.issueSummary,
    required this.issueDetails,
    required this.isIncident,
    required this.incidentNotes,
    required this.room,
    required this.guestName,
    this.acknowledgedByUserId,
    required this.acknowledgedAt,
    required this.resolutionCode,
    required this.resolutionNotes,
    required this.confirmedAt,
    this.closedAt,
    this.roomDetails,
    this.isTransitioning = false,
    this.universalItems = const [],
    this.catalogDetails,
    this.manualDetails,
  });

  MyTicket copyWith({
    String? id,
    String? opsTicketId,
    int? createdAt,
    int? updatedAt,
    int? lastTransitionAt,
    bool? slaBreached,
    bool? overdue,
    bool? needsAttention,
    String? hotelId,
    String? departmentId,
    String? departmentName,
    String? departmentMobileIcon,
    String? departmentIconUrl,
    String? departmentCode,
    String? assignedToUserId,
    String? assigneeName,
    String? createdByUserId,
    bool? createdByAi,
    String? type,
    String? ticketType,
    String? status,
    int? dueAt,
    int? dueAtWithGrace,
    String? category,
    String? priority,
    String? issueSummary,
    String? issueDetails,
    bool? isIncident,
    String? incidentNotes,
    String? room,
    String? guestName,
    String? acknowledgedByUserId,
    int? acknowledgedAt,
    String? resolutionCode,
    String? resolutionNotes,
    int? confirmedAt,
    String? closedAt,
    RoomDetails? roomDetails,
    bool? isTransitioning,
    List<UniversalTicketItem>? universalItems,
    CatalogTicketDetails? catalogDetails,
    ManualTicketDetails? manualDetails,
  }) {
    return MyTicket(
      id: id ?? this.id,
      opsTicketId: opsTicketId ?? this.opsTicketId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastTransitionAt: lastTransitionAt ?? this.lastTransitionAt,
      slaBreached: slaBreached ?? this.slaBreached,
      overdue: overdue ?? this.overdue,
      needsAttention: needsAttention ?? this.needsAttention,
      hotelId: hotelId ?? this.hotelId,
      departmentId: departmentId ?? this.departmentId,
      departmentName: departmentName ?? this.departmentName,
      departmentMobileIcon: departmentMobileIcon ?? this.departmentMobileIcon,
      departmentIconUrl: departmentIconUrl ?? this.departmentIconUrl,
      departmentCode: departmentCode ?? this.departmentCode,
      assignedToUserId: assignedToUserId ?? this.assignedToUserId,
      assigneeName: assigneeName ?? this.assigneeName,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      createdByAi: createdByAi ?? this.createdByAi,
      type: type ?? this.type,
      ticketType: ticketType ?? this.ticketType,
      status: status ?? this.status,
      dueAt: dueAt ?? this.dueAt,
      dueAtWithGrace: dueAtWithGrace ?? this.dueAtWithGrace,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      issueSummary: issueSummary ?? this.issueSummary,
      issueDetails: issueDetails ?? this.issueDetails,
      isIncident: isIncident ?? this.isIncident,
      incidentNotes: incidentNotes ?? this.incidentNotes,
      room: room ?? this.room,
      guestName: guestName ?? this.guestName,
      acknowledgedByUserId: acknowledgedByUserId ?? this.acknowledgedByUserId,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      resolutionCode: resolutionCode ?? this.resolutionCode,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      closedAt: closedAt ?? this.closedAt,
      roomDetails: roomDetails ?? this.roomDetails,
      isTransitioning: isTransitioning ?? this.isTransitioning,
      universalItems: universalItems ?? this.universalItems,
      catalogDetails: catalogDetails ?? this.catalogDetails,
      manualDetails: manualDetails ?? this.manualDetails,
    );
  }

  /// Check if ticket is NEW (incoming)
  bool get isIncoming => status.toUpperCase() == 'NEW';

  /// Check if ticket is ACCEPTED
  bool get isAccepted => status.toUpperCase() == 'ACCEPTED';

  /// Check if ticket is in progress
  bool get isInProgress => status.toUpperCase() == 'IN_PROGRESS';

  /// Check if ticket is on hold (rendered as "Scheduled" in the UI)
  bool get isOnHold => status.toUpperCase() == 'ON_HOLD';

  /// Check if ticket is done
  bool get isDone => status.toUpperCase() == 'DONE';

  /// Check if ticket is canceled. Accepts both spellings during the
  /// rollout — backend authoritative is `CANCELED`.
  bool get isCanceled =>
      status.toUpperCase() == 'CANCELED' || status.toUpperCase() == 'CANCELLED';

  /// Check if ticket is expired (server-driven, no client transition).
  bool get isExpired => status.toUpperCase() == 'EXPIRED';

  /// Check if ticket is overdue.
  ///
  /// True when either:
  /// - the server has flagged `sla_breached`, or
  /// - `due_at` is in the past and the ticket is not in a terminal state
  ///   (DONE / CANCELED / EXPIRED).
  bool get isOverdue {
    if (isDone || isCanceled || isExpired) return false;
    if (slaBreached) return true;
    if (dueAt == 0) return false;
    return DateTime.fromMillisecondsSinceEpoch(dueAt).isBefore(ServerClock.now());
  }
}

/// Room details for MyTicket.
class RoomDetails {
  final String id;
  final String onbRoomNumber;
  final String floorId;
  final String onbRoomTypeId;

  const RoomDetails({
    required this.id,
    required this.onbRoomNumber,
    required this.floorId,
    required this.onbRoomTypeId,
  });
}

/// Best-effort timestamp for "when did this ticket reach its current status".
///
/// The backend doesn't ship a dedicated `status_changed_at` field, so we
/// infer from whichever timestamp the model already carries:
///
/// - DONE        → confirmedAt → acknowledgedAt → createdAt
/// - IN_PROGRESS → acknowledgedAt → createdAt
/// - ACCEPTED    → acknowledgedAt → createdAt
/// - NEW (other) → createdAt
///
/// Realtime events override this with [DateTime.now] at the moment the
/// event is observed (see [MyTicketsState.statusChangedAt]).
int defaultStatusChangedAt(MyTicket t) {
  // The /tickets/get_my_tickets endpoint provides last_transition_at
  // directly, so prefer it whenever it is populated.
  if (t.lastTransitionAt > 0) return t.lastTransitionAt;
  switch (t.status.toUpperCase()) {
    case 'DONE':
      if (t.confirmedAt > 0) return t.confirmedAt;
      if (t.acknowledgedAt > 0) return t.acknowledgedAt;
      return t.createdAt;
    case 'IN_PROGRESS':
    case 'ACCEPTED':
    case 'ON_HOLD':
      if (t.acknowledgedAt > 0) return t.acknowledgedAt;
      return t.createdAt;
    case 'CANCELED':
    case 'CANCELLED':
    case 'EXPIRED':
      if (t.acknowledgedAt > 0) return t.acknowledgedAt;
      return t.createdAt;
    default:
      return t.createdAt;
  }
}

/// State holder for my tickets with counts.
class MyTicketsState {
  final List<MyTicket> all;
  final bool isLoading;
  final String? error;

  /// Realtime overrides for `status_changed_at`. Populated whenever a
  /// realtime upsert is observed — keyed by ticket id, value is the
  /// `DateTime.now().millisecondsSinceEpoch` at the time of the event.
  final Map<String, int> statusChangedAt;

  /// Tickets that arrived via realtime within the last 3 seconds. Used to
  /// drive the slide-in + background flash on the card. Cleared by a
  /// notifier-side timer.
  final Set<String> freshlyArrivedIds;

  /// Per-ticket epoch ms of the most recent realtime change (creation OR
  /// status transition). Drives the green-border highlight on the card. The
  /// notifier prunes entries older than the highlight window via timer; the
  /// UI also defends against staleness by checking `now - ts < window`.
  final Map<String, int> recentChangeAt;

  const MyTicketsState({
    this.all = const [],
    this.isLoading = false,
    this.error,
    this.statusChangedAt = const {},
    this.freshlyArrivedIds = const {},
    this.recentChangeAt = const {},
  });

  MyTicketsState copyWith({
    List<MyTicket>? all,
    bool? isLoading,
    String? error,
    Map<String, int>? statusChangedAt,
    Set<String>? freshlyArrivedIds,
    Map<String, int>? recentChangeAt,
  }) {
    return MyTicketsState(
      all: all ?? this.all,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      statusChangedAt: statusChangedAt ?? this.statusChangedAt,
      freshlyArrivedIds: freshlyArrivedIds ?? this.freshlyArrivedIds,
      recentChangeAt: recentChangeAt ?? this.recentChangeAt,
    );
  }

  // ───────────────────────── helpers ─────────────────────────

  int statusChangedAtFor(MyTicket t) =>
      statusChangedAt[t.id] ?? defaultStatusChangedAt(t);

  bool _isToday(int epochMs) {
    if (epochMs <= 0) return false;
    final dt = DateTime.fromMillisecondsSinceEpoch(epochMs).toLocal();
    final now = ServerClock.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  /// Today bucketing uses the ticket's **due-at** date — a ticket is "for
  /// today" iff its `due_at` falls on today's local calendar. This avoids
  /// counting a backlog ticket as Today just because the backend touched
  /// `last_transition_at` on a non-status patch (e.g. change-due-time):
  /// only when the user actually moves the due date INTO today does the
  /// ticket flip from Backlog → Today.
  ///
  /// Tickets with no `due_at` (== 0) are never in the Today bucket.
  bool _changedToday(MyTicket t) => _isToday(t.dueAt);

  // ───────────────────────── Incoming ─────────────────────────

  /// Newly received tickets that haven't been accepted yet.
  List<MyTicket> get incoming => all.where((t) => t.isIncoming).toList();
  int get incomingCount => incoming.length;

  // ───────────────────────── Today (due today) ────────────────────────────
  //
  // "Today" = active (Accepted / In Progress) tickets whose `due_at` falls
  // on today's local calendar. Buckets exclude DONE/CANCELED/EXPIRED —
  // those belong on the Done tab, not in the operator's active workload.
  //
  // Bucket predicate is `due_at` (NOT `last_transition_at`) because the
  // operator's mental model is "what's due today", and because backends
  // commonly touch `last_transition_at` on non-status patches which would
  // otherwise spuriously pull a backlog ticket into Today.
  //
  // Overdue is its own partition: a ticket past its `due_at` is reported
  // ONLY under [todayOverdue], never under [todayAccepted] or
  // [todayInProgress]. So:
  //
  //   todayAll = todayAccepted + todayInProgress + todayOverdue   (disjoint)

  bool _isActiveToday(MyTicket t) =>
      (t.isAccepted || t.isInProgress) && _changedToday(t);

  /// Active tickets (Accepted + In Progress) whose status changed today.
  /// Includes overdue — overdue is a lens, not a removal from the bucket.
  List<MyTicket> get todayAll => all.where(_isActiveToday).toList();

  /// Accepted today AND not overdue. Overdue accepted tickets surface only
  /// under [todayOverdue].
  List<MyTicket> get todayAccepted => all
      .where((t) => t.isAccepted && _changedToday(t) && !t.isOverdue)
      .toList();

  /// In Progress today AND not overdue.
  List<MyTicket> get todayInProgress => all
      .where((t) => t.isInProgress && _changedToday(t) && !t.isOverdue)
      .toList();

  List<MyTicket> get todayDone =>
      all.where((t) => t.isDone && _changedToday(t)).toList();

  /// Overdue partition — past `due_at`, status changed today, status is
  /// Accepted or In Progress. Mutually exclusive with [todayAccepted] and
  /// [todayInProgress].
  List<MyTicket> get todayOverdue => all
      .where(
        (t) =>
            (t.isAccepted || t.isInProgress) &&
            _changedToday(t) &&
            t.isOverdue,
      )
      .toList();

  int get todayAllCount => todayAll.length;
  int get todayAcceptedCount => todayAccepted.length;
  int get todayInProgressCount => todayInProgress.length;
  int get todayDoneCount => todayDone.length;
  int get todayOverdueCount => todayOverdue.length;

  // ───────────────────────── Backlog (active, NOT today) ──────────────
  // Mirrors the Today block but inverts the date predicate — active tickets
  // (Accepted / In Progress) whose `last_transition_at` is not today.
  // Carryover from previous days the operator hasn't closed out yet.

  bool _isActiveBacklog(MyTicket t) =>
      (t.isAccepted || t.isInProgress) && !_changedToday(t);

  List<MyTicket> get backlogAll => all.where(_isActiveBacklog).toList();

  List<MyTicket> get backlogAccepted => all
      .where((t) => t.isAccepted && !_changedToday(t) && !t.isOverdue)
      .toList();

  List<MyTicket> get backlogInProgress => all
      .where((t) => t.isInProgress && !_changedToday(t) && !t.isOverdue)
      .toList();

  List<MyTicket> get backlogOverdue => all
      .where(
        (t) =>
            (t.isAccepted || t.isInProgress) &&
            !_changedToday(t) &&
            t.isOverdue,
      )
      .toList();

  int get backlogAllCount => backlogAll.length;
  int get backlogAcceptedCount => backlogAccepted.length;
  int get backlogInProgressCount => backlogInProgress.length;
  int get backlogOverdueCount => backlogOverdue.length;

  // ───────────────────────── legacy aggregate counts ──────────────────────
  // Retained for callers that still display global "across all dates"
  // counts (KPIs, dashboard cards) — these don't filter by today.

  int get acceptedCount => all.where((t) => t.isAccepted).length;
  int get inProgressCount => all.where((t) => t.isInProgress).length;
  int get doneCount => all.where((t) => t.isDone).length;
  int get overdueCount => all.where((t) => t.isOverdue).length;

  /// Resolves the filter key emitted by [TicketsFilterChips] to the
  /// appropriate today-bucket. `null` / `'all'` returns every today ticket.
  List<MyTicket> todayFiltered(String? filterKey) {
    switch (filterKey) {
      case 'accepted':
        return todayAccepted;
      case 'inprogress':
        return todayInProgress;
      case 'overdue':
        return todayOverdue;
      case 'done':
        return todayDone;
      case 'all':
      case null:
      default:
        return todayAll;
    }
  }

  /// Backlog equivalent of [todayFiltered].
  List<MyTicket> backlogFiltered(String? filterKey) {
    switch (filterKey) {
      case 'accepted':
        return backlogAccepted;
      case 'inprogress':
        return backlogInProgress;
      case 'overdue':
        return backlogOverdue;
      case 'all':
      case null:
      default:
        return backlogAll;
    }
  }
}
