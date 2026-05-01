import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/my_ticket.dart';
import '../../domain/models/department.dart';
import '../../domain/models/ticket.dart';
import 'my_tickets_notifier.dart';
import 'tickets_list_controller.dart';

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

/// Transforms MyTicket API data to TicketsListView for UI compatibility.
/// This adapter allows the existing UI to work with the new API structure.
final myTicketsListProvider = Provider.autoDispose<TicketsListView?>((ref) {
  final asyncState = ref.watch(myTicketsNotifierProvider);

  return asyncState.when(
    data: (state) {
      if (state.all.isEmpty && state.isLoading) {
        return null; // Loading state
      }

      final tickets = state.all;

      // Map API status to UI categories
      final incomingNow = tickets.where((t) => t.isIncoming).toList();
      final inProgress = tickets
          .where((t) => t.isAccepted || t.isInProgress)
          .toList();
      final completedToday = tickets.where((t) => t.isDone).toList();
      final scheduled = tickets.where((t) {
        if (t.dueAt == 0) return false;
        final dueDate = DateTime.fromMillisecondsSinceEpoch(t.dueAt);
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        return dueDate.isAfter(tomorrow);
      }).toList();

      return TicketsListView(
        incomingNow: incomingNow.map(_mapToTicket).toList(),
        inProgress: inProgress.map(_mapToTicket).toList(),
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
