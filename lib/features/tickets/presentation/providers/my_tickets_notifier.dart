import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dashboard/presentation/providers/dashboard_bootstrap_controller.dart';
import '../../data/repositories/ticket_repository.dart';
import '../../domain/entities/my_ticket.dart';
import '../../domain/models/ticket_change_event.dart';
import 'ticket_detail_api_controller.dart';
import 'ticket_event_bus.dart';
import 'tickets_paged_notifier.dart';

/// How long a ticket stays "highlighted" after a realtime create or status
/// change. Drives the green-border emphasis on the card.
const Duration kRecentChangeHighlightWindow = Duration(seconds: 5);

/// Legacy state-tracking provider used by the shell to know whether the
/// user is on the Tickets tab. The notifier no longer reads this — the
/// realtime ticket list is persistent across tab navigation. Kept so the
/// existing call sites compile without churn.
final ticketsTabActiveProvider = StateProvider<bool>((ref) => false);

/// Persistent realtime ticket list.
///
/// - Initial fetch fires once the dashboard bootstrap supplies a hotelId.
/// - Realtime upserts and deletes apply incrementally (no full refetch).
/// - State survives tab navigation; it is bound to the auth session and
///   is invalidated when the user logs out via the lifecycle wiring.
class MyTicketsNotifier extends AsyncNotifier<MyTicketsState> {
  late TicketRepository _repo;

  @override
  Future<MyTicketsState> build() async {
    _repo = ref.read(ticketRepositoryProvider);

    final bootstrap = ref
        .watch(dashboardBootstrapControllerProvider)
        .valueOrNull;
    final hotelId = bootstrap?.userProfile?.hotelDetails.hotel.id;

    if (hotelId == null || hotelId.isEmpty) {
      //debugPrint(
      //   '[MyTicketsNotifier] hotelId not ready — returning empty state',
      // );
      return const MyTicketsState();
    }

    return _fetchTickets(hotelId);
  }

  Future<MyTicketsState> _fetchTickets(String hotelId) async {
    try {
      final tickets = await _repo.fetchMyTickets(hotelId: hotelId);
      //debugPrint('[MyTicketsNotifier] fetched ${tickets.length} tickets');
      return MyTicketsState(all: tickets, isLoading: false);
    } catch (e) {
      //debugPrint('[MyTicketsNotifier] fetch error: $e');
      //debugPrint('$st');
      return MyTicketsState(error: e.toString());
    }
  }

  /// Refresh tickets from API. UI shows the previous data while loading.
  ///
  /// Also refreshes all four paged tab providers so callers that fire
  /// `notifier.refresh()` after a mutation (action bar, manual create,
  /// home shell bootstrap) bring every tab back in sync with the server.
  Future<void> refresh() async {
    final bootstrap = ref
        .read(dashboardBootstrapControllerProvider)
        .valueOrNull;
    final hotelId = bootstrap?.userProfile?.hotelDetails.hotel.id;
    if (hotelId == null || hotelId.isEmpty) return;
    state = const AsyncLoading<MyTicketsState>().copyWithPrevious(state);
    final legacy = AsyncValue.guard(() => _fetchTickets(hotelId));
    final paged = Future.wait<void>([
      for (final tab in kAllTicketsTabs)
        ref.read(ticketsPagedProvider(specForTab(tab)).notifier).refresh(),
    ]);
    state = await legacy;
    await paged;
  }

