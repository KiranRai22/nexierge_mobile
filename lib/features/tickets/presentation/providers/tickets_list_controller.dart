// ─── V2 TICKETS LIST CONTROLLER (2026-05-14) ───────────────────
// Derives KPI counts from v2 paged providers for incoming, today
// (inProgress), and overdue. Replaces legacy dashboard derivations.
// ─────────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/time/server_clock.dart';
import '../../domain/entities/ticket_form_options.dart';
import '../../domain/models/department.dart';
import '../../domain/models/ticket.dart';
import 'session_providers.dart';
import 'tickets_paged_notifier.dart';

/// Sub-tab on the dashboard.
enum TicketsSubTab { incoming, today, done }

/// Computed view-model the dashboard renders.
class TicketsListView {
  final List<Ticket> incomingNow;
  final List<Ticket> inProgress;
  final List<Ticket> completedToday;
  final int kpiIncoming;
  final int kpiInProgress;
  final int kpiOverdue;

  const TicketsListView({
    required this.incomingNow,
    required this.inProgress,
    required this.completedToday,
    required this.kpiIncoming,
    required this.kpiInProgress,
    required this.kpiOverdue,
  });

  bool get isEmpty =>
      incomingNow.isEmpty && inProgress.isEmpty && completedToday.isEmpty;

  /// Returns a filtered view for the given sub-tab.
  TicketsListView forSubTab(TicketsSubTab tab) {
    switch (tab) {
      case TicketsSubTab.incoming:
        return TicketsListView(
          incomingNow: incomingNow,
          inProgress: const [],
          completedToday: const [],
          kpiIncoming: kpiIncoming,
          kpiInProgress: kpiInProgress,
          kpiOverdue: kpiOverdue,
        );
      case TicketsSubTab.today:
        return TicketsListView(
          incomingNow: const [],
          inProgress: inProgress,
          completedToday: const [],
          kpiIncoming: kpiIncoming,
          kpiInProgress: kpiInProgress,
          kpiOverdue: kpiOverdue,
        );
      case TicketsSubTab.done:
        return TicketsListView(
          incomingNow: const [],
          inProgress: const [],
          completedToday: completedToday,
          kpiIncoming: kpiIncoming,
          kpiInProgress: kpiInProgress,
          kpiOverdue: kpiOverdue,
        );
    }
  }
}

/// Sub-tab is local to the dashboard.
final ticketsSubTabProvider = StateProvider.autoDispose<TicketsSubTab>(
  (ref) => TicketsSubTab.today,
);

/// Search query — local to the dashboard.
final ticketsSearchQueryProvider = StateProvider.autoDispose<String>(
  (ref) => '',
);

/// Reactive view model from v2 paged providers. Derives KPI counts
/// from the v2 tabs and computes overdue tickets locally.
/// Status-based model: incoming, inProgress, backlog, done.
final ticketsListProvider = Provider.autoDispose<TicketsListView>((ref) {
  final incomingState = ref.watch(
    ticketsPagedProvider(specForTab(TicketsTab.incoming)),
  );
  final inProgressState = ref.watch(
    ticketsPagedProvider(specForTab(TicketsTab.inProgress)),
  );
  // Note: todayDoneState removed in status-based model.
  // Use doneState for completed tickets (history).

  final incomingItems =
      incomingState.valueOrNull?.items.cast<Ticket>() ?? const [];
  final inProgressItems =
      inProgressState.valueOrNull?.items.cast<Ticket>() ?? const [];
  // completedTodayItems removed - status-based model doesn't track
  // today's done separately. Done tab has All/Today filters instead.
  final completedTodayItems = <Ticket>[];

  final kpiIncoming = incomingState.valueOrNull?.itemsTotal ?? 0;
  final kpiInProgress = inProgressState.valueOrNull?.itemsTotal ?? 0;
  final kpiOverdue = inProgressItems.where((t) => t.isOverdue).length;

  return TicketsListView(
    incomingNow: incomingItems,
    inProgress: inProgressItems,
    completedToday: completedTodayItems,
    kpiIncoming: kpiIncoming,
    kpiInProgress: kpiInProgress,
    kpiOverdue: kpiOverdue,
  );
});

// ─── LEGACY-V1 (2026-05-14) ──────────────────────────────────────
// Dashboard-era _applyScope/_applySearch/_project. Kept for reference.
// ─────────────────────────────────────────────────────────────────
// ignore: unused_element
List<Ticket> _applyScope(
  List<Ticket> all,
  TicketScope scope,
  Department home,
  Set<HotelDepartment> filter,
) {
  Iterable<Ticket> out = all;
  if (scope == TicketScope.myDept) {
    out = out.where((t) => t.department == home);
  }
  if (filter.isNotEmpty) {
    // Mock-backed Tickets carry the legacy [Department] enum, so we match
    // via the picked HotelDepartment's `known` mapping. When real
    // API-backed tickets land we'll switch this to `t.departmentId == hd.id`.
    final knownEnums = filter
        .map((d) => d.known)
        .whereType<Department>()
        .toSet();
    out = out.where((t) => knownEnums.contains(t.department));
  }
  return out.toList(growable: false);
}

// ignore: unused_element
List<Ticket> _applySearch(List<Ticket> tickets, String query) {
  if (query.isEmpty) return tickets;
  return tickets
      .where((t) {
        return t.title.toLowerCase().contains(query) ||
            t.room.number.toLowerCase().contains(query) ||
            (t.guest?.displayName.toLowerCase().contains(query) ?? false) ||
            t.code.toLowerCase().contains(query);
      })
      .toList(growable: false);
}

// ignore: unused_element
TicketsListView _project(List<Ticket> tickets, TicketsSubTab subTab) {
  // ─── LEGACY-V1 (2026-05-14) ──────────────────────────────────────
  // Dashboard projection logic. Replaced by v2 paged providers with
  // separate incoming/inProgress/doneHistory tabs. Not called by v2.
  // ─────────────────────────────────────────────────────────────────
  final now = ServerClock.now();
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(const Duration(days: 1));

  final incomingNow = tickets
      .where((t) => t.status == TicketStatus.incoming)
      .toList(growable: false);
  final inProgress = tickets
      .where(
        (t) =>
            t.status == TicketStatus.inProgress ||
            t.status == TicketStatus.accepted,
      )
      .toList(growable: false);
  final completedToday = tickets
      .where((t) {
        if (t.status != TicketStatus.done || t.doneAt == null) return false;
        return t.doneAt!.isAfter(today) && t.doneAt!.isBefore(tomorrow);
      })
      .toList(growable: false);

  final kpiIncoming = incomingNow.length;
  final kpiInProgress = inProgress.length;
  final kpiOverdue = tickets.where((t) => t.isOverdue).length;

  switch (subTab) {
    case TicketsSubTab.incoming:
      return TicketsListView(
        incomingNow: incomingNow,
        inProgress: const [],
        completedToday: const [],
        kpiIncoming: kpiIncoming,
        kpiInProgress: kpiInProgress,
        kpiOverdue: kpiOverdue,
      );
    case TicketsSubTab.today:
      return TicketsListView(
        incomingNow: incomingNow,
        inProgress: inProgress,
        completedToday: completedToday,
        kpiIncoming: kpiIncoming,
        kpiInProgress: kpiInProgress,
        kpiOverdue: kpiOverdue,
      );
    case TicketsSubTab.done:
      return TicketsListView(
        incomingNow: const [],
        inProgress: const [],
        completedToday: completedToday,
        kpiIncoming: kpiIncoming,
        kpiInProgress: kpiInProgress,
        kpiOverdue: kpiOverdue,
      );
  }
}
