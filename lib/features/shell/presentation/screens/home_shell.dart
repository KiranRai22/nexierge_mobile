import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/color_palette.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../tickets/presentation/providers/my_tickets_notifier.dart';
import '../../../tickets/presentation/providers/tickets_main_tab_provider.dart';
import '../../../tickets/presentation/screens/tickets_screen_new.dart';
import '../../../tickets/presentation/widgets/tickets_main_tabs.dart';
import '../widgets/app_bottom_nav.dart';
import 'create_router.dart';
import '../widgets/center_fab.dart';

/// Single host that owns the bottom-nav state.
///
/// Mirrors hotel-ops.lovable.app/dashboard: a flat 3-tab bar
/// (Dashboard · Tickets · Profile) with a separate floating action button
/// anchored at the bottom-right that opens the Create flow.
///
/// Tab switching uses an [IndexedStack] so each tab keeps its scroll
/// position and ephemeral state.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  ShellTab _current = ShellTab.dashboard;

  static const _stackTabs = [
    ShellTab.dashboard,
    ShellTab.tickets,
    ShellTab.profile,
  ];

  int get _stackIndex => _stackTabs.indexOf(_current);

  void _onSelect(ShellTab tab) {
    if (tab == _current) return;
    setState(() => _current = tab);

    // Track tickets tab active state for API fetching
    ref.read(ticketsTabActiveProvider.notifier).state = tab == ShellTab.tickets;
  }

  Future<void> _onFabPressed() async {
    final submitted = await CreateRouter.openCreate(context, ref);
    if (!mounted || !submitted) return;
    setState(() => _current = ShellTab.tickets);
    ref.read(ticketsTabActiveProvider.notifier).state = true;
    ref.read(ticketsMainTabProvider.notifier).state = TicketsMainTab.today;
    // Pull latest from server.
    ref.read(myTicketsNotifierProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.opsSurface,
      body: IndexedStack(
        index: _stackIndex,
        children: [
          DashboardScreen(onSwitchTab: _onSelect),
          TicketsScreenNew(onSwitchTab: _onSelect),
          const ProfileScreen(),
        ],
      ),
      floatingActionButton: _current == ShellTab.dashboard
          ? CenterFab(onPressed: _onFabPressed)
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: AppBottomNav(current: _current, onSelect: _onSelect),
    );
  }
}
