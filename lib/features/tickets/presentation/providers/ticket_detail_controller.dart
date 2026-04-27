import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/department.dart';
import '../../domain/models/ticket.dart';
import 'repository_providers.dart';

/// Live single-ticket stream keyed by id. Re-emits whenever the repository
/// mutates the underlying ticket (accept, mark done, add note, etc.).
final ticketByIdProvider =
    StreamProvider.autoDispose.family<Ticket?, String>((ref, id) {
  final repo = ref.watch(ticketsRepositoryProvider);
  return repo.watch(id);
});

/// Mutation actions exposed to the detail screen. Wraps the repository so
/// the screen never imports `mock_tickets_repository.dart` directly.
class TicketActions {
  TicketActions(this._ref);
  final Ref _ref;

  Future<void> accept(String id, Duration etaIn) =>
      _ref.read(ticketsRepositoryProvider).accept(id, etaIn: etaIn);

  Future<void> markDone(String id) =>
      _ref.read(ticketsRepositoryProvider).markDone(id);

  Future<void> cancel(String id) =>
      _ref.read(ticketsRepositoryProvider).cancel(id);

  Future<void> addNote(String id, String note) =>
      _ref.read(ticketsRepositoryProvider).addNote(id, note);

  Future<void> changeDepartment(String id, Department newDept) =>
      _ref.read(ticketsRepositoryProvider).changeDepartment(id, newDept);
}

final ticketActionsProvider = Provider<TicketActions>(TicketActions.new);
