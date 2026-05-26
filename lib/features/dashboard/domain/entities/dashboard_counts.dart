/// Domain model for the dashboard KPI strip. Mapped from the
/// `dashboard/numbers` endpoint by `DashboardRepository`.
///
/// API response: {"in_progress":25,"overdue":25,"not_started":1,"done":6}
/// We map them to the dashboard cards as follows:
///   - `not_started`  → incoming (INCOMING card)
///   - `in_progress`  → inProgress
///   - `overdue`      → overdue
///   - `done`         → done
///
/// All counts are non-negative ints. Strings that fail to parse default to 0
/// so the UI never crashes on a malformed payload.
class DashboardCounts {
  final int incomingCount;      // from not_started
  final int inProgressCount;
  final int overdueCount;
  final int doneCount;

  const DashboardCounts({
    required this.incomingCount,
    required this.inProgressCount,
    required this.overdueCount,
    required this.doneCount,
  });

  static const empty = DashboardCounts(
    incomingCount: 0,
    inProgressCount: 0,
    overdueCount: 0,
    doneCount: 0,
  );

  bool get hasUnread => incomingCount > 0 || overdueCount > 0;

  DashboardCounts copyWith({
    int? incomingCount,
    int? inProgressCount,
    int? overdueCount,
    int? doneCount,
  }) {
    return DashboardCounts(
      incomingCount: incomingCount ?? this.incomingCount,
      inProgressCount: inProgressCount ?? this.inProgressCount,
      overdueCount: overdueCount ?? this.overdueCount,
      doneCount: doneCount ?? this.doneCount,
    );
  }
}
