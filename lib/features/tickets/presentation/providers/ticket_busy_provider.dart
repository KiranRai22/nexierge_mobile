import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks ticket IDs currently undergoing a status-change API call.
/// Card UI dims + AbsorbPointer while the ID is in the set, preventing
/// duplicate taps across list, detail, and any other view.
class TicketBusyNotifier extends StateNotifier<Set<String>> {
  TicketBusyNotifier() : super(const <String>{});

  void mark(String ticketId) {
    if (ticketId.isEmpty || state.contains(ticketId)) return;
    state = {...state, ticketId};
  }

  void clear(String ticketId) {
    if (!state.contains(ticketId)) return;
    final next = {...state}..remove(ticketId);
    state = next;
  }

  bool isBusy(String ticketId) => state.contains(ticketId);
}

final ticketBusyProvider =
    StateNotifierProvider<TicketBusyNotifier, Set<String>>(
  (ref) => TicketBusyNotifier(),
);

/// Fine-grained provider: rebuilds only when the given ticket's busy
/// state flips, avoiding wholesale list rebuilds.
final isTicketBusyProvider = Provider.family<bool, String>((ref, ticketId) {
  return ref.watch(ticketBusyProvider).contains(ticketId);
});
