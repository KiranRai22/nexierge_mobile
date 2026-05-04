import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/my_ticket.dart';
import '../../domain/models/department.dart';
import '../../domain/models/ticket.dart';
import 'my_tickets_notifier.dart';
import 'tickets_list_controller.dart';
import 'tickets_main_tab_provider.dart';

/// Simplified Ticket mapping from MyTicket for UI display.
/// This is a lightweight adapter - full Ticket model is kept for detail view.
Ticket _mapToTicket(MyTicket t) {
  return Ticket(
    id: t.id,
    code: t.roomDetails?.onbRoomNumber ?? 'N/A',
    title: t.issueSummary.isNotEmpty ? t.issueSummary : '${t.type} Request',
    status: _mapStatus(t.status),
    kind: _mapKind(t.type),
    department: Department.housekeeping,
    room: Room(
      id: t.room,
      number: t.roomDetails?.onbRoomNumber ?? 'N/A',
      floor: 1,
    ),
    guest: t.guestName.isNotEmpty
        ? Guest(id: t.room, displayName: t.guestName)
        : null,
    createdAt: DateTime.fromMillisecondsSinceEpoch(t.createdAt),
    eta: t.dueAt > 0 ? DateTime.fromMillisecondsSinceEpoch(t.dueAt) : null,
    items: [],
    assigneeName: t.assignedToUserId,
  );
}

TicketStatus _mapStatus(String status) {
  switch (status.toUpperCase()) {
    case 'NEW':
      return TicketStatus.incoming;
    case 'ACCEPTED':
      return TicketStatus.accepted;
    case 'IN_PROGRESS':
      return TicketStatus.inProgress;
    case 'DONE':
      return TicketStatus.done;
    case 'CANCELLED':
      return TicketStatus.cancelled;
    default:
      return TicketStatus.incoming;
  }
}

TicketKind _mapKind(String type) {
  switch (type.toUpperCase()) {
    case 'REQUEST':
      return TicketKind.universal;
    case 'CATALOG':
      return TicketKind.catalog;
    default:
      return TicketKind.manual;
  }
}

/// Extension to provide empty view
extension TicketsListViewEmpty on TicketsListView {
  static TicketsListView empty() => const TicketsListView(
    incomingNow: [],
    inProgress: [],
    completedToday: [],
    scheduled: [],
    kpiIncoming: 0,
    kpiInProgress: 0,
    kpiOverdue: 0,
  );
}

/// Transforms MyTicket realtime state into TicketsListView for UI compatibility.
///
/// Today-bucket fields (`inProgress`, `completedToday`) are scoped to
/// tickets whose status changed today — see `MyTicketsState.todayAccepted`
/// and friends. Tickets in those statuses but unchanged today fall out of
/// the Today view.
final myTicketsListProvider = Provider<TicketsListView?>((ref) {
  final asyncState = ref.watch(myTicketsNotifierProvider);

  return asyncState.when(
    data: (state) {
      if (state.all.isEmpty && state.isLoading) return null;

      final incomingNow = state.incoming;
      final todayInProgressBucket = [
        ...state.todayAccepted,
        ...state.todayInProgress,
      ];
      final completedToday = state.todayDone;
      final scheduled = state.all.where((t) {
        if (t.dueAt == 0) return false;
        final dueDate = DateTime.fromMillisecondsSinceEpoch(t.dueAt);
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        return dueDate.isAfter(tomorrow);
      }).toList();

      return TicketsListView(
        incomingNow: incomingNow.map(_mapToTicket).toList(),
        inProgress: todayInProgressBucket.map(_mapToTicket).toList(),
        completedToday: completedToday.map(_mapToTicket).toList(),
        scheduled: scheduled.map(_mapToTicket).toList(),
        kpiIncoming: state.incomingCount,
        kpiInProgress: state.acceptedCount + state.inProgressCount,
        kpiOverdue: state.overdueCount,
      );
    },
    loading: () => null,
    error: (_, __) => TicketsListViewEmpty.empty(),
  );
});

/// State-layer "Today" tab list. Reads the realtime ticket state plus the
/// active filter chip and returns the filtered today bucket. Widgets
/// don't switch on the filter key — they just render whatever the
/// provider gives them.
final todayTicketsProvider = Provider<List<Ticket>>((ref) {
  final asyncState = ref.watch(myTicketsNotifierProvider);
  final filter = ref.watch(ticketsFilterProvider);
  return asyncState.maybeWhen(
    data: (state) =>
        state.todayFiltered(filter).map(_mapToTicket).toList(),
    orElse: () => const [],
  );
});

/// State-layer "Incoming" tab list. Equivalent to `state.incoming` mapped
/// for the UI. Exposed as a dedicated provider so the screen never
/// re-derives it.
final incomingTicketsProvider = Provider<List<Ticket>>((ref) {
  final asyncState = ref.watch(myTicketsNotifierProvider);
  return asyncState.maybeWhen(
    data: (state) => state.incoming.map(_mapToTicket).toList(),
    orElse: () => const [],
  );
});
