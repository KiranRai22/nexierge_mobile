import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/my_ticket.dart';
import '../../domain/models/department.dart';
import '../../domain/models/ticket.dart';
import 'my_tickets_notifier.dart';
import 'tickets_list_controller.dart';
import 'tickets_main_tab_provider.dart';

/// Simplified Ticket mapping from MyTicket for UI display.
/// This is a lightweight adapter - full Ticket model is kept for detail view.
/// [workStartedEpoch] is the statusChangedAt override for IN_PROGRESS tickets.
Ticket mapMyTicketToTicket(MyTicket t, {int? workStartedEpoch}) =>
    _mapToTicket(t, workStartedEpoch: workStartedEpoch);

Ticket _mapToTicket(MyTicket t, {int? workStartedEpoch}) {
  DateTime? workStartedAt;
  if (t.isInProgress) {
    if (workStartedEpoch != null) {
      workStartedAt = DateTime.fromMillisecondsSinceEpoch(workStartedEpoch);
    } else if (t.acknowledgedAt > 0) {
      workStartedAt = DateTime.fromMillisecondsSinceEpoch(t.acknowledgedAt);
    }
  }

  // Fix title: avoid "Request Request" duplication
  final String title;
  if (t.issueSummary.isNotEmpty) {
    title = t.issueSummary;
  } else {
    final typeLower = t.type.toLowerCase();
    // If type already contains "request", don't append it again
    if (typeLower.contains('request')) {
      title = t.type;
    } else {
      title = '${t.type} Request';
    }
  }

  return Ticket(
    id: t.id,
    code: t.roomDetails?.onbRoomNumber ?? 'N/A',
    title: title,
    status: _mapStatus(t.status),
    kind: _mapKind(t.type),
    department: _mapDepartment(t.departmentId),
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
    workStartedAt: workStartedAt,
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
    case 'ON_HOLD':
      // ON_HOLD tickets surface in the Scheduled tab and render a
      // "Scheduled" chip on their cards.
      return TicketStatus.scheduled;
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

Department _mapDepartment(String departmentId) {
  final id = departmentId.toLowerCase();
  if (id.contains('housekeeping') || id.contains('house')) {
    return Department.housekeeping;
  }
  if (id.contains('maintenance') || id.contains('maint')) {
    return Department.maintenance;
  }
  if (id.contains('room') || id.contains('service')) {
    return Department.roomService;
  }
  if (id.contains('front') || id.contains('desk')) {
    return Department.frontDesk;
  }
  if (id.contains('concierge')) {
    return Department.concierge;
  }
  if (id.contains('f&b') || id.contains('fn') || id.contains('food')) {
    return Department.fnb;
  }
  // Default fallback
  return Department.housekeeping;
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

      final now = DateTime.now();
      final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final incomingNow = state.incoming;
      final todayInProgressBucket = [
        ...state.todayAccepted,
        ...state.todayInProgress,
      ];
      final completedToday = state.todayDone;

      // Schedule: accepted/in-progress tickets with dueAt beyond today.
      final scheduled = state.all.where((t) {
        if (!t.isAccepted && !t.isInProgress) return false;
        if (t.dueAt == 0) return false;
        final dueDate = DateTime.fromMillisecondsSinceEpoch(t.dueAt);
        return dueDate.isAfter(endOfToday);
      }).toList();

      Ticket mapWithWork(MyTicket t) =>
          _mapToTicket(t, workStartedEpoch: state.statusChangedAt[t.id]);

      return TicketsListView(
        incomingNow: incomingNow.map(mapWithWork).toList(),
        inProgress: todayInProgressBucket.map(mapWithWork).toList(),
        completedToday: completedToday.map(mapWithWork).toList(),
        scheduled: scheduled.map(mapWithWork).toList(),
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
    data: (state) => state
        .todayFiltered(filter)
        .map(
          (t) => _mapToTicket(t, workStartedEpoch: state.statusChangedAt[t.id]),
        )
        .toList(),
    orElse: () => const [],
  );
});

/// State-layer "Incoming" tab list. Equivalent to `state.incoming` mapped
/// for the UI. Exposed as a dedicated provider so the screen never
/// re-derives it.
final incomingTicketsProvider = Provider<List<Ticket>>((ref) {
  final asyncState = ref.watch(myTicketsNotifierProvider);
  return asyncState.maybeWhen(
    data: (state) => state.incoming
        .map(
          (t) => _mapToTicket(t, workStartedEpoch: state.statusChangedAt[t.id]),
        )
        .toList(),
    orElse: () => const [],
  );
});
