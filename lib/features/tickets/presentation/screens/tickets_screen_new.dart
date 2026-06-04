// ─── V2 TICKETS SCREEN (2026-05-14) ────────────────────────────
// Implements the v2 5-tab model with 4 main tabs (Incoming, Today,
// Backlog, Done) and nested Today sub-tabs (All, In Progress, Overdue).
// Uses v2 paged providers for KPI counts and filtering.
// ─────────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/services/sound_manager.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../core/theme/unified_theme_manager.dart';
import '../../../../core/theme/theme_mode_controller.dart';
import '../../../../core/theme/typography_manager.dart';
import '../../../../core/time/server_clock.dart';
import '../../../shell/presentation/widgets/app_bottom_nav.dart';
import '../../domain/entities/my_ticket.dart';
import '../../domain/models/ticket.dart';
import '../../../auth/presentation/providers/user_profile_controller.dart';
import '../providers/my_tickets_list_controller.dart';
import '../providers/my_tickets_notifier.dart';
import '../providers/session_providers.dart';
import '../providers/ticket_busy_provider.dart';
import '../providers/tickets_list_controller.dart';
import '../providers/tickets_main_tab_provider.dart';
import '../providers/tickets_paged_notifier.dart';
import '../widgets/skeletons/ticket_skeletons.dart';
// import '../widgets/ticket_card_new.dart'; // ← backup — uncomment to revert
import '../widgets/ticket_card_compact.dart';
import '../widgets/live_empty_state.dart';
import '../widgets/tickets_top_bar.dart';
import '../widgets/tickets_main_tabs.dart';
import '../widgets/tickets_filter_chips.dart';
import '../widgets/ticket_filters_sheet.dart';
import '../widgets/mark_done_bottom_sheet.dart';
import '../widgets/start_work_confirmation_bottom_sheet.dart';
import '../../../notifications/presentation/widgets/notifications_sheet.dart';
import '../../../notifications/presentation/providers/notification_inbox_controller.dart';
import 'ticket_detail_screen.dart';
import '../../../shell/presentation/widgets/center_fab.dart';
import '../../../shell/presentation/screens/create_router.dart';
import '../../data/repositories/ticket_repository.dart';
import '../../../../core/error/error_handler.dart';

/// Updated tickets screen matching the provided design
class TicketsScreenNew extends ConsumerStatefulWidget {
  final ValueChanged<ShellTab> onSwitchTab;

  const TicketsScreenNew({super.key, required this.onSwitchTab});

  @override
  ConsumerState<TicketsScreenNew> createState() => _TicketsScreenNewState();
}

