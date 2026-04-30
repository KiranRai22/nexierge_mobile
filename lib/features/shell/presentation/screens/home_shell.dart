import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/color_palette.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../tickets/presentation/screens/tickets_screen_new.dart';
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
  }

  Future<void> _onFabPressed() => CreateRouter.openCreate(context, ref);

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
