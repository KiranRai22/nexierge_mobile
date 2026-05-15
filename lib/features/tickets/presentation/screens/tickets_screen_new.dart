// ─── V2 TICKETS SCREEN (2026-05-14) ────────────────────────────
// Implements the v2 5-tab model with 4 main tabs (Incoming, Today,
// Backlog, Done) and nested Today sub-tabs (All, In Progress, Overdue).
// Uses v2 paged providers for KPI counts and filtering.
// ─────────────────────────────────────────────────────────────────

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
import '../widgets/ticket_card_new.dart';
import '../widgets/tickets_top_bar.dart';
import '../widgets/tickets_main_tabs.dart';
import '../widgets/tickets_filter_chips.dart';
import '../widgets/filter_department_sheet.dart';
import '../widgets/mark_done_bottom_sheet.dart';
import '../widgets/start_work_confirmation_bottom_sheet.dart';
import '../../../notifications/presentation/widgets/notifications_sheet.dart';
import 'ticket_detail_screen.dart';
import '../../../shell/presentation/widgets/center_fab.dart';
import '../../../shell/presentation/screens/create_router.dart';
import '../../data/repositories/ticket_repository.dart';

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

  @override
  void initState() {
    super.initState();
    _searchCtl = TextEditingController();
    WidgetsBinding.instance.addObserver(this);
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
    await ref.read(ticketsPagedProvider(specForTab(tab)).notifier).refresh();
  }

  /// Check if a tab has filters available
  bool _tabHasFilters(TicketsMainTab tab) {
    switch (tab) {
      case TicketsMainTab.incoming:
        return true; // Has newest/oldest filters
      case TicketsMainTab.today:
      case TicketsMainTab.backlog:
        return true; // Has all/accepted/inprogress/overdue filters
      case TicketsMainTab.done:
        return false; // Filters hidden
    }
  }

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
    // Tab transitions: rely on the realtime cache for freshness — no
    // refresh-on-tap. Reset the chip state to the default of each tab so
    // the operator doesn't carry a stale filter across tabs.
    ref.listen<TicketsMainTab>(ticketsMainTabProvider, (prev, next) {
      if (prev == next) return;
      switch (next) {
        case TicketsMainTab.today:
          // Reset Today to 'all' filter (shows todayInProgress + todayDone combined)
          ref.read(ticketsFilterProvider.notifier).state = 'all';
          break;
        case TicketsMainTab.backlog:
          ref.read(ticketsFilterProvider.notifier).state = 'all';
          break;
        case TicketsMainTab.incoming:
          ref.read(ticketsFilterProvider.notifier).state = 'newest';
          break;
        case TicketsMainTab.done:
          ref.read(ticketsFilterProvider.notifier).state = null;
          break;
      }
    });

    // Today filter-chip counts come from the realtime ticket cache — they
    // update in-place on websocket events without a network round-trip.
    final todayCounts = _todayFilterCounts();
    final userProfile = ref.watch(userProfileProvider);
    final session = ref.watch(operatorSessionProvider);
    final themeMode =
        ref.watch(themeModeControllerProvider).valueOrNull ?? ThemeMode.system;
    final isDarkMode = themeMode == ThemeMode.dark;

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
            // Top bar with search toggle, theme, and notifications
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TicketsTopBar(
                avatarInitials: initials,
                avatarImageUrl: profilePictureUrl,
                hasUnreadNotifications: true,
                isDarkMode: isDarkMode,
                onThemeToggle: () =>
                    ref.read(themeModeControllerProvider.notifier).toggle(),
                onNotifications: () => _openNotifications(context),
                onSearchToggle: _toggleSearch,
                isSearchVisible: _isSearchVisible,
                onAvatarTap: () => widget.onSwitchTab(ShellTab.profile),
              ),
            ),

            // Title row: All Tickets + filter button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Text(
                    '${context.l10n.activityTypeAll} ${context.l10n.navTickets}',
                    style: TypographyManager.headlineSmall.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 24,
                      color: c.fgBase,
                    ),
                  ),
                  const Spacer(),
                  // Funnel filter button in circle
                  Semantics(
                    button: true,
                    label: context.l10n.filterTitle,
                    child: InkWell(
                      onTap: tapSound(() => _showFilterSheet(context)),
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: c.bgSubtle,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: c.borderBase),
                        ),
                        child: Icon(
                          LucideIcons.funnel,
                          size: 18,
                          color: c.fgBase,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search field (toggleable)
            if (_isSearchVisible)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: _SearchField(controller: _searchCtl),
              ),

            // Main tabs with counts
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TicketsMainTabs(
                selectedTab: mainTab,
                onChanged: (tab) =>
                    ref.read(ticketsMainTabProvider.notifier).state = tab,
                counts: counts,
              ),
            ),

            // Filter chips based on selected main tab - only show if tab has filters
            if (_tabHasFilters(mainTab))
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                child: TicketsFilterChips(
                  selectedTab: mainTab,
                  selectedFilter: selectedFilter,
                  filterCounts: mainTab == TicketsMainTab.today
                      ? todayCounts
                      : (mainTab == TicketsMainTab.backlog
                            ? _backlogFilterCounts()
                            : null),
                  onFilterChanged: (filter) =>
                      ref.read(ticketsFilterProvider.notifier).state = filter,
                ),
              ),

            // Tickets list
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                color: c.tagPurpleIcon,
                child: _buildList(mainTab),
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
    final incomingState = ref.watch(
      ticketsPagedProvider(specForTab(TicketsTab.incoming)),
    ).valueOrNull;
    final inProgressState = ref.watch(
      ticketsPagedProvider(specForTab(TicketsTab.todayInProgress)),
    ).valueOrNull;
    final backlogState = ref.watch(
      ticketsPagedProvider(specForTab(TicketsTab.backlog)),
    ).valueOrNull;
    final doneState = ref.watch(
      ticketsPagedProvider(specForTab(TicketsTab.doneHistory)),
    ).valueOrNull;

    return {
      TicketsMainTab.incoming: incomingState?.itemsTotal ?? 0,
      // Today badge = inProgress only (not including doneToday)
      TicketsMainTab.today: inProgressState?.itemsTotal ?? 0,
      TicketsMainTab.backlog: backlogState?.itemsTotal ?? 0,
      TicketsMainTab.done: doneState?.itemsTotal ?? 0,
    };
  }

  /// Today filter-chip counts from v2 paged providers. Returns zeroes
  /// while the cache is still loading. Includes All, In Progress, Overdue
  /// (from inProgress provider) + Done (from doneToday provider).
  Map<String, int> _todayFilterCounts() {
    // V2: Derive from inProgress + doneToday paged providers
    final inProgressState = ref.watch(
      ticketsPagedProvider(specForTab(TicketsTab.todayInProgress)),
    ).valueOrNull;
    final doneTodayState = ref.watch(
      ticketsPagedProvider(specForTab(TicketsTab.todayDone)),
    ).valueOrNull;

    if (inProgressState == null && doneTodayState == null) {
      return const {'all': 0, 'inprogress': 0, 'overdue': 0, 'done': 0};
    }

    final inProgressCount = (inProgressState?.items ?? [])
        .where((t) => !t.isOverdue)
        .length;
    final overdueCount = (inProgressState?.items ?? [])
        .where((t) => t.isOverdue)
        .length;
    final doneCount = doneTodayState?.itemsTotal ?? 0;

    return {
      'all': (inProgressState?.itemsTotal ?? 0) + doneCount,
      'inprogress': inProgressCount,
      'overdue': overdueCount,
      'done': doneCount,
    };
  }

  /// Backlog filter-chip counts from v2 paged provider. Returns zeroes
  /// while the cache is still loading.
  Map<String, int> _backlogFilterCounts() {
    // V2: Derive from backlog paged provider
    final backlogState = ref.watch(
      ticketsPagedProvider(specForTab(TicketsTab.backlog)),
    ).valueOrNull;

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
    FilterDepartmentSheet.show(context);
  }

  Widget _buildList(TicketsMainTab mainTab) {
    // All tabs are paginated against `/ticketsv2` endpoints. The list
    // widget watches the paged provider for its tab and triggers
    // infinite scroll near the end. For Today, the tab selection depends
    // on the active filter chip (all/inprogress/overdue use todayInProgress;
    // done uses todayDone).
    final filter = ref.watch(ticketsFilterProvider);
    return _PagedTicketsTabList(
      tab: _ticketsTabFromMain(mainTab, filter),
    );
  }
}

