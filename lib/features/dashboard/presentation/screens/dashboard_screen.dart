import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/i18n/language_picker_sheet.dart';
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

/// Operator dashboard: greeting, stats grid (Incoming Now / In Progress /
/// Overdue) and a *Needs attention* list of high-priority tickets.
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(operatorSessionProvider);
    final asyncView = ref.watch(dashboardViewProvider);

    final initials = session.displayName.isEmpty
        ? '?'
        : session.displayName.trim()[0].toUpperCase();
    final firstName = session.displayName.split(' ').first;

    return Container(
      color: ColorPalette.opsSurfaceSubtle,
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => _refresh(ref),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: AppTopBar(
                    avatarInitials: initials,
                    hasUnreadNotifications: asyncView.maybeWhen(
                      data: (v) => v.hasUnread,
                      orElse: () => false,
                    ),
                    onThemeToggle: () => ref
                        .read(themeModeControllerProvider.notifier)
                        .toggle(),
                    onLanguageTap: () =>
                        LanguagePickerSheet.show(context),
                    onNotifications: () => _showNotificationsHint(context),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                sliver: SliverToBoxAdapter(
                  child: DashboardGreeting(
                    firstName: firstName,
                    deptHint: session.homeDepartment,
                    now: DateTime.now(),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                sliver: SliverToBoxAdapter(
                  child: asyncView.when(
                    data: (v) => DashboardStatsGrid(
                      incoming: v.incomingCount,
                      inProgress: v.inProgressCount,
                      overdue: v.overdueCount,
                      breakdown: v.incomingBreakdown,
                      onTapAll: () => onSwitchTab(ShellTab.tickets),
                    ),
                    loading: () => const _StatsSkeleton(),
                    error: (_, __) => const _StatsSkeleton(),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                sliver: SliverToBoxAdapter(
                  child: asyncView.when(
                    data: (v) => NeedsAttentionList(
                      items: v.needsAttention,
                      deptHint: session.homeDepartment,
                      onItemTap: (item) =>
                          _openTicket(context, item.ticket),
                      onViewAll: () => onSwitchTab(ShellTab.tickets),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsSkeleton extends StatelessWidget {
  const _StatsSkeleton();

  @override
  Widget build(BuildContext context) {
    return const DashboardStatsGrid(
      incoming: 0,
      inProgress: 0,
      overdue: 0,
      breakdown: IncomingBreakdown(universal: 0, catalog: 0, manual: 0),
      onTapAll: _noop,
    );
  }

  static void _noop() {}
}
