import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/unified_theme_manager.dart';
import '../../../../core/theme/theme_mode_controller.dart';
import '../../../../core/theme/typography_manager.dart';
import '../../../notifications/presentation/providers/notification_inbox_controller.dart';
import '../../../notifications/presentation/widgets/notifications_sheet.dart';
import '../../../shell/presentation/widgets/app_bottom_nav.dart';
import '../../../tickets/domain/models/department.dart';
import '../../../tickets/presentation/providers/session_providers.dart';
import '../../../tickets/presentation/screens/ticket_detail_screen.dart';
import '../../../tickets/presentation/widgets/app_top_bar.dart';
import '../providers/dashboard_bootstrap_controller.dart';
import '../providers/dashboard_counts_controller.dart';
import '../providers/dashboard_view.dart';
import '../providers/needs_attention_controller.dart';
import '../widgets/dashboard_greeting.dart';
import '../widgets/dashboard_stats_compact.dart';
import '../widgets/dashboard_stats_grid.dart';
import '../widgets/needs_attention_api_list.dart';

/// Operator dashboard. Mirrors `docs/ai_prompts/Dashboard.tsx`:
/// header (avatar + theme + bell) → greeting → 2×2 stats grid (Needs
/// acknowledgment / In progress / Overdue / Not started) → Needs attention
/// list → empty state.
class DashboardScreen extends ConsumerStatefulWidget {
  /// Switch the host shell to the Tickets tab. Wired by [HomeShell] via
  /// the bottom-nav controller it owns.
  final ValueChanged<ShellTab> onSwitchTab;

