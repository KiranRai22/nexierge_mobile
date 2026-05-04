import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/ticket_repository.dart';
import '../../domain/entities/ticket_detail.dart';

/// Async controller for ticket detail from API.
class TicketDetailApiController extends AsyncNotifier<TicketDetail> {
  late TicketRepository _repo;

  @override
  Future<TicketDetail> build() async {
    _repo = ref.read(ticketRepositoryProvider);
    final ticketId = ref.watch(ticketIdProvider);
    if (ticketId == null || ticketId.isEmpty) {
      throw Exception('Ticket ID is required');
    }
    return _repo.fetchTicketDetails(ticketId: ticketId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading<TicketDetail>().copyWithPrevious(state);
    state = await AsyncValue.guard(build);
  }

  /// Re-fetches the detail without flipping into a loading state. The
  /// activity-timeline tab listens for transition pushes from the backend
  /// and triggers this so the timeline updates without a spinner flash.
  Future<void> silentRefresh() async {
    final id = ref.read(ticketIdProvider);
    if (id == null || id.isEmpty) return;
    try {
      final fresh = await _repo.fetchTicketDetails(ticketId: id);
      state = AsyncData(fresh);
    } catch (_) {
      // Keep previous data; the next backend push will retry.
    }
  }
}

final ticketDetailApiControllerProvider =
    AsyncNotifierProvider<TicketDetailApiController, TicketDetail>(
      TicketDetailApiController.new,
    );

/// Provider for the ticket ID being viewed. Set by the detail screen.
final ticketIdProvider = StateProvider<String?>((ref) => null);