class _TicketsScreenNewState extends ConsumerState<TicketsScreenNew>
    with WidgetsBindingObserver {
  late final TextEditingController _searchCtl;
  bool _isSearchVisible = false;
  bool _backlogExpanded = false;

  @override
  void initState() {
    super.initState();
    _searchCtl = TextEditingController();
    WidgetsBinding.instance.addObserver(this);

    // Initialize filter based on current tab (runs once on first load)
    // This ensures the correct filter chip is selected when screen first appears
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final currentTab = ref.read(ticketsMainTabProvider);
      final currentFilter = ref.read(ticketsFilterProvider);
      // Only set if not already the correct value (avoid unnecessary updates)
      final expectedFilter = switch (currentTab) {
        TicketsMainTab.today => 'active',
        TicketsMainTab.backlog => 'all',
        TicketsMainTab.incoming => 'newest',
        TicketsMainTab.done => 'newest',
      };
      //debugPrint('[TicketsScreen] initState - Tab: $currentTab, Current filter: "$currentFilter", Expected: "$expectedFilter"');
      if (currentFilter != expectedFilter) {
        //debugPrint('[TicketsScreen] initState - Setting filter to: "$expectedFilter"');
        ref.read(ticketsFilterProvider.notifier).state = expectedFilter;
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchCtl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // On app resume, do one quiet refresh to catch any websocket frames
    // missed while backgrounded. The existing realtime stream handles
    // foreground updates from then on.
    if (state == AppLifecycleState.resumed && mounted) {
      // ignore: discarded_futures
      ref.read(myTicketsNotifierProvider.notifier).refresh();
    }
  }

  void _openNotifications(BuildContext context) {
    ref.read(notificationInboxControllerProvider.notifier).refreshUnreadCount();
    NotificationsSheet.show(
      context,
      onOpenTicket: (ticketId) {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => TicketDetailScreen(ticketId: ticketId),
          ),
        );
      },
    );
  }

  Future<void> _refresh() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    final tab = _ticketsTabFromMain(ref.read(ticketsMainTabProvider));
    final spec = ref.read(ticketsPagedSpecProvider(tab));
    await ref.read(ticketsPagedProvider(spec).notifier).refresh();
  }

  /// Only Today tab has inline filter chips (active/overdue).
  bool _tabHasFilters(TicketsMainTab tab) => tab == TicketsMainTab.today;

  void _toggleSearch() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
      if (!_isSearchVisible) {
        _searchCtl.clear();
        ref.read(ticketsSearchQueryProvider.notifier).state = '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mainTab = ref.watch(ticketsMainTabProvider);
    final selectedFilter = ref.watch(ticketsFilterProvider);
    //debugPrint('[TicketsScreen] BUILD - mainTab: $mainTab, selectedFilter: "$selectedFilter"');
    // Tab transitions: rely on the realtime cache for freshness — no
    // refresh-on-tap. Reset the chip state to the default of each tab so
    // the operator doesn't carry a stale filter across tabs.
    // Also handles initial load when prev is null (first build).
    ref.listen<TicketsMainTab>(ticketsMainTabProvider, (prev, next) {
      // If prev is null, this is the initial load - still apply the filter
      // If prev == next, ignore (no actual change)
      if (prev != null && prev == next) return;
      switch (next) {
        case TicketsMainTab.today:
          ref.read(ticketsFilterProvider.notifier).state = 'active';
          break;
        case TicketsMainTab.backlog:
          ref.read(ticketsFilterProvider.notifier).state = 'all';
          break;
        case TicketsMainTab.incoming:
          ref.read(ticketsFilterProvider.notifier).state = 'newest';
          break;
        case TicketsMainTab.done:
          ref.read(ticketsFilterProvider.notifier).state = 'newest';
          break;
      }
      // Refresh the newly-selected tab if its data is older than 30 s.
      // This keeps lists fresh without hammering the API on every rapid swipe.
      if (prev != null) {
        final tab = _ticketsTabFromMain(next);
        final spec = ref.read(ticketsPagedSpecProvider(tab));
        ref
            .read(ticketsPagedProvider(spec).notifier)
            .refreshIfStale(const Duration(seconds: 30));
      }
    });

    final userProfile = ref.watch(userProfileProvider);
    final session = ref.watch(operatorSessionProvider);
    final themeMode =
        ref.watch(themeModeControllerProvider).valueOrNull ?? ThemeMode.system;
    final isDarkMode = themeMode == ThemeMode.dark;
    final inboxUnread = ref.watch(
      notificationInboxControllerProvider.select((v) => v.totalUnreadCount),
    );

    final c = context.themeColors;

    // Calculate counts for each main tab from the paged providers'
    // server-reported totals.
    final counts = _calculateTabCounts();

    // Use user profile data if available, fallback to session data
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
    final profilePictureUrl = userProfile?.pictureProfile?.url;

    return Scaffold(
      backgroundColor: c.bgBase,
      floatingActionButton: CenterFab(
        onPressed: () async {
          SoundManager.instance.play(SoundCategory.button);
          final submitted = await CreateRouter.openCreate(context, ref);
          if (submitted && mounted) {
            widget.onSwitchTab(ShellTab.tickets);
          }
        },
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top bar: avatar + "All Tickets" title (left), search / filter / bell (right)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TicketsTopBar(
                avatarInitials: initials,
                avatarImageUrl: profilePictureUrl,
                unreadCount: inboxUnread,
                isDarkMode: isDarkMode,
                title:
                    '${context.l10n.activityTypeAll} ${context.l10n.navTickets}',
                onFilter: () => _showFilterSheet(context),
                filterActiveCount:
                    ref.watch(resolvedTicketsFilterProvider).activeCount,
                onThemeToggle: () =>
                    ref.read(themeModeControllerProvider.notifier).toggle(),
                onNotifications: () => _openNotifications(context),
                onSearchToggle: _toggleSearch,
                isSearchVisible: _isSearchVisible,
                onAvatarTap: () => widget.onSwitchTab(ShellTab.profile),
                onRefresh: _refresh,
              ),
            ),

            // Search field (toggleable)
            if (_isSearchVisible)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: _SearchField(controller: _searchCtl),
              ),

            // Main tabs with counts (Backlog collapsible)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TicketsMainTabs(
                selectedTab: mainTab,
                onChanged: (tab) =>
                    ref.read(ticketsMainTabProvider.notifier).state = tab,
                counts: counts,
                isBacklogExpanded: _backlogExpanded,
                onToggleBacklog: () {
                  final collapsing = _backlogExpanded;
                  setState(() => _backlogExpanded = !_backlogExpanded);
                  // If collapsing while backlog is selected, switch to Today
                  if (collapsing &&
                      ref.read(ticketsMainTabProvider) ==
                          TicketsMainTab.backlog) {
                    ref.read(ticketsMainTabProvider.notifier).state =
                        TicketsMainTab.today;
                  }
                },
              ),
            ),

            // Filter chips — slide in/out smoothly when tab changes
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              child: _tabHasFilters(mainTab)
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                      child: TicketsFilterChips(
                        selectedTab: mainTab,
                        selectedFilter: selectedFilter,
                        filterCounts: mainTab == TicketsMainTab.backlog
                            ? _backlogFilterCounts()
                            : mainTab == TicketsMainTab.today
                                ? _todayFilterCounts()
                                : null,
                        onFilterChanged: (filter) =>
                            ref.read(ticketsFilterProvider.notifier).state =
                                filter,
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),

            // Tickets list — fade in new tab only; old tab hidden immediately
            // to prevent stale content from a previous tab bleeding through
            // during the transition.
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeIn,
                  ),
                  child: child,
                ),
                layoutBuilder: (currentChild, previousChildren) => Stack(
                  alignment: Alignment.topCenter,
                  children: <Widget>[
                    // Collapse previous tab content instantly — no fade-out
                    ...previousChildren.map(
                      (child) => Opacity(opacity: 0.0, child: child),
                    ),
                    if (currentChild != null) currentChild,
                  ],
                ),
                child: RefreshIndicator(
                  key: ValueKey(mainTab),
                  onRefresh: _refresh,
                  color: c.tagPurpleIcon,
                  child: _buildList(mainTab),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Top-tab badge counts. Sourced from v2 paged providers so they always
  /// match the server-reported itemsTotal. Falls back to zero while loading.
  Map<TicketsMainTab, int> _calculateTabCounts() {
    // V2: Read from paged providers instead of legacy myTicketsNotifier
    final incomingState = ref
        .watch(
          ticketsPagedProvider(
            ref.watch(ticketsPagedSpecProvider(TicketsTab.incoming)),
          ),
        )
        .valueOrNull;
    final inProgressState = ref
        .watch(
          ticketsPagedProvider(
            ref.watch(ticketsPagedSpecProvider(TicketsTab.todayInProgress)),
          ),
        )
        .valueOrNull;
    final backlogState = ref
        .watch(
          ticketsPagedProvider(
            ref.watch(ticketsPagedSpecProvider(TicketsTab.backlog)),
          ),
        )
        .valueOrNull;
    final doneState = ref
        .watch(
          ticketsPagedProvider(
            ref.watch(ticketsPagedSpecProvider(TicketsTab.todayDone)),
          ),
        )
        .valueOrNull;

    return {
      TicketsMainTab.incoming: incomingState?.itemsTotal ?? 0,
      // In Progress badge = total in-progress tickets from server
      // (Filter chips show active/overdue breakdown separately)
      TicketsMainTab.today: inProgressState?.itemsTotal ?? 0,
      TicketsMainTab.backlog: backlogState?.itemsTotal ?? 0,
      TicketsMainTab.done: doneState?.itemsTotal ?? 0,
    };
  }

  /// Today (In Progress) filter-chip counts from v2 paged provider.
  /// Returns zeroes while the cache is still loading.
  /// Calculates active and overdue counts from fetched items.
  Map<String, int> _todayFilterCounts() {
    // V2: Derive from todayInProgress paged provider
    final inProgressState = ref
        .watch(
          ticketsPagedProvider(
            ref.watch(ticketsPagedSpecProvider(TicketsTab.todayInProgress)),
          ),
        )
        .valueOrNull;

    if (inProgressState == null) {
      return const {'active': 0, 'overdue': 0};
    }

    // Use server-reported overdue_count from the in_progress endpoint.
    // Active = total in-progress minus the server-reported overdue count.
    final overdueCount = inProgressState.overdueCount;
    final activeCount = (inProgressState.itemsTotal - overdueCount)
        .clamp(0, inProgressState.itemsTotal);

    return {
      'active': activeCount,
      'overdue': overdueCount,
      // No counts for newest/oldest (sort filters only)
    };
  }

  /// Backlog filter-chip counts from v2 paged provider. Returns zeroes
  /// while the cache is still loading.
  Map<String, int> _backlogFilterCounts() {
    // V2: Derive from backlog paged provider
    final backlogState = ref
        .watch(
          ticketsPagedProvider(
            ref.watch(ticketsPagedSpecProvider(TicketsTab.backlog)),
          ),
        )
        .valueOrNull;

    if (backlogState == null) {
      return const {'all': 0, 'inprogress': 0, 'overdue': 0};
    }

    final inProgressCount = backlogState.items
        .where((t) => t.isInProgress && !t.isOverdue)
        .length;
    final overdueCount = backlogState.items
        .where((t) => t.isInProgress && t.isOverdue)
        .length;

    return {
      'all': backlogState.itemsTotal,
      'inprogress': inProgressCount,
      'overdue': overdueCount,
    };
  }

  void _showFilterSheet(BuildContext context) {
    TicketFiltersSheet.show(context);
  }

  Widget _buildList(TicketsMainTab mainTab) {
    // All tabs are paginated against `/ticketsv2` endpoints. The list
    // widget watches the paged provider for its tab and triggers
    // infinite scroll near the end.
    return _PagedTicketsTabList(tab: _ticketsTabFromMain(mainTab));
  }
}

