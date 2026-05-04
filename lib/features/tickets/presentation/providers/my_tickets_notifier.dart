import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dashboard/presentation/providers/dashboard_bootstrap_controller.dart';
import '../../data/repositories/ticket_repository.dart';
import '../../domain/entities/my_ticket.dart';

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
      debugPrint(
        '[MyTicketsNotifier] hotelId not ready — returning empty state',
      );
      return const MyTicketsState();
    }

    return _fetchTickets(hotelId);
  }

  Future<MyTicketsState> _fetchTickets(String hotelId) async {
    try {
      final tickets = await _repo.fetchMyTickets(hotelId: hotelId);
      debugPrint('[MyTicketsNotifier] fetched ${tickets.length} tickets');
      return MyTicketsState(all: tickets, isLoading: false);
    } catch (e, st) {
      debugPrint('[MyTicketsNotifier] fetch error: $e');
      debugPrint('$st');
      return MyTicketsState(error: e.toString());
    }
  }

  /// Refresh tickets from API. UI shows the previous data while loading.
  Future<void> refresh() async {
    final bootstrap = ref
        .read(dashboardBootstrapControllerProvider)
        .valueOrNull;
    final hotelId = bootstrap?.userProfile?.hotelDetails.hotel.id;
    if (hotelId == null || hotelId.isEmpty) return;
    state = const AsyncLoading<MyTicketsState>().copyWithPrevious(state);
    state = await AsyncValue.guard(() => _fetchTickets(hotelId));
  }

  /// Realtime upsert. Replaces an existing ticket by id, or prepends if
  /// new. Records the observation timestamp in `statusChangedAt` so the
  /// "Today" filter sees the latest transition immediately.
  void upsertFromRealtime(MyTicket ticket) {
    final current = state.valueOrNull;
    if (current == null) {
      // No baseline yet — store as the only ticket; initial fetch will
      // merge once it lands.
      final now = DateTime.now().millisecondsSinceEpoch;
      state = AsyncData(
        MyTicketsState(
          all: [ticket],
          statusChangedAt: {ticket.id: now},
        ),
      );
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

    // Only stamp `statusChangedAt` when the status actually transitioned
    // (or this is a brand new ticket). Avoids reshuffling the Today list
    // on no-op updates like room number tweaks.
    final stampedNow = existing == null || existing.status != ticket.status;
    final nextStatusChangedAt = stampedNow
        ? {
            ...current.statusChangedAt,
            ticket.id: DateTime.now().millisecondsSinceEpoch,
          }
        : current.statusChangedAt;

    state = AsyncData(
      current.copyWith(
        all: next,
        statusChangedAt: nextStatusChangedAt,
      ),
    );
  }

  /// Realtime delete. Drops the ticket if present and clears any
  /// per-ticket overrides.
  void removeById(String ticketId) {
    final current = state.valueOrNull;
    if (current == null) return;
    if (!current.all.any((t) => t.id == ticketId)) return;

    final nextOverrides = {...current.statusChangedAt}..remove(ticketId);

    state = AsyncData(
      current.copyWith(
        all: current.all.where((t) => t.id != ticketId).toList(),
        statusChangedAt: nextOverrides,
      ),
    );
  }
}

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
