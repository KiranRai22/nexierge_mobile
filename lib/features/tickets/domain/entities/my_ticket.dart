/// Domain entity for My Ticket from get_my_tickets API.
class MyTicket {
  final String id;
  final int createdAt;
  final String hotelId;
  final String departmentId;
  final String? assignedToUserId;
  final String createdByUserId;
  final bool createdByAi;
  final String type;
  final String status;
  final int dueAt;
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

  const MyTicket({
    required this.id,
    required this.createdAt,
    required this.hotelId,
    required this.departmentId,
    this.assignedToUserId,
    required this.createdByUserId,
    required this.createdByAi,
    required this.type,
    required this.status,
    required this.dueAt,
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
  });

  /// Check if ticket is NEW (incoming)
  bool get isIncoming => status == 'NEW';

  /// Check if ticket is ACCEPTED
  bool get isAccepted => status == 'ACCEPTED';

  /// Check if ticket is in progress
  bool get isInProgress => status == 'IN_PROGRESS';

  /// Check if ticket is done
  bool get isDone => status == 'DONE';

  /// Check if ticket is overdue (due_at is in the past and not done)
  bool get isOverdue {
    if (dueAt == 0 || isDone) return false;
    return DateTime.fromMillisecondsSinceEpoch(dueAt).isBefore(DateTime.now());
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
  switch (t.status.toUpperCase()) {
    case 'DONE':
      if (t.confirmedAt > 0) return t.confirmedAt;
      if (t.acknowledgedAt > 0) return t.acknowledgedAt;
      return t.createdAt;
    case 'IN_PROGRESS':
    case 'ACCEPTED':
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

  const MyTicketsState({
    this.all = const [],
    this.isLoading = false,
    this.error,
    this.statusChangedAt = const {},
  });

  MyTicketsState copyWith({
    List<MyTicket>? all,
    bool? isLoading,
    String? error,
    Map<String, int>? statusChangedAt,
  }) {
    return MyTicketsState(
      all: all ?? this.all,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      statusChangedAt: statusChangedAt ?? this.statusChangedAt,
    );
  }

  // ───────────────────────── helpers ─────────────────────────

  int statusChangedAtFor(MyTicket t) =>
      statusChangedAt[t.id] ?? defaultStatusChangedAt(t);

  bool _isToday(int epochMs) {
    if (epochMs <= 0) return false;
    final dt = DateTime.fromMillisecondsSinceEpoch(epochMs).toLocal();
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  bool _changedToday(MyTicket t) => _isToday(statusChangedAtFor(t));

  // ───────────────────────── Incoming ─────────────────────────

  /// Newly received tickets that haven't been accepted yet.
  List<MyTicket> get incoming => all.where((t) => t.isIncoming).toList();
  int get incomingCount => incoming.length;

  // ───────────────────────── Today (status changed today) ──────────────────

  /// All tickets whose latest status transition happened today.
  List<MyTicket> get todayAll => all.where(_changedToday).toList();
  List<MyTicket> get todayAccepted =>
      all.where((t) => t.isAccepted && _changedToday(t)).toList();
  List<MyTicket> get todayInProgress =>
      all.where((t) => t.isInProgress && _changedToday(t)).toList();
  List<MyTicket> get todayDone =>
      all.where((t) => t.isDone && _changedToday(t)).toList();

  int get todayAllCount => todayAll.length;
  int get todayAcceptedCount => todayAccepted.length;
  int get todayInProgressCount => todayInProgress.length;
  int get todayDoneCount => todayDone.length;

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
      case 'done':
        return todayDone;
      case 'all':
      case null:
      default:
        return todayAll;
    }
  }
}
