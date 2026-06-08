import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_mode_controller.dart';
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

  static const double _statsMaxExtent = 470.0;
  static const double _statsMinExtent = 88.0;

  // Tracks the last scroll direction so snap knows which boundary to target.
  ScrollDirection _lastScrollDirection = ScrollDirection.idle;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Called by the NotificationListener on every scroll event.
  /// Tracks direction while scrolling; snaps to a boundary when the user
  /// lifts their finger (UserScrollNotification direction == idle).
  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta ?? 0;
      if (delta != 0) {
        _lastScrollDirection =
            delta > 0 ? ScrollDirection.forward : ScrollDirection.reverse;
      }
    } else if (notification is UserScrollNotification &&
        notification.direction == ScrollDirection.idle) {
      _snapHeaderIfNeeded();
    }
    return false;
  }

  /// Snaps the header to either fully expanded (offset 0) or fully collapsed
  /// (offset == maxShrinkOffset) when the finger is released mid-transition.
  /// Direction of the last movement determines which boundary wins.
  void _snapHeaderIfNeeded() {
    if (!_scrollController.hasClients) return;
    final offset = _scrollController.offset;
    const maxShrinkOffset = _statsMaxExtent - _statsMinExtent;
    if (offset <= 0 || offset >= maxShrinkOffset) return;

    final target = _lastScrollDirection == ScrollDirection.forward
        ? maxShrinkOffset // snap to collapsed
        : 0.0; // snap to expanded

    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  void _openNotifications(BuildContext context) {
    ref.read(notificationInboxControllerProvider.notifier).refreshUnreadCount();
    NotificationsSheet.show(
      context,
      onOpenTicket: (ticketId) => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => TicketDetailScreen(ticketId: ticketId),
        ),
      ),
      onOpenAllTickets: () => widget.onSwitchTab(ShellTab.tickets),
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
  void _navigateToIncoming() {
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

  void _navigateToDone() {
    // Navigate to tickets page, select today tab and done filter
    widget.onSwitchTab(ShellTab.tickets);
    ref.read(ticketsMainTabProvider.notifier).state = TicketsMainTab.today;
    ref.read(ticketsFilterProvider.notifier).state = 'done';
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

    // Compute greeting text inline (previously owned by DashboardGreeting widget)
    final s = context.l10n;
    final now = DateTime.now();
    final greetingText = now.hour < 12
        ? s.dashboardGreetingMorning(firstName)
        : now.hour < 18
        ? s.dashboardGreetingAfternoon(firstName)
        : s.dashboardGreetingEvening(firstName);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final deptHint = () {
      final role = userProfile?.userHotelStatus.hierarchyRole;
      if (role != null) {
        try {
          return Department.values.firstWhere((d) => d.name == role);
        } catch (_) {
          return null;
        }
      }
      return session.homeDepartment;
    }();
    final dateLine = [
      DateFormat.EEEE(locale).format(now),
      '·',
      DateFormat.jm(locale).format(now),
      if (deptHint != null) '· ${deptHint.label(s)}',
    ].join(' ');

    return Container(
      color: c.bgSubtle,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top bar with greeting integrated next to avatar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AppTopBar(
                avatarInitials: initials,
                avatarImageUrl: profilePictureUrl,
                isDarkMode: isDark,
                unreadCount: inboxUnread,
                greeting: greetingText,
                subGreeting: dateLine,
                onThemeToggle: () =>
                    ref.read(themeModeControllerProvider.notifier).toggle(),
                onNotifications: () => _openNotifications(context),
                onAvatarTap: () => widget.onSwitchTab(ShellTab.profile),
                onRefresh: _refresh,
              ),
            ),

            // Scrollable content. A NotificationListener catches scroll
            // events so we can snap the stats header to either fully
            // expanded or fully collapsed — the user never has to scroll
            // carefully through the transition zone.
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: NotificationListener<ScrollNotification>(
                  onNotification: _onScrollNotification,
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
                        fullGrid: asyncCounts.when(
                          data: (counts) => Padding(
                            padding: const EdgeInsets.only(top: 20.0),
                            child: DashboardStatsGrid(
                              incoming: counts.incomingCount,
                              inProgress: counts.inProgressCount,
                              overdue: counts.overdueCount,
                              done: counts.doneCount,
                              breakdown: asyncView.maybeWhen(
                                data: (v) => v.incomingBreakdown,
                                orElse: () => const IncomingBreakdown(
                                  universal: 0,
                                  catalog: 0,
                                  manual: 0,
                                ),
                              ),
                              onTapIncoming: _navigateToIncoming,
                              onTapInProgress: _navigateToInProgress,
                              onTapOverdue: _navigateToOverdue,
                              onTapDone: _navigateToDone,
                            ),
                          ),
                          loading: () => const _StatsSkeleton(),
                          error: (_, _) => const _StatsSkeleton(),
                        ),
                        compactStrip: asyncCounts.when(
                          data: (counts) => DashboardStatsCompact(
                            incoming: counts.incomingCount,
                            inProgress: counts.inProgressCount,
                            overdue: counts.overdueCount,
                            done: counts.doneCount,
                            onTapIncoming: _navigateToIncoming,
                            onTapInProgress: _navigateToInProgress,
                            onTapOverdue: _navigateToOverdue,
                            onTapDone: _navigateToDone,
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
      inProgress: 0,
      overdue: 0,
      done: 0,
      breakdown: const IncomingBreakdown(universal: 0, catalog: 0, manual: 0),
      onTapIncoming: _noop,
      onTapInProgress: _noop,
      onTapOverdue: _noop,
      onTapDone: _noop,
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

  _DashboardStatsHeaderDelegate({
    required this.fullGrid,
    required this.compactStrip,
    required this.maxHeight,
    required this.minHeight,
    required this.backgroundColor,
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
    final maxShrinkOffset = maxHeight - minHeight;
    final t = (shrinkOffset / maxShrinkOffset).clamp(0.0, 1.0);

    // Sequential (non-overlapping) transition:
    //   t 0.0→0.5  full grid fades out completely
    //   t 0.5→1.0  compact strip fades in
    // The two layouts are never both visible at the same time.
    final fullGridOpacity = (1.0 - t * 2).clamp(0.0, 1.0);
    final compactOpacity = ((t - 0.5) * 2).clamp(0.0, 1.0);

    return Container(
      color: backgroundColor,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Full grid — fades out in first half of collapse
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                ignoring: t >= 0.5,
                child: Opacity(
                  opacity: fullGridOpacity,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: fullGrid,
                  ),
                ),
              ),
            ),
            // Compact strip — fades in during second half of collapse
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                ignoring: t < 0.5,
                child: Opacity(
                  opacity: compactOpacity,
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
        oldDelegate.compactStrip != compactStrip;
  }
}
