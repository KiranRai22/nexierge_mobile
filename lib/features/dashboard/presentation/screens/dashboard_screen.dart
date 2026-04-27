import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_mode_controller.dart';
import '../../../notifications/presentation/providers/notification_inbox_controller.dart';
import '../../../notifications/presentation/widgets/notifications_sheet.dart';
import '../../../shell/presentation/widgets/app_bottom_nav.dart';
import '../../../tickets/domain/models/ticket.dart';
import '../../../tickets/presentation/providers/session_providers.dart';
import '../../../tickets/presentation/screens/ticket_detail_screen.dart';
import '../../../tickets/presentation/widgets/app_top_bar.dart';
import '../providers/dashboard_counts_controller.dart';
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

  void _openNotifications(BuildContext context) {
    NotificationsSheet.show(
      context,
      onOpenTicket: (ticketId) => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => TicketDetailScreen(ticketId: ticketId),
        ),
      ),
    );
  }

  Future<void> _refresh(WidgetRef ref) async {
    // Refresh both API counts and the local attention projection in parallel.
    await Future.wait<void>([
      ref.read(dashboardCountsControllerProvider.notifier).refresh(),
      Future<void>(() => ref.invalidate(dashboardViewProvider)),
    ]);
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
    final asyncCounts = ref.watch(dashboardCountsControllerProvider);
    final asyncView = ref.watch(dashboardViewProvider);
    final inboxUnread = ref.watch(
      notificationInboxControllerProvider.select((v) => v.unreadCount),
    );
    final themeMode = ref.watch(themeModeControllerProvider).valueOrNull;
    final isDark = _resolveDark(context, themeMode);
    final c = context.appColors;

    final initials = (() {
      final name = session.displayName.trim();
      if (name.isEmpty) return '?';
      final parts = name
          .split(RegExp(r'\s+'))
          .where((p) => p.isNotEmpty)
          .toList();
      if (parts.length == 1) return parts.first[0].toUpperCase();
      return (parts.first[0] + parts.last[0]).toUpperCase();
    })();
    final firstName = session.displayName.split(' ').first;

    return Container(
      color: c.bgSubtle,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Fixed top: app bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: AppTopBar(
                avatarInitials: initials,
                isDarkMode: isDark,
                hasUnreadNotifications:
                    inboxUnread > 0 ||
                    asyncCounts.maybeWhen(
                      data: (counts) => counts.hasUnread,
                      orElse: () => false,
                    ),
                onThemeToggle: () =>
                    ref.read(themeModeControllerProvider.notifier).toggle(),
                onNotifications: () => _openNotifications(context),
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
                        // KPI counts come from the real `dashboard/numbers`
                        // endpoint. Breakdown line stays driven by the local
                        // mock projection until the backend exposes it.
                        child: asyncCounts.when(
                          data: (counts) => DashboardStatsGrid(
                            incoming: counts.incomingCount,
                            accepted: counts.notStartedCount,
                            inProgress: counts.inProgressCount,
                            overdue: counts.overdueCount,
                            breakdown: asyncView.maybeWhen(
                              data: (v) => v.incomingBreakdown,
                              orElse: () => const IncomingBreakdown(
                                universal: 0,
                                catalog: 0,
                                manual: 0,
                              ),
                            ),
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