/// Map TicketsMainTab to the corresponding v2 TicketsTab.
/// For In Progress tab: shows non-overdue IN_PROGRESS tickets.
/// For Overdue tab: shows overdue IN_PROGRESS tickets.
/// For Done tab: uses todayDone (shows only tickets completed today).
TicketsTab _ticketsTabFromMain(TicketsMainTab mainTab) {
  switch (mainTab) {
    case TicketsMainTab.incoming:
      return TicketsTab.incoming;
    case TicketsMainTab.today:
      // Today tab uses todayInProgress provider (all IN_PROGRESS tickets)
      // Active/Overdue filtering is applied client-side via _applyTodaySubFilter
      return TicketsTab.todayInProgress;
    case TicketsMainTab.backlog:
      return TicketsTab.backlog;
    case TicketsMainTab.done:
      return TicketsTab.todayDone;
  }
}

/// Narrows the Today/Backlog tab's already-fetched items down to the
/// chip the operator picked. Incoming and Done are passthrough.
///
/// For Today (In Progress):
/// - active: non-overdue IN_PROGRESS tickets
/// - overdue: overdue IN_PROGRESS tickets
/// - newest/oldest: all IN_PROGRESS tickets (just sorted)
///
/// For Backlog:
/// - all / inprogress / overdue: client narrows by status/overdue flag
List<MyTicket> _applyTodaySubFilter(
  TicketsTab tab,
  List<MyTicket> items,
  String? filter,
) {
  switch (tab) {
    case TicketsTab.todayInProgress:
      // Today tab: filter by active/overdue, or pass through for sort
      switch (filter) {
        case 'active':
          return items
              .where((t) => t.isInProgress && !t.isOverdue)
              .toList(growable: false);
        case 'overdue':
          return items
              .where((t) => t.isInProgress && t.isOverdue)
              .toList(growable: false);
        case 'newest':
        case 'oldest':
        case null:
        default:
          // No status filtering — just sorting
          return items;
      }
    case TicketsTab.overdue:
      // Overdue tab uses same provider as todayInProgress, filtered via that provider's _matchesFilter
      return items;
    case TicketsTab.todayDone:
      // No local filtering — server pre-filtered to DONE (today only)
      return items;
    case TicketsTab.backlog:
      // Filter by chip: all / inprogress / overdue
      switch (filter) {
        case 'inprogress':
          return items
              .where((t) => t.isInProgress && !t.isOverdue)
              .toList(growable: false);
        case 'overdue':
          return items
              .where((t) => t.isInProgress && t.isOverdue)
              .toList(growable: false);
        case 'all':
        case null:
        default:
          return items;
      }
    case TicketsTab.incoming:
    case TicketsTab.doneHistory:
      // No local filtering — server-filtered or sort-only chips
      return items;
  }
}

