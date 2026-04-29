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
}

final ticketDetailApiControllerProvider =
    AsyncNotifierProvider<TicketDetailApiController, TicketDetail>(
      TicketDetailApiController.new,
    );

/// Provider for the ticket ID being viewed. Set by the detail screen.
final ticketIdProvider = StateProvider<String?>((ref) => null);
