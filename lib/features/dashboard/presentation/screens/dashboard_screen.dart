import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/theme/theme_mode_controller.dart';
import '../../../shell/presentation/widgets/app_bottom_nav.dart';
import '../../../tickets/domain/models/ticket.dart';
import '../../../tickets/presentation/providers/session_providers.dart';
import '../../../tickets/presentation/screens/ticket_detail_screen.dart';
import '../../../tickets/presentation/widgets/app_top_bar.dart';
import '../providers/dashboard_view.dart';
import '../widgets/dashboard_greeting.dart';
import '../widgets/dashboard_stats_grid.dart';
import '../widgets/needs_attention_list.dart';

/// Operator dashboard. Mirrors `docs/ai_prompts/Dashboard.tsx`:
/// header (avatar + theme + bell) → greeting → 2×2 stats grid (Needs
/// acknowledgment / In progress / Overdue / Not started) → Needs attention
/// list → empty state.
class DashboardScreen extends ConsumerWidget {
  /// Switch the host shell to the Tickets tab. Wired by [HomeShell] via
  /// the bottom-nav controller it owns.
  final ValueChanged<ShellTab> onSwitchTab;

  const DashboardScreen({super.key, required this.onSwitchTab});

  void _showNotificationsHint(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.comingSoonNotifications)),
    );
  }

  Future<void> _refresh(WidgetRef ref) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    ref.invalidate(dashboardViewProvider);
  }

  void _openTicket(BuildContext context, Ticket ticket) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TicketDetailScreen(ticketId: ticket.id),
      ),
    );
  }

  bool _resolveDark(BuildContext context, ThemeMode? mode) {
    switch (mode) {
      case ThemeMode.dark:
        return true;
      case ThemeMode.light:
        return false;
      case ThemeMode.system:
      case null:
        return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(operatorSessionProvider);
    final asyncView = ref.watch(dashboardViewProvider);
    final themeMode = ref.watch(themeModeControllerProvider).valueOrNull;
    final isDark = _resolveDark(context, themeMode);

    final initials = session.displayName.isEmpty
        ? '?'
        : session.displayName.trim()[0].toUpperCase();
    final firstName = session.displayName.split(' ').first;

    return Container(
      color: ColorPalette.opsSurfaceSubtle,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Fixed top: app bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: AppTopBar(
                avatarInitials: initials,
                isDarkMode: isDark,
                hasUnreadNotifications: asyncView.maybeWhen(
                  data: (v) => v.hasUnread,
                  orElse: () => false,
                ),
                onThemeToggle: () =>
                    ref.read(themeModeControllerProvider.notifier).toggle(),
                onNotifications: () => _showNotificationsHint(context),
              ),
            ),

            // Fixed greeting under the app bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: DashboardGreeting(
                firstName: firstName,
                deptHint: session.homeDepartment,
                now: DateTime.now(),
              ),
            ),

            // Scrollable content below
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _refresh(ref),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      sliver: SliverToBoxAdapter(
                        child: asyncView.when(
                          data: (v) => DashboardStatsGrid(
                            incoming: v.incomingCount,
                            accepted: v.acceptedCount,
                            inProgress: v.inProgressCount,
                            overdue: v.overdueCount,
                            breakdown: v.incomingBreakdown,
                            onTapIncoming: () => onSwitchTab(ShellTab.tickets),
                            onTapInProgress: () =>
                                onSwitchTab(ShellTab.tickets),
                            onTapOverdue: () => onSwitchTab(ShellTab.tickets),
                            onTapAccepted: () => onSwitchTab(ShellTab.tickets),
                          ),
                          loading: () => const _StatsSkeleton(),
                          error: (_, _) => const _StatsSkeleton(),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                      sliver: SliverToBoxAdapter(
                        child: asyncView.when(
                          data: (v) => NeedsAttentionList(
                            items: v.needsAttention,
                            onItemTap: (item) =>
                                _openTicket(context, item.ticket),
                            onViewAll: () => onSwitchTab(ShellTab.tickets),
                          ),
                          loading: () => const SizedBox.shrink(),
                          error: (_, _) => const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsSkeleton extends StatelessWidget {
  const _StatsSkeleton();

  @override
  Widget build(BuildContext context) {
    return DashboardStatsGrid(
      incoming: 0,
      accepted: 0,
      inProgress: 0,
      overdue: 0,
      breakdown: const IncomingBreakdown(universal: 0, catalog: 0, manual: 0),
      onTapIncoming: _noop,
      onTapInProgress: _noop,
      onTapOverdue: _noop,
      onTapAccepted: _noop,
    );
  }

  static void _noop() {}
}
