import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/department.dart';
import '../../domain/models/ticket.dart';
import 'repository_providers.dart';
import 'session_providers.dart';

/// Sub-tab on the dashboard.
enum TicketsSubTab { incoming, today, scheduled, done }

/// Computed view-model the dashboard renders.
class TicketsListView {
  final List<Ticket> incomingNow;
  final List<Ticket> inProgress;
  final List<Ticket> completedToday;
  final List<Ticket> scheduled;
  final int kpiIncoming;
  final int kpiInProgress;
  final int kpiOverdue;

  const TicketsListView({
    required this.incomingNow,
    required this.inProgress,
    required this.completedToday,
    required this.scheduled,
    required this.kpiIncoming,
    required this.kpiInProgress,
    required this.kpiOverdue,
  });

  bool get isEmpty =>
      incomingNow.isEmpty &&
      inProgress.isEmpty &&
      completedToday.isEmpty &&
      scheduled.isEmpty;
}

/// Sub-tab is local to the dashboard.
final ticketsSubTabProvider =
    StateProvider.autoDispose<TicketsSubTab>((ref) => TicketsSubTab.today);

/// Search query — local to the dashboard.
final ticketsSearchQueryProvider =
    StateProvider.autoDispose<String>((ref) => '');

/// Reactive bound to the repository. Recomputes whenever tickets change,
/// scope changes, sub-tab changes, search query changes, or filters change.
final ticketsListProvider =
    StreamProvider.autoDispose<TicketsListView>((ref) {
  final repo = ref.watch(ticketsRepositoryProvider);
  final scope = ref.watch(ticketScopeProvider);
  final subTab = ref.watch(ticketsSubTabProvider);
  final query = ref.watch(ticketsSearchQueryProvider).trim().toLowerCase();
  final dept = ref.watch(departmentFilterProvider);
  final session = ref.watch(operatorSessionProvider);

  return repo.watchAll().map((all) {
    final scoped = _applyScope(all, scope, session.homeDepartment, dept);
    final filtered = _applySearch(scoped, query);
    return _project(filtered, subTab);
  });
});

List<Ticket> _applyScope(
  List<Ticket> all,
  TicketScope scope,
  Department home,
  Set<Department> filter,
) {
  Iterable<Ticket> out = all;
  if (scope == TicketScope.myDept) {
    out = out.where((t) => t.department == home);
  }
  if (filter.isNotEmpty) {
    out = out.where((t) => filter.contains(t.department));
  }
  return out.toList(growable: false);
}

List<Ticket> _applySearch(List<Ticket> tickets, String query) {
  if (query.isEmpty) return tickets;
  return tickets.where((t) {
    return t.title.toLowerCase().contains(query) ||
        t.room.number.toLowerCase().contains(query) ||
        (t.guest?.displayName.toLowerCase().contains(query) ?? false) ||
        t.code.toLowerCase().contains(query);
  }).toList(growable: false);
}

TicketsListView _project(List<Ticket> tickets, TicketsSubTab subTab) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(const Duration(days: 1));

  final incomingNow = tickets
      .where((t) => t.status == TicketStatus.incoming)
      .toList(growable: false);
  final inProgress = tickets
      .where((t) => t.status == TicketStatus.inProgress ||
          t.status == TicketStatus.accepted)
      .toList(growable: false);
  final completedToday = tickets.where((t) {
    if (t.status != TicketStatus.done || t.doneAt == null) return false;
    return t.doneAt!.isAfter(today) && t.doneAt!.isBefore(tomorrow);
  }).toList(growable: false);
  final scheduled = tickets.where((t) {
    if (t.eta == null) return false;
    return t.eta!.isAfter(tomorrow);
  }).toList(growable: false);

  // Sub-tab filtering surface — KPI numbers always reflect the full snapshot
  // so the strip doesn't change when the user moves between tabs.
  final kpiIncoming = incomingNow.length;
  final kpiInProgress = inProgress.length;
  final kpiOverdue = tickets.where((t) => t.isOverdue).length;

  switch (subTab) {
    case TicketsSubTab.incoming:
      return TicketsListView(
        incomingNow: incomingNow,
        inProgress: const [],
        completedToday: const [],
        scheduled: const [],
        kpiIncoming: kpiIncoming,
        kpiInProgress: kpiInProgress,
        kpiOverdue: kpiOverdue,
      );
    case TicketsSubTab.today:
      return TicketsListView(
        incomingNow: incomingNow,
        inProgress: inProgress,
        completedToday: completedToday,
        scheduled: const [],
        kpiIncoming: kpiIncoming,
        kpiInProgress: kpiInProgress,
        kpiOverdue: kpiOverdue,
      );
    case TicketsSubTab.scheduled:
      return TicketsListView(
        incomingNow: const [],
        inProgress: const [],
        completedToday: const [],
        scheduled: scheduled,
        kpiIncoming: kpiIncoming,
        kpiInProgress: kpiInProgress,
        kpiOverdue: kpiOverdue,
      );
    case TicketsSubTab.done:
      return TicketsListView(
        incomingNow: const [],
        inProgress: const [],
        completedToday: completedToday,
        scheduled: const [],
        kpiIncoming: kpiIncoming,
        kpiInProgress: kpiInProgress,
        kpiOverdue: kpiOverdue,
      );
  }
}
