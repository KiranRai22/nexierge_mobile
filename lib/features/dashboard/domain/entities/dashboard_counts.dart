/// Domain model for the dashboard KPI strip. Mapped from the
/// `dashboard/numbers` endpoint by `DashboardRepository`.
///
/// API today only exposes three fields (`tickets`, `due_today`, `pending`)
/// returned as strings. We map them to the four-card UI as follows:
///   - `pending`    → incoming  (Needs acknowledgment)
///   - `tickets`    → inProgress
///   - `due_today`  → overdue
///   - notStarted   → 0 (no API field yet — will be wired when backend ships)
///
/// All counts are non-negative ints. Strings that fail to parse default to 0
/// so the UI never crashes on a malformed payload.
class DashboardCounts {
  final int incomingCount;
  final int inProgressCount;
  final int overdueCount;
  final int notStartedCount;

  const DashboardCounts({
    required this.incomingCount,
    required this.inProgressCount,
    required this.overdueCount,
    required this.notStartedCount,
  });

  static const empty = DashboardCounts(
    incomingCount: 0,
    inProgressCount: 0,
    overdueCount: 0,
    notStartedCount: 0,
  );

  bool get hasUnread => incomingCount > 0 || overdueCount > 0;

  DashboardCounts copyWith({
    int? incomingCount,
    int? inProgressCount,
    int? overdueCount,
    int? notStartedCount,
  }) {
    return DashboardCounts(
      incomingCount: incomingCount ?? this.incomingCount,
      inProgressCount: inProgressCount ?? this.inProgressCount,
      overdueCount: overdueCount ?? this.overdueCount,
      notStartedCount: notStartedCount ?? this.notStartedCount,
    );
  }
}