  const DashboardScreen({super.key, required this.onSwitchTab});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isCompact = false;
  static const double _compactThreshold = 50.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final offset = _scrollController.offset;
      // Use different thresholds to prevent flickering
      // Enter compact mode when scrolling up past 50px
      // Exit compact mode only when scrolling down near the top (20px)
      if (_isCompact) {
        // In compact mode - require scrolling down to near top to exit
        if (offset < 20) {
          setState(() {
            _isCompact = false;
          });
        }
      } else {
        // In full mode - enter compact when scrolling up
        if (offset > _compactThreshold) {
          setState(() {
            _isCompact = true;
          });
        }
      }
    }
  }

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

  Future<void> _refresh() async {
    // Refresh API counts and needs attention in parallel.
    // User profile is managed by bootstrap and doesn't need refresh here.
    await Future.wait<void>([
      ref.read(dashboardCountsControllerProvider.notifier).refresh(),
      ref.read(needsAttentionControllerProvider.notifier).refresh(),
    ]);
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
  Widget build(BuildContext context) {
    final session = ref.watch(operatorSessionProvider);
    final userProfile = ref.watch(bootstrapUserProfileProvider);
    final asyncCounts = ref.watch(dashboardCountsControllerProvider);
    final asyncView = ref.watch(dashboardViewProvider);
    final asyncNeedsAttention = ref.watch(needsAttentionControllerProvider);
    final inboxUnread = ref.watch(
      notificationInboxControllerProvider.select((v) => v.unreadCount),
    );
    final themeMode = ref.watch(themeModeControllerProvider).valueOrNull;
    final isDark = _resolveDark(context, themeMode);
    final c = context.themeColors;

    // Use user profile from bootstrap data, fallback to session data
    final displayName = userProfile?.firstName != null
        ? '${userProfile!.firstName} ${userProfile.lastName}'
        : session.displayName;
    final initials = (() {
      final name = displayName.trim();
      if (name.isEmpty) return '?';
      final parts = name
          .split(RegExp(r'\s+'))
          .where((p) => p.isNotEmpty)
          .toList();
      if (parts.length == 1) return parts.first[0].toUpperCase();
      return (parts.first[0] + parts.last[0]).toUpperCase();
    })();
    final firstName =
        userProfile?.firstName ?? session.displayName.split(' ').first;
    final profilePictureUrl = userProfile?.pictureProfile?.url;

    return Container(
      color: c.bgSubtle,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Fixed top: app bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AppTopBar(
                avatarInitials: initials,
                avatarImageUrl: profilePictureUrl,
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
                onAvatarTap: () => widget.onSwitchTab(ShellTab.profile),
              ),
            ),

            // Fixed greeting under the app bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: DashboardGreeting(
                firstName: firstName,
                deptHint: () {
                  final role = userProfile?.userHotelStatus.hierarchyRole;
                  if (role != null) {
                    try {
                      return Department.values.firstWhere(
                        (dept) => dept.name == role,
                      );
                    } catch (_) {
                      return null;
                    }
                  }
                  return session.homeDepartment;
                }(),
                now: DateTime.now(),
              ),
            ),

            // Animated stats section - compact when scrolled
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _isCompact
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: asyncCounts.when(
                        data: (counts) => DashboardStatsCompact(
                          incoming: counts.needsAcknowledgmentCount,
                          accepted: counts.notStartedCount,
                          inProgress: counts.inProgressCount,
                          overdue: counts.overdueCount,
                          onTapIncoming: () =>
                              widget.onSwitchTab(ShellTab.tickets),
                          onTapInProgress: () =>
                              widget.onSwitchTab(ShellTab.tickets),
                          onTapOverdue: () =>
                              widget.onSwitchTab(ShellTab.tickets),
                          onTapAccepted: () =>
                              widget.onSwitchTab(ShellTab.tickets),
                        ),
                        loading: () => const SizedBox(height: 48),
                        error: (_, _) => const SizedBox(height: 48),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            // Needs attention header - always visible when compact
            if (_isCompact)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Needs Attention',
                      style: TypographyManager.textHeading.copyWith(
                        color: c.fgBase,
                      ),
                    ),
                    InkWell(
                      onTap: () => widget.onSwitchTab(ShellTab.tickets),
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 4,
                        ),
                        child: Text(
                          'View All',
                          style: TypographyManager.textCaption.copyWith(
                            color: c.tagPurpleIcon,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Scrollable content below
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    if (!_isCompact)
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                        sliver: SliverToBoxAdapter(
                          // KPI counts come from the real `dashboard/numbers`
                          // endpoint. Breakdown line stays driven by the local
                          // mock projection until the backend exposes it.
                          child: asyncCounts.when(
                            data: (counts) => DashboardStatsGrid(
                              incoming: counts.needsAcknowledgmentCount,
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
                              onTapIncoming: () =>
                                  widget.onSwitchTab(ShellTab.tickets),
                              onTapInProgress: () =>
                                  widget.onSwitchTab(ShellTab.tickets),
                              onTapOverdue: () =>
                                  widget.onSwitchTab(ShellTab.tickets),
                              onTapAccepted: () =>
                                  widget.onSwitchTab(ShellTab.tickets),
                            ),
                            loading: () => const _StatsSkeleton(),
                            error: (_, _) => const _StatsSkeleton(),
                          ),
                        ),
                      ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        _isCompact ? 30 : 0,
                        16,
                        96,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: asyncNeedsAttention.when(
                          data: (items) => NeedsAttentionApiList(
                            items: items,
                            isLoading: false,
                            showHeader: !_isCompact,
                            onViewAll: () =>
                                widget.onSwitchTab(ShellTab.tickets),
                            onItemTap: (ticketId) {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      TicketDetailScreen(ticketId: ticketId),
                                ),
                              );
                            },
                          ),
                          loading: () => NeedsAttentionApiList(
                            items: const [],
                            isLoading: true,
                            showHeader: !_isCompact,
                            onViewAll: () =>
                                widget.onSwitchTab(ShellTab.tickets),
                            onItemTap: (_) {},
                          ),
                          error: (_, _) => NeedsAttentionApiList(
                            items: const [],
                            isLoading: false,
                            showHeader: !_isCompact,
                            onViewAll: () =>
                                widget.onSwitchTab(ShellTab.tickets),
                            onItemTap: (_) {},
                          ),
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