  /// Realtime upsert. Replaces an existing ticket by id, or prepends if
  /// new. Records the observation timestamp in `statusChangedAt` so the
  /// "Today" filter sees the latest transition immediately.
  ///
  /// On every create or status transition, also:
  ///   - stamps `recentChangeAt[id]` to drive the green-border highlight,
  ///   - emits a [TicketChangeEvent] onto [TicketEventBus] for the toast +
  ///     sound dispatcher to consume.
  /// No-op field updates (e.g. assignee tweak) skip both — only meaningful
  /// transitions cause UI noise.
  void upsertFromRealtime(MyTicket ticket) {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final current = state.valueOrNull;
    if (kDebugMode) {
      //debugPrint(
      //   '[MyTicketsNotifier] upsertFromRealtime id=${ticket.id} '
      //   'status=${ticket.status} hasState=${current != null}',
      // );
    }
    if (current == null) {
      state = AsyncData(
        MyTicketsState(
          all: [ticket],
          statusChangedAt: {ticket.id: nowMs},
          freshlyArrivedIds: {ticket.id},
          recentChangeAt: {ticket.id: nowMs},
        ),
      );
      _scheduleFreshClear(ticket.id);
      _scheduleRecentChangeClear(ticket.id);
      if (ref.read(ticketIdProvider) != ticket.id) {
        _emitEvent(
          kind: TicketChangeKind.created,
          ticket: ticket,
          oldStatus: null,
        );
      }
      return;
    }

    final existingIndex = current.all.indexWhere((t) => t.id == ticket.id);
    final existing = existingIndex >= 0 ? current.all[existingIndex] : null;
    final next = [...current.all];
    if (existingIndex >= 0) {
      next[existingIndex] = ticket;
    } else {
      next.insert(0, ticket);
    }

    final isBrandNew = existing == null;
    final isStatusChange = !isBrandNew && existing.status != ticket.status;
    final isMeaningful = isBrandNew || isStatusChange;

    final nextStatusChangedAt = isMeaningful
        ? {...current.statusChangedAt, ticket.id: nowMs}
        : current.statusChangedAt;

    // Only mark as freshly arrived on a brand new id; status transitions on
    // existing tickets shouldn't re-trigger the slide-in animation.
    final nextFresh = isBrandNew
        ? {...current.freshlyArrivedIds, ticket.id}
        : current.freshlyArrivedIds;

    final nextRecentChange = isMeaningful
        ? {...current.recentChangeAt, ticket.id: nowMs}
        : current.recentChangeAt;

    if (kDebugMode) {
      //debugPrint(
      //   '[MyTicketsNotifier] upsert resolved: '
      //   'isBrandNew=$isBrandNew isStatusChange=$isStatusChange '
      //   'oldStatus=${existing?.status} newStatus=${ticket.status} '
      //   'todayBefore=${current.todayAllCount} '
      //   'incomingBefore=${current.incomingCount}',
      // );
    }

    state = AsyncData(
      current.copyWith(
        all: next,
        statusChangedAt: nextStatusChangedAt,
        freshlyArrivedIds: nextFresh,
        recentChangeAt: nextRecentChange,
      ),
    );

    // Debug-only state snapshot block removed; the debugPrint it served was
    // long-commented out. Re-add via `final s = state.valueOrNull!;` if you
    // need to inspect counts after an upsert.

    if (isBrandNew) _scheduleFreshClear(ticket.id);
    if (isMeaningful) {
      _scheduleRecentChangeClear(ticket.id);
      // Don't toast if the user opened this ticket directly from a notification.
      final isBeingViewed = isBrandNew && ref.read(ticketIdProvider) == ticket.id;
      if (!isBeingViewed) {
        _emitEvent(
          kind: isBrandNew
              ? TicketChangeKind.created
              : TicketChangeKind.statusChanged,
          ticket: ticket,
          oldStatus: existing?.status,
        );
      }
    }
  }

  void _emitEvent({
    required TicketChangeKind kind,
    required MyTicket ticket,
    required String? oldStatus,
  }) {
    TicketEventBus.instance.emit(
      TicketChangeEvent(
        ticketId: ticket.id,
        kind: kind,
        at: DateTime.now(),
        label: _labelFor(ticket),
        oldStatus: oldStatus,
        newStatus: ticket.status,
        ticketKind: ticket.type,
        dueAt: ticket.dueAt,
      ),
    );
  }

  String _labelFor(MyTicket t) {
    final title = t.issueSummary.trim();
    if (title.isNotEmpty) return title;
    final room = t.roomDetails?.onbRoomNumber ?? '';
    if (room.isNotEmpty) return 'Room $room';
    return '';
  }

