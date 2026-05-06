import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/tickets_main_tabs.dart';

/// Provider for the selected main tab (Incoming, Today, Scheduled, Done).
/// Default is Today — the operator's day-of view.
final ticketsMainTabProvider = StateProvider<TicketsMainTab>((ref) {
  return TicketsMainTab.today;
});

/// Provider for the selected filter within the current main tab
/// Default is 'all' so the All chip is selected initially on Today tab
final ticketsFilterProvider = StateProvider<String?>((ref) {
  return 'all';
});