// ─── LEGACY-V1 (2026-05-14) ──────────────────────────────────────
// V2: Local day bucketing logic no longer needed — server returns
// distinct tabs (todayInProgress vs backlog) with pre-filtered items.
// ─────────────────────────────────────────────────────────────────
// ignore: unused_element
bool _isTransitionedToday(MyTicket t) {
  if (t.dueAt <= 0) return false;
  final dt = DateTime.fromMillisecondsSinceEpoch(t.dueAt).toLocal();
  final now = ServerClock.now();
  return dt.year == now.year && dt.month == now.month && dt.day == now.day;
}

/// Builds an `onAccept` handler for NEW tickets.
/// Shows confirmation sheet, then calls V2 start API to move directly
/// to IN_PROGRESS with default 15-minute due window.
VoidCallback _acceptHandler(
  BuildContext context,
  WidgetRef ref,
  Ticket ticket,
) {
  return () async {
    if (ref.read(ticketBusyProvider).contains(ticket.id)) return;

    await showStartWorkConfirmation(
      context: context,
      onConfirm: () async {
        final busy = ref.read(ticketBusyProvider.notifier)..mark(ticket.id);
        for (final tab in kAllTicketsTabs) {
          final spec = ref.read(ticketsPagedSpecProvider(tab));
          ref
              .read(ticketsPagedProvider(spec).notifier)
              .markTicketTransitioning(ticket.id);
        }
        final incomingSpec = ref.read(
          ticketsPagedSpecProvider(TicketsTab.incoming),
        );
        final todayInProgressSpec = ref.read(
          ticketsPagedSpecProvider(TicketsTab.todayInProgress),
        );
        ref
            .read(ticketsPagedProvider(incomingSpec).notifier)
            .updateTabCountImmediate(delta: -1);
        ref
            .read(ticketsPagedProvider(todayInProgressSpec).notifier)
            .updateTabCountImmediate(delta: 1);
        try {
          final dueAt = ServerClock.now().add(const Duration(minutes: 15));
          await ref
              .read(ticketRepositoryProvider)
              .startTicketV2(
                ticketId: ticket.id,
                dueAt: dueAt,
              );
          ref
              .read(ticketsPagedProvider(incomingSpec).notifier)
              .updateTicketStatusImmediate(ticket.id, 'IN_PROGRESS');
          ref
              .read(ticketsPagedProvider(todayInProgressSpec).notifier)
              .updateTicketStatusImmediate(ticket.id, 'IN_PROGRESS');
          ref.read(myTicketsNotifierProvider.notifier).refresh();
        } catch (e) {
          ref
              .read(ticketsPagedProvider(incomingSpec).notifier)
              .updateTabCountImmediate(delta: 1);
          ref
              .read(ticketsPagedProvider(todayInProgressSpec).notifier)
              .updateTabCountImmediate(delta: -1);
          if (context.mounted) context.showFailure(e.toString());
          rethrow;
        } finally {
          busy.clear(ticket.id);
        }
      },
    );
  };
}