/// Map TicketsMainTab to the corresponding v2 TicketsTab.
/// For Today tab: if filter=='done', use todayDone provider; otherwise use
/// todayInProgress (filtering via _applyTodaySubFilter for inprogress/overdue).
TicketsTab _ticketsTabFromMain(TicketsMainTab mainTab, [String? todayFilter]) {
  switch (mainTab) {
    case TicketsMainTab.incoming:
      return TicketsTab.incoming;
    case TicketsMainTab.today:
      // V2: Today tab switches providers based on filter chip
      if (todayFilter == 'done') {
        return TicketsTab.todayDone;
      } else {
        // all/inprogress/overdue filters are applied client-side via
        // _applyTodaySubFilter on the todayInProgress provider
        return TicketsTab.todayInProgress;
      }
    case TicketsMainTab.backlog:
      return TicketsTab.backlog;
    case TicketsMainTab.done:
      return TicketsTab.doneHistory;
  }
}

/// Narrows the Today / Backlog tab's already-fetched items down to the
/// chip the operator picked. Other tabs (Incoming, Done, Done History) are passthrough.
///
/// For Today:
/// - todayInProgress (filter: all/inprogress/overdue): server-side IN_PROGRESS,
///   client narrows by overdue flag
/// - todayDone (filter: done): server-side DONE completed today, no narrowing
List<MyTicket> _applyTodaySubFilter(
  TicketsTab tab,
  List<MyTicket> items,
  String? filter,
) {
  // V2: Apply local filtering on top of server-side tabs.
  // - todayInProgress: items are already filtered server-side to IN_PROGRESS
  // - todayDone: items are already filtered server-side to DONE (today only)
  // - backlog: items are server-curated, no day-boundary filtering needed
  // - incoming: NEW status, no filtering needed
  // - doneHistory: DONE status across all time, no filtering needed

  // For todayInProgress and backlog, the filter chips let users narrow
  // further (all / inprogress / overdue). todayDone has no local filtering.
  // Other tabs are passthrough.
  switch (tab) {
    case TicketsTab.todayInProgress:
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
        case 'done': // Shouldn't reach here; done uses todayDone tab
        default:
          return items;
      }
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

/// Builds an `onAccept` handler that opens the acknowledge sheet and
/// applies the resulting status change. When the user picks
/// "Accept & Start" the ticket goes straight to IN_PROGRESS.
// [ACCEPT_AND_START_FLOW] Was: open AcknowledgeTicketBottomSheet to let
// the user pick ETA / notes / Accept vs Accept & Start. New flow: tap on
// the card's button calls acknowledgeAndStartTicket directly with a 15-min
// default due window — no sheet, no intermediate ACCEPTED state.
//
// Original implementation kept below (commented) for reference.
/*
VoidCallback _acceptHandler(
  BuildContext context,
  WidgetRef ref,
  Ticket ticket,
) {
  return () async {
    // Guard at the entry point too: if a previous tap is still in flight
    // and the card overlay hasn't repainted yet, drop the second tap.
    if (ref.read(ticketBusyProvider).contains(ticket.id)) return;

    await AcknowledgeTicketBottomSheet.showWithCallback(
      context: context,
      ticketCode: ticket.code,
      ticketTitle: ticket.title,
      hasGuest: ticket.guest != null,
      onConfirm: (result) async {
        final busy = ref.read(ticketBusyProvider.notifier)..mark(ticket.id);
        // Step 1: Mark ticket as transitioning (shimmer)
        for (final tab in kAllTicketsTabs) {
          ref
              .read(ticketsPagedProvider(specForTab(tab)).notifier)
              .markTicketTransitioning(ticket.id);
        }
        // Step 2: Optimistic tab count deltas
        ref
            .read(
              ticketsPagedProvider(specForTab(TicketsTab.incoming)).notifier,
            )
            .updateTabCountImmediate(delta: -1);
        ref
            .read(ticketsPagedProvider(specForTab(TicketsTab.todayInProgress)).notifier)
            .updateTabCountImmediate(delta: 1);
        try {
          // Step 3: API
          if (result.startImmediately) {
            await ref
                .read(ticketRepositoryProvider)
                .acknowledgeAndStartTicket(
                  ticketId: ticket.id,
                  dueAt: result.dueAtEpochMs,
                  notes: result.notes,
                );
          } else {
            await ref
                .read(ticketRepositoryProvider)
                .acknowledgeTicket(
                  ticketId: ticket.id,
                  dueAt: result.dueAtEpochMs,
                  notes: result.notes,
                );
          }
          // Step 4: Optimistic status patch
          final optimisticStatus = result.startImmediately
              ? 'IN_PROGRESS'
              : 'ACCEPTED';
          ref
              .read(
                ticketsPagedProvider(specForTab(TicketsTab.incoming)).notifier,
              )
              .updateTicketStatusImmediate(ticket.id, optimisticStatus);
          ref
              .read(ticketsPagedProvider(specForTab(TicketsTab.todayInProgress)).notifier)
              .updateTicketStatusImmediate(ticket.id, optimisticStatus);
          ref.read(myTicketsNotifierProvider.notifier).refresh();
        } catch (e) {
          // Revert optimistic count deltas on error and surface the toast.
          ref
              .read(
                ticketsPagedProvider(specForTab(TicketsTab.incoming)).notifier,
              )
              .updateTabCountImmediate(delta: 1);
          ref
              .read(ticketsPagedProvider(specForTab(TicketsTab.todayInProgress)).notifier)
              .updateTabCountImmediate(delta: -1);
          if (context.mounted) context.showFailure(e.toString());
          rethrow; // Keep sheet open so user can retry / dismiss.
        } finally {
          busy.clear(ticket.id);
        }
      },
    );
  };
}
*/

VoidCallback _acceptHandler(
  BuildContext context,
  WidgetRef ref,
  Ticket ticket,
) {
  return () async {
    if (ref.read(ticketBusyProvider).contains(ticket.id)) return;
    final busy = ref.read(ticketBusyProvider.notifier)..mark(ticket.id);
    for (final tab in kAllTicketsTabs) {
      ref
          .read(ticketsPagedProvider(specForTab(tab)).notifier)
          .markTicketTransitioning(ticket.id);
    }
    ref
        .read(ticketsPagedProvider(specForTab(TicketsTab.incoming)).notifier)
        .updateTabCountImmediate(delta: -1);
    ref
        .read(ticketsPagedProvider(specForTab(TicketsTab.todayInProgress)).notifier)
        .updateTabCountImmediate(delta: 1);
    try {
      final dueAt = ServerClock.now()
          .add(const Duration(minutes: 15))
          .millisecondsSinceEpoch;
      await ref
          .read(ticketRepositoryProvider)
          .acknowledgeAndStartTicket(
            ticketId: ticket.id,
            dueAt: dueAt,
            notes: null,
          );
      ref
          .read(
            ticketsPagedProvider(specForTab(TicketsTab.incoming)).notifier,
          )
          .updateTicketStatusImmediate(ticket.id, 'IN_PROGRESS');
      ref
          .read(ticketsPagedProvider(specForTab(TicketsTab.todayInProgress)).notifier)
          .updateTicketStatusImmediate(ticket.id, 'IN_PROGRESS');
      ref.read(myTicketsNotifierProvider.notifier).refresh();
    } catch (e) {
      ref
          .read(
            ticketsPagedProvider(specForTab(TicketsTab.incoming)).notifier,
          )
          .updateTabCountImmediate(delta: 1);
      ref
          .read(ticketsPagedProvider(specForTab(TicketsTab.todayInProgress)).notifier)
          .updateTabCountImmediate(delta: -1);
      if (context.mounted) context.showFailure(e.toString());
    } finally {
      busy.clear(ticket.id);
    }
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
        ref
            .read(ticketsPagedProvider(specForTab(tab)).notifier)
            .markTicketTransitioning(ticket.id);
      }
      try {
        await ref
            .read(ticketRepositoryProvider)
            .changeTicketStatus(ticketId: ticket.id, newStatus: 'IN_PROGRESS');
        ref
            .read(ticketsPagedProvider(specForTab(TicketsTab.todayInProgress)).notifier)
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
    onConfirm: (note) async {
      final busy = ref.read(ticketBusyProvider.notifier)..mark(ticket.id);
      for (final tab in kAllTicketsTabs) {
        ref
            .read(ticketsPagedProvider(specForTab(tab)).notifier)
            .markTicketTransitioning(ticket.id);
      }
      ref
          .read(ticketsPagedProvider(specForTab(TicketsTab.todayInProgress)).notifier)
          .updateTabCountImmediate(delta: -1);
      ref
          .read(ticketsPagedProvider(specForTab(TicketsTab.doneHistory)).notifier)
          .updateTabCountImmediate(delta: 1);
      try {
        await ref
            .read(ticketRepositoryProvider)
            .markDoneWithNote(ticketId: ticket.id, resolutionNote: note);
        ref
            .read(ticketsPagedProvider(specForTab(TicketsTab.todayInProgress)).notifier)
            .updateTicketStatusImmediate(ticket.id, 'DONE');
        ref
            .read(ticketsPagedProvider(specForTab(TicketsTab.doneHistory)).notifier)
            .updateTicketStatusImmediate(ticket.id, 'DONE');
        ref.read(myTicketsNotifierProvider.notifier).refresh();
      } catch (e) {
        ref
            .read(ticketsPagedProvider(specForTab(TicketsTab.todayInProgress)).notifier)
            .updateTabCountImmediate(delta: 1);
        ref
            .read(ticketsPagedProvider(specForTab(TicketsTab.doneHistory)).notifier)
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
    // Trigger when within ~3 ticket cards (~300px) of the bottom.
    if (pos.pixels >= pos.maxScrollExtent - 300) {
      ref
          .read(ticketsPagedProvider(specForTab(widget.tab)).notifier)
          .loadNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final spec = specForTab(widget.tab);
    final asyncState = ref.watch(ticketsPagedProvider(spec));

    // Keep sort order in sync with the filter chip ('newest'/'oldest').
    // Use a separate listener to avoid calling setSortOrder during build.
    final filter = ref.watch(ticketsFilterProvider);
    final order = filter == 'oldest'
        ? TicketsSortOrder.oldestFirst
        : TicketsSortOrder.newestFirst;

    // Sync sort order after build to prevent infinite loop
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(ticketsPagedProvider(spec).notifier).setSortOrder(order);
      }
    });

    return asyncState.when(
      loading: () => const _LoadingList(),
      error: (e, _) => _ErrorView(error: e.toString()),
      data: (page) {
        // Apply Today sub-filter (accepted / inprogress / overdue) on top
        // of the server-side status filter. The server already constrains
        // the list to ACCEPTED + IN_PROGRESS for the Today tab; this
        // narrows further when a chip other than 'all' is selected.
        final visibleItems = _applyTodaySubFilter(
          widget.tab,
          page.items,
          filter,
        );
        if (visibleItems.isEmpty) return const _EmptyView();
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
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TicketCardNew(
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

class _EmptyView extends StatelessWidget {
  const _EmptyView();
  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        Icon(
          Icons.inbox_outlined,
          size: 56,
          color: context.themeColors.fgDisabled,
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            context.l10n.emptyState,
            style: TypographyManager.bodyMedium.copyWith(
              color: context.themeColors.fgMuted,
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  const _ErrorView({required this.error});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
      children: [
        Icon(
          LucideIcons.triangleAlert,
          size: 56,
          color: context.themeColors.tagRedIcon,
        ),
        const SizedBox(height: 12),
        Text(
          context.l10n.unknownError,
          style: TypographyManager.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          error,
          style: TypographyManager.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