  /// Drops [ticketId] from `recentChangeAt` after the highlight window. The
  /// UI also defends against this via wall-clock comparison, but pruning
  /// keeps the map from growing unbounded over a long session.
  void _scheduleRecentChangeClear(String ticketId) {
    Timer(kRecentChangeHighlightWindow, () {
      try {
        final s = state.valueOrNull;
        if (s == null) return;
        if (!s.recentChangeAt.containsKey(ticketId)) return;
        // Only drop the entry if it hasn't been re-stamped by a newer event
        // (re-highlight on subsequent transitions).
        final stamp = s.recentChangeAt[ticketId]!;
        final age = DateTime.now().millisecondsSinceEpoch - stamp;
        if (age < kRecentChangeHighlightWindow.inMilliseconds) return;
        final next = {...s.recentChangeAt}..remove(ticketId);
        state = AsyncData(s.copyWith(recentChangeAt: next));
      } catch (_) {
        // Notifier disposed — drop silently.
      }
    });
  }

  /// Removes [ticketId] from `freshlyArrivedIds` after 3 seconds. Safe if
  /// the notifier is disposed before the timer fires.
  void _scheduleFreshClear(String ticketId) {
    Timer(const Duration(seconds: 3), () {
      try {
        final s = state.valueOrNull;
        if (s == null || !s.freshlyArrivedIds.contains(ticketId)) return;
        final next = {...s.freshlyArrivedIds}..remove(ticketId);
        state = AsyncData(s.copyWith(freshlyArrivedIds: next));
      } catch (_) {
        // Notifier disposed — drop silently.
      }
    });
  }

  /// Captures the current state for optimistic rollback. Returns null if
  /// the notifier hasn't loaded yet.
  MyTicketsState? snapshot() => state.valueOrNull;

  /// Restores a previously captured snapshot. Used after an optimistic
  /// patch fails on the server so the local list matches reality again.
  void restore(MyTicketsState previous) {
    state = AsyncData(previous);
  }

  /// Realtime delete. Drops the ticket if present and clears any
  /// per-ticket overrides.
  void removeById(String ticketId) {
    final current = state.valueOrNull;
    if (current == null) return;
    if (!current.all.any((t) => t.id == ticketId)) return;

    final nextOverrides = {...current.statusChangedAt}..remove(ticketId);
    final nextFresh = current.freshlyArrivedIds.contains(ticketId)
        ? ({...current.freshlyArrivedIds}..remove(ticketId))
        : current.freshlyArrivedIds;

    state = AsyncData(
      current.copyWith(
        all: current.all.where((t) => t.id != ticketId).toList(),
        statusChangedAt: nextOverrides,
        freshlyArrivedIds: nextFresh,
      ),
    );
  }
}

/// Whether [ticketId] arrived via realtime within the last 3 seconds.
/// Drives the slide-in + background flash animation in [TicketCardNew].
final isFreshlyArrivedProvider = Provider.family<bool, String>((ref, ticketId) {
  final state = ref.watch(myTicketsNotifierProvider).valueOrNull;
  return state?.freshlyArrivedIds.contains(ticketId) ?? false;
});

/// Whether [ticketId] had a realtime create or status change within the
/// last [kRecentChangeHighlightWindow]. Drives the green-border emphasis
/// on [TicketCardNew]. Wall-clock guarded so a stale entry between the
/// notifier-side prune timer and the next rebuild does not over-highlight.
final isRecentlyChangedProvider = Provider.family<bool, String>((
  ref,
  ticketId,
) {
  final state = ref.watch(myTicketsNotifierProvider).valueOrNull;
  final stamp = state?.recentChangeAt[ticketId];
  if (stamp == null) return false;
  final age = DateTime.now().millisecondsSinceEpoch - stamp;
  return age < kRecentChangeHighlightWindow.inMilliseconds;
});

/// Persistent realtime-aware ticket list. Survives tab switches.
final myTicketsNotifierProvider =
    AsyncNotifierProvider<MyTicketsNotifier, MyTicketsState>(
      MyTicketsNotifier.new,
    );

/// Provider for just the counts (optimized for dashboard).
final myTicketsCountsProvider = Provider((ref) {
  final asyncState = ref.watch(myTicketsNotifierProvider);
  return asyncState.when(
    data: (state) => (
      incoming: state.incomingCount,
      accepted: state.acceptedCount,
      inProgress: state.inProgressCount,
      done: state.doneCount,
      overdue: state.overdueCount,
    ),
    loading: () =>
        (incoming: 0, accepted: 0, inProgress: 0, done: 0, overdue: 0),
    error: (_, __) =>
        (incoming: 0, accepted: 0, inProgress: 0, done: 0, overdue: 0),
  );
});
