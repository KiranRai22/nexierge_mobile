import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/tickets_main_tabs.dart';

/// Provider for the selected main tab (Incoming, In Progress, Backlog, Done).
/// Default is In Progress — the operator's primary working view.
final ticketsMainTabProvider = StateProvider<TicketsMainTab>((ref) {
  return TicketsMainTab.inProgress;
});

/// Provider for the selected filter within the current main tab.
/// Default is 'newest' for newest-first sort on all tabs.
final ticketsFilterProvider = StateProvider<String?>((ref) {
  return 'newest';
});
