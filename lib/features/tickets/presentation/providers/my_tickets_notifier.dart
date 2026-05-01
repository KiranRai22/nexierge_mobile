import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dashboard/presentation/providers/dashboard_bootstrap_controller.dart';
import '../../data/repositories/ticket_repository.dart';
import '../../domain/entities/my_ticket.dart';

/// Provider to track when tickets tab is active (for triggering fetches)
final ticketsTabActiveProvider = StateProvider<bool>((ref) => false);

/// AsyncNotifier for my tickets with counts and filtering.
/// AutoDispose so it re-fetches when user navigates to tickets tab.
class MyTicketsNotifier extends AutoDisposeAsyncNotifier<MyTicketsState> {
  late TicketRepository _repo;

  @override
  Future<MyTicketsState> build() async {
    _repo = ref.read(ticketRepositoryProvider);

    // Watch tickets tab active state - triggers fetch when user switches to tickets tab
    final isTabActive = ref.watch(ticketsTabActiveProvider);

    // Get hotelId from dashboard bootstrap (which calls me_user API)
    final bootstrap = ref
        .watch(dashboardBootstrapControllerProvider)
        .valueOrNull;
    final hotelId = bootstrap?.userProfile?.hotelDetails.hotel.id;

    debugPrint(
      '[MyTicketsNotifier] build() - isTabActive: $isTabActive, hotelId: $hotelId',
    );

    if (hotelId == null || hotelId.isEmpty) {
      // Bootstrap not ready yet; will re-run automatically when it resolves
      debugPrint(
        '[MyTicketsNotifier] No hotelId from bootstrap, returning empty state',
      );
      return const MyTicketsState();
    }

    // Always fetch when tab is active (user is viewing tickets)
    if (!isTabActive) {
      debugPrint('[MyTicketsNotifier] Tab not active, returning empty state');
      return const MyTicketsState();
    }

    debugPrint('[MyTicketsNotifier] Fetching tickets for hotel: $hotelId');
    return _fetchTickets(hotelId);
  }

  Future<MyTicketsState> _fetchTickets(String hotelId) async {
    try {
      debugPrint('[MyTicketsNotifier] Calling API for hotel: $hotelId');
      final tickets = await _repo.fetchMyTickets(hotelId: hotelId);
      debugPrint('[MyTicketsNotifier] API returned ${tickets.length} tickets');
      return MyTicketsState(all: tickets, isLoading: false);
    } catch (e, st) {
      debugPrint('[MyTicketsNotifier] Error fetching tickets: $e');
      debugPrint('[MyTicketsNotifier] Stack trace: $st');
      return MyTicketsState(error: e.toString());
    }
  }

  Future<MyTicketsState> _fetch() async {
    final bootstrap = ref
        .read(dashboardBootstrapControllerProvider)
        .valueOrNull;
    final hotelId = bootstrap?.userProfile?.hotelDetails.hotel.id;
    if (hotelId == null || hotelId.isEmpty) {
      return const MyTicketsState(error: 'No hotel selected');
    }
    return _fetchTickets(hotelId);
  }

  /// Refresh tickets from API.
  Future<void> refresh() async {
    state = const AsyncLoading<MyTicketsState>().copyWithPrevious(state);
    state = await AsyncValue.guard(_fetch);
  }
}

/// Provider for my tickets state.
/// AutoDispose so it re-fetches when user navigates back to tickets tab.
final myTicketsNotifierProvider =
    AsyncNotifierProvider.autoDispose<MyTicketsNotifier, MyTicketsState>(
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
