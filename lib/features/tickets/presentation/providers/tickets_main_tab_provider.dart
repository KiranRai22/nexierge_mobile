import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/tickets_main_tabs.dart';

/// Provider for the selected main tab (Incoming, Today, Scheduled, Done)
final ticketsMainTabProvider = StateProvider<TicketsMainTab>((ref) {
  return TicketsMainTab.incoming;
});

/// Provider for the selected filter within the current main tab
final ticketsFilterProvider = StateProvider<String?>((ref) {
  return null;
});