VoidCallback _openHandler(BuildContext context, Ticket ticket) {
  return () => Navigator.of(context).push(
    MaterialPageRoute<void>(
      // Forward the list-built Ticket as a preset so the detail header /
      // type / source come straight from what the user just saw on the
      // card, no cache lookup race.
      builder: (_) =>
          TicketDetailScreen(ticketId: ticket.id, presetTicket: ticket),
    ),
  );
}

Future<void> _startWorkHandler(
  BuildContext context,
  WidgetRef ref,
  Ticket ticket,
) async {
  if (ref.read(ticketBusyProvider).contains(ticket.id)) return;
  await showStartWorkConfirmation(
    context: context,
    onConfirm: () async {
      final busy = ref.read(ticketBusyProvider.notifier)..mark(ticket.id);
      for (final tab in kAllTicketsTabs) {
        final spec = ref.read(ticketsPagedSpecProvider(tab));
        ref
            .read(ticketsPagedProvider(spec).notifier)
            .markTicketTransitioning(ticket.id);
      }
      final todayInProgressSpec = ref.read(
        ticketsPagedSpecProvider(TicketsTab.todayInProgress),
      );
      try {
        await ref
            .read(ticketRepositoryProvider)
            .changeTicketStatus(ticketId: ticket.id, newStatus: 'IN_PROGRESS');
        ref
            .read(ticketsPagedProvider(todayInProgressSpec).notifier)
            .updateTicketStatusImmediate(ticket.id, 'IN_PROGRESS');
        ref.read(myTicketsNotifierProvider.notifier).refresh();
      } catch (e) {
        if (context.mounted) context.showFailure(e.toString());
        rethrow;
      } finally {
        busy.clear(ticket.id);
      }
    },
  );
}

