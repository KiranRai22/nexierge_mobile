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

  final kind = _mapKind(t.type, t.ticketType);
  final kindData = _buildKindData(t, kind);
  final title = _buildTitle(t, kind, kindData);

  return Ticket(
    id: t.id,
    code: t.roomDetails?.onbRoomNumber ?? 'N/A',
    title: title,
    status: _mapStatus(t.status),
    kind: kind,
    department: _mapDepartment(
      code: t.departmentCode,
      name: t.departmentName,
      fallback: t.departmentId,
    ),
    departmentName: t.departmentName,
    departmentEmoji: t.departmentMobileIcon,
    departmentIconUrl: t.departmentIconUrl,
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
    items: const [],
    assigneeName: t.assignedToUserId,
    isTransitioning: t.isTransitioning,
    kindData: kindData,
  );
}

TicketKindData? _buildKindData(MyTicket t, TicketKind kind) {
  switch (kind) {
    case TicketKind.universal:
      if (t.universalItems.isEmpty) return null;
      final first = t.universalItems.first;
      return UniversalKindData(
        displayName: first.item,
        thumbnailUrl: first.thumbnailUrl,
        emoji: first.emoji.isEmpty ? null : first.emoji,
        itemCount: t.universalItems.length,
        nameI18n: first.nameI18n,
      );
    case TicketKind.catalog:
      final c = t.catalogDetails;
      if (c == null) return null;
      return CatalogKindData(
        catalogName: c.catalogName,
        logoUrl: c.logoUrl,
        brandColorHex: c.brandColorHex,
        grandTotal: c.grandTotal,
        currency: c.currency,
        itemCount: c.items.length,
        itemThumbnails: [
          for (final i in c.items)
            if (i.imageUrl != null && i.imageUrl!.isNotEmpty) i.imageUrl!,
        ],
        itemNames: c.items.map((i) => i.itemName).toList(growable: false),
      );
    case TicketKind.manual:
      final m = t.manualDetails;
      return ManualKindData(
        summary: m?.summary ?? t.issueSummary,
        details: m?.details ?? t.issueDetails,
      );
  }
}

String _buildTitle(MyTicket t, TicketKind kind, TicketKindData? kindData) {
  switch (kind) {
    case TicketKind.universal:
      final u = kindData is UniversalKindData ? kindData : null;
      final base = u?.displayName.isNotEmpty == true
          ? u!.displayName
          : (t.issueSummary.isNotEmpty ? t.issueSummary : 'Universal request');
      return base;
    case TicketKind.catalog:
      final c = kindData is CatalogKindData ? kindData : null;
      return c?.catalogName.isNotEmpty == true
          ? c!.catalogName
          : (t.issueSummary.isNotEmpty ? t.issueSummary : 'Catalog order');
    case TicketKind.manual:
      final m = kindData is ManualKindData ? kindData : null;
      if (m != null && m.summary.isNotEmpty) return m.summary;
      if (t.issueSummary.isNotEmpty) return t.issueSummary;
      return t.departmentName ?? 'Manual ticket';
  }
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
      return TicketStatus.onHold;
    case 'DONE':
      return TicketStatus.done;
    case 'CANCELED':
    case 'CANCELLED':
      return TicketStatus.canceled;
    case 'EXPIRED':
      // EXPIRED is server-driven; no UI tab yet — render as canceled-like
      // terminal state until a dedicated badge is added.
      return TicketStatus.canceled;
    default:
      return TicketStatus.incoming;
  }
}

TicketKind _mapKind(String type, String? ticketType) {
  final effective = (ticketType?.isNotEmpty == true ? ticketType! : type)
      .toLowerCase();
  switch (effective) {
    case 'universal_request':
    case 'request':
      return TicketKind.universal;
    case 'service_catalog':
    case 'catalog':
      return TicketKind.catalog;
    case 'manual':
    case 'manual_ticket_request':
      return TicketKind.manual;
    default:
      return TicketKind.manual;
  }
}

Department _mapDepartment({
  String? code,
  String? name,
  required String fallback,
}) {
  // Prefer the stable backend `department.code` (e.g. `fnb`, `frontdesk`).
  final byCode = (code ?? '').toLowerCase();
  switch (byCode) {
    case 'fnb':
    case 'fb':
      return Department.fnb;
    case 'frontdesk':
    case 'front_desk':
    case 'front-desk':
      return Department.frontDesk;
    case 'housekeeping':
      return Department.housekeeping;
    case 'maintenance':
      return Department.maintenance;
    case 'concierge':
      return Department.concierge;
    case 'roomservice':
    case 'room_service':
      return Department.roomService;
  }
  // Fall back to fuzzy name match, then the legacy id-string heuristic.
  final hint = ((name ?? '').isNotEmpty ? name! : fallback).toLowerCase();
  if (hint.contains('housekeeping') || hint.contains('house')) {
    return Department.housekeeping;
  }
  if (hint.contains('maintenance') || hint.contains('maint')) {
    return Department.maintenance;
  }
  if (hint.contains('room service') || hint.contains('roomservice')) {
    return Department.roomService;
  }
  if (hint.contains('front') || hint.contains('desk') ||
      hint.contains('reservation')) {
    return Department.frontDesk;
  }
  if (hint.contains('concierge')) {
    return Department.concierge;
  }
  if (hint.contains('f&b') ||
      hint.contains('food') ||
      hint.contains('beverage')) {
    return Department.fnb;
  }
  return Department.housekeeping;
}

/// Extension to provide empty view
extension TicketsListViewEmpty on TicketsListView {
  static TicketsListView empty() => const TicketsListView(
    incomingNow: [],
    inProgress: [],
    completedToday: [],
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

      Ticket mapWithWork(MyTicket t) =>
          _mapToTicket(t, workStartedEpoch: state.statusChangedAt[t.id]);

      return TicketsListView(
        incomingNow: incomingNow.map(mapWithWork).toList(),
        inProgress: todayInProgressBucket.map(mapWithWork).toList(),
        completedToday: completedToday.map(mapWithWork).toList(),
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
