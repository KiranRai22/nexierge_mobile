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
import '../../../tickets/presentation/providers/tickets_main_tab_provider.dart';
import '../../../tickets/presentation/widgets/tickets_main_tabs.dart';
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

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _headerAnimationController;

  /// Maximum height of the stats sliver header — full 3-row grid plus its
  /// bottom padding. Generous enough to hold all four KPI cards with their
  /// dotted divider + footer text fully visible; under-sizing this clips
  /// the bottom "Not started" card.
  static const double _statsMaxExtent = 470.0;

  /// Minimum height — compact 1-row chip strip plus its bottom padding.
  /// Stays pinned at the top once the user has scrolled past `_statsMaxExtent
  ///  - _statsMinExtent`, so Needs Attention cards flow underneath rather
  /// than getting hidden behind it.
  ///
  /// Sized to fit each chip's intrinsic Column (icon 20 + gap 4 + value 22 =
  /// 46) plus the chip's vertical chrome (~24) plus the strip's 12px
  /// bottom padding — total ~82, with a small buffer for fonts that scale.
  static const double _statsMinExtent = 88.0;

  /// Current header state: 0.0 = expanded, 1.0 = collapsed
  double _headerShrinkProgress = 0.0;

  /// Whether header is fully collapsed (allows content scrolling)
  bool _isHeaderCollapsed = false;

  @override
  void initState() {
    super.initState();
    _headerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _headerAnimationController.addListener(() {
      setState(() {
        _headerShrinkProgress = _headerAnimationController.value;
      });
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _headerAnimationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    final maxShrinkOffset = _statsMaxExtent - _statsMinExtent;

    if (_isHeaderCollapsed) {
      // When at top, allow header to expand
      if (offset <= 0) {
        _isHeaderCollapsed = false;
        _headerShrinkProgress = 0.0;
        _headerAnimationController.value = 0.0;
        setState(() {});
      }
      return;
    }

    // Header is expanded - map scroll offset to header shrink progress
    if (offset > 0) {
      if (offset <= maxShrinkOffset) {
        // During header collapse phase - animate header based on scroll
        final progress = (offset / maxShrinkOffset).clamp(0.0, 1.0);
        if (_headerShrinkProgress != progress) {
          _headerShrinkProgress = progress;
          _headerAnimationController.value = progress;
          setState(() {});
        }
      } else {
        // Header fully collapsed, mark as collapsed state
        _isHeaderCollapsed = true;
        _headerShrinkProgress = 1.0;
        _headerAnimationController.value = 1.0;
        setState(() {});
      }
    } else if (offset < 0 && _headerShrinkProgress > 0) {
      // Overscroll up - expand header
      _headerShrinkProgress = 0.0;
      _headerAnimationController.value = 0.0;
      setState(() {});
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

  // Navigation functions for dashboard cards
  void _navigateToNeedsAcknowledgment() {
    // Navigate to tickets page and select incoming tab
    widget.onSwitchTab(ShellTab.tickets);
    // Set the main tab to incoming
    ref.read(ticketsMainTabProvider.notifier).state = TicketsMainTab.incoming;
  }

  void _navigateToInProgress() {
    // Navigate to tickets page, select today tab and inprogress filter
    widget.onSwitchTab(ShellTab.tickets);
    ref.read(ticketsMainTabProvider.notifier).state = TicketsMainTab.today;
    ref.read(ticketsFilterProvider.notifier).state = 'inprogress';
  }

  void _navigateToOverdue() {
    // Navigate to tickets page, select today tab and overdue filter
    widget.onSwitchTab(ShellTab.tickets);
    ref.read(ticketsMainTabProvider.notifier).state = TicketsMainTab.today;
    ref.read(ticketsFilterProvider.notifier).state = 'overdue';
  }

  void _navigateToNotStarted() {
    // Navigate to tickets page, select today tab and accepted filter
    widget.onSwitchTab(ShellTab.tickets);
    ref.read(ticketsMainTabProvider.notifier).state = TicketsMainTab.today;
    ref.read(ticketsFilterProvider.notifier).state = 'accepted';
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

            // Scrollable content. The stats grid lives inside a pinned
            // SliverPersistentHeader that smoothly shrinks + cross-fades
            // into the compact 1-row strip as the user scrolls, instead of
            // toggling layouts at a threshold (which jumped abruptly and
            // could hide the first Needs Attention card behind the strip).
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _DashboardStatsHeaderDelegate(
                        maxHeight: _statsMaxExtent,
                        minHeight: _statsMinExtent,
                        backgroundColor: c.bgSubtle,
                        shrinkProgress: _headerShrinkProgress,
                        fullGrid: asyncCounts.when(
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
                            onTapIncoming: _navigateToNeedsAcknowledgment,
                            onTapInProgress: _navigateToInProgress,
                            onTapOverdue: _navigateToOverdue,
                            onTapAccepted: _navigateToNotStarted,
                          ),
                          loading: () => const _StatsSkeleton(),
                          error: (_, _) => const _StatsSkeleton(),
                        ),
                        compactStrip: asyncCounts.when(
                          data: (counts) => DashboardStatsCompact(
                            incoming: counts.needsAcknowledgmentCount,
                            accepted: counts.notStartedCount,
                            inProgress: counts.inProgressCount,
                            overdue: counts.overdueCount,
                            onTapIncoming: _navigateToNeedsAcknowledgment,
                            onTapInProgress: _navigateToInProgress,
                            onTapOverdue: _navigateToOverdue,
                            onTapAccepted: _navigateToNotStarted,
                          ),
                          loading: () => const SizedBox(height: 48),
                          error: (_, _) => const SizedBox(height: 48),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                      sliver: SliverToBoxAdapter(
                        child: asyncNeedsAttention.when(
                          data: (items) => NeedsAttentionApiList(
                            items: items,
                            isLoading: false,
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
                            onViewAll: () =>
                                widget.onSwitchTab(ShellTab.tickets),
                            onItemTap: (_) {},
                          ),
                          error: (_, _) => NeedsAttentionApiList(
                            items: const [],
                            isLoading: false,
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

/// SliverPersistentHeader delegate that smoothly shrinks the dashboard's
/// stats area as the user scrolls. The full 3-row grid sits at the top of
/// the header zone and fades out as `shrinkOffset` grows; the compact
/// 1-row strip sits at the bottom (anchored to the always-visible
/// `minExtent` band) and fades in. The header pins at `minExtent`, so the
/// Needs Attention list slides underneath it instead of being hidden by
/// an absolutely-positioned compact bar (which was the old bug).
class _DashboardStatsHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget fullGrid;
  final Widget compactStrip;
  final double maxHeight;
  final double minHeight;
  final Color backgroundColor;
  final double shrinkProgress;

  _DashboardStatsHeaderDelegate({
    required this.fullGrid,
    required this.compactStrip,
    required this.maxHeight,
    required this.minHeight,
    required this.backgroundColor,
    required this.shrinkProgress,
  });

  @override
  double get maxExtent => maxHeight;

  @override
  double get minExtent => minHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    // Use shrinkProgress from animation controller
    final t = shrinkProgress.clamp(0.0, 1.0);
    return Container(
      color: backgroundColor,
      child: ClipRect(
        child: Stack(
          children: [
            // Full grid — top-aligned in the header zone, fades out as the
            // header shrinks. IgnorePointer flips once it's mostly gone so
            // taps don't land on invisible cards.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                ignoring: t > 0.5,
                child: Opacity(
                  opacity: 1.0 - t,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: fullGrid,
                  ),
                ),
              ),
            ),
            // Compact strip — anchored to the bottom (always inside the
            // pinned `minExtent` band), fades in symmetrically.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: minExtent,
              child: IgnorePointer(
                ignoring: t < 0.5,
                child: Opacity(
                  opacity: t,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: compactStrip,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_DashboardStatsHeaderDelegate oldDelegate) {
    return oldDelegate.maxHeight != maxHeight ||
        oldDelegate.minHeight != minHeight ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.fullGrid != fullGrid ||
        oldDelegate.compactStrip != compactStrip ||
        oldDelegate.shrinkProgress != shrinkProgress;
  }
}