Future<void> _markDoneHandler(
  BuildContext context,
  WidgetRef ref,
  Ticket ticket,
) async {
  if (ref.read(ticketBusyProvider).contains(ticket.id)) return;
  await MarkDoneBottomSheet.showWithCallback(
    context,
    isRequired: ticket.isOverdue,
    onConfirm: (note) async {
      final busy = ref.read(ticketBusyProvider.notifier)..mark(ticket.id);
      for (final tab in kAllTicketsTabs) {
        final spec = ref.read(ticketsPagedSpecProvider(tab));
        ref
            .read(ticketsPagedProvider(spec).notifier)
            .markTicketTransitioning(ticket.id);
      }
      final todayInProgressSpec = ref.read(
        ticketsPagedSpecProvider(TicketsTab.todayInProgress),
      );
      final doneHistorySpec = ref.read(
        ticketsPagedSpecProvider(TicketsTab.doneHistory),
      );
      ref
          .read(ticketsPagedProvider(todayInProgressSpec).notifier)
          .updateTabCountImmediate(delta: -1);
      ref
          .read(ticketsPagedProvider(doneHistorySpec).notifier)
          .updateTabCountImmediate(delta: 1);
      try {
        await ref
            .read(ticketRepositoryProvider)
            .markDoneWithNote(ticketId: ticket.id, resolutionNote: note);
        ref
            .read(ticketsPagedProvider(todayInProgressSpec).notifier)
            .updateTicketStatusImmediate(ticket.id, 'DONE');
        ref
            .read(ticketsPagedProvider(doneHistorySpec).notifier)
            .updateTicketStatusImmediate(ticket.id, 'DONE');
        ref.read(myTicketsNotifierProvider.notifier).refresh();
      } catch (e) {
        ref
            .read(ticketsPagedProvider(todayInProgressSpec).notifier)
            .updateTabCountImmediate(delta: 1);
        ref
            .read(ticketsPagedProvider(doneHistorySpec).notifier)
            .updateTabCountImmediate(delta: -1);
        if (context.mounted) context.showFailure(e.toString());
        rethrow;
      } finally {
        busy.clear(ticket.id);
      }
    },
  );
}

/// Paginated tab list. One instance per tab — watches the matching
/// `ticketsPagedProvider`, renders rows via `TicketCardNew`, and triggers
/// the next-page fetch when the user scrolls within ~3 items of the end.
class _PagedTicketsTabList extends ConsumerStatefulWidget {
  final TicketsTab tab;
  const _PagedTicketsTabList({required this.tab});

  @override
  ConsumerState<_PagedTicketsTabList> createState() =>
      _PagedTicketsTabListState();
}

class _PagedTicketsTabListState extends ConsumerState<_PagedTicketsTabList> {
  late final ScrollController _scrollCtl;

  @override
  void initState() {
    super.initState();
    _scrollCtl = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtl
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollCtl.hasClients) return;
    final pos = _scrollCtl.position;
    // Guard: list must actually be long enough to scroll before triggering.
    // Without this, short lists (e.g. 2 overdue cards) always satisfy
    // `pixels >= maxScrollExtent - 300` and fire a spurious API call.
    if (pos.maxScrollExtent < 1) return;
    if (pos.pixels >= pos.maxScrollExtent - 300) {
      final spec = ref.read(ticketsPagedSpecProvider(widget.tab));
      ref.read(ticketsPagedProvider(spec).notifier).loadNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final spec = ref.watch(ticketsPagedSpecProvider(widget.tab));
    final asyncState = ref.watch(ticketsPagedProvider(spec));

    // Keep sort order in sync with the advanced filter.
    final advancedFilter = ref.watch(resolvedTicketsFilterProvider);
    final filter = ref.watch(ticketsFilterProvider);

    final order = advancedFilter.newestFirst
        ? TicketsSortOrder.newestFirst
        : TicketsSortOrder.oldestFirst;

    // Sync sort order after build to prevent infinite loop
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final currentSpec = ref.read(ticketsPagedSpecProvider(widget.tab));
        ref
            .read(ticketsPagedProvider(currentSpec).notifier)
            .setSortOrder(order);
      }
    });

    return asyncState.when(
      loading: () => const _LoadingList(),
      error: (e, _) => _ErrorView(error: e),
      data: (page) {
        // Debug: Log items and their status for troubleshooting
        if (widget.tab == TicketsTab.todayInProgress && page.items.isNotEmpty) {
          //debugPrint('=== DEBUG: Today In Progress Tab ===');
          //debugPrint('Total items from API: ${page.items.length}');
          for (final item in page.items) {
            //debugPrint('Ticket ${item.id}: status=${item.status}, isInProgress=${item.isInProgress}, isOverdue=${item.isOverdue}, dueAt=${item.dueAt}');
          }
          //debugPrint('Current filter: $filter');
          final activeCount = page.items.where((t) => t.isInProgress && !t.isOverdue).length;
          final overdueCount = page.items.where((t) => t.isInProgress && t.isOverdue).length;
          //debugPrint('Active count: $activeCount, Overdue count: $overdueCount');
          //debugPrint('=====================================');
        }
        // Apply Backlog sub-filter (all / inprogress / overdue) on top
        // of the server-side status filter. Other tabs use server-side
        // filtering exclusively.
        final visibleItems = _applyTodaySubFilter(
          widget.tab,
          page.items,
          filter,
        );
        if (visibleItems.isEmpty) return const LiveEmptyState();
        final tickets = visibleItems
            .map(
              (mt) => mapMyTicketToTicket(
                mt,
                workStartedEpoch: mt.lastTransitionAt > 0
                    ? mt.lastTransitionAt
                    : null,
              ),
            )
            .toList(growable: false);
        return ListView.builder(
          controller: _scrollCtl,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(
            16,
            4,
            16,
            120,
          ), // Combined padding with bottom space for bottom nav
          itemCount: tickets.length + (page.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= tickets.length) {
              return const _PaginationLoader();
            }
            final ticket = tickets[index];
            return RepaintBoundary(
              key: ValueKey('ticket_card_${ticket.id}'),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TicketCardCompact(
                  key: ValueKey('ticket_${ticket.id}'),
                  ticket: ticket,
                  onTap: _openHandler(context, ticket),
                  onAccept: _acceptHandler(context, ref, ticket),
                  onStartWork: () => _startWorkHandler(context, ref, ticket),
                  onMarkDone: () => _markDoneHandler(context, ref, ticket),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _PaginationLoader extends StatelessWidget {
  const _PaginationLoader();

  @override
  Widget build(BuildContext context) {
    return const TicketPaginationSkeleton();
  }
}

class _SearchField extends ConsumerWidget {
  final TextEditingController controller;
  const _SearchField({required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.themeColors;
    return TextField(
      controller: controller,
      style: TypographyManager.bodyMedium,
      onChanged: (v) => ref.read(ticketsSearchQueryProvider.notifier).state = v,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: context.l10n.ticketsSearchHint,
        hintStyle: TypographyManager.bodyMedium.copyWith(color: c.fgMuted),
        prefixIcon: Icon(Icons.search_rounded, color: c.fgMuted),
        filled: true,
        fillColor: c.bgField,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.borderBase),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.borderBase),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.tagPurpleIcon),
        ),
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();
  @override
  Widget build(BuildContext context) {
    return const TicketListSkeleton();
  }
}


class _ErrorView extends StatelessWidget {
  final Object error;
  const _ErrorView({required this.error});

  @override
  Widget build(BuildContext context) {
    final message = error is AppException
        ? (error as AppException).localizedMessage(context.l10n)
        : context.l10n.unknownError;

    if (kDebugMode) {
      final orig = error is AppException ? (error as AppException).originalError : null;
      debugPrint('[_ErrorView] type=${error.runtimeType} | $error | originalError=$orig');
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
      children: [
        Icon(
          LucideIcons.triangleAlert,
          size: 56,
          color: context.themeColors.tagRedIcon,
        ),
        const SizedBox(height: 16),
        Text(
          message,
          style: TypographyManager.bodyMedium,
          textAlign: TextAlign.center,
        ),
        if (kDebugMode) ...[
          const SizedBox(height: 12),
          Text(
            error.toString(),
            style: const TextStyle(fontSize: 11, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
