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
import '../providers/tickets_list_controller.dart';
import '../providers/tickets_main_tab_provider.dart';
import '../providers/tickets_paged_notifier.dart';
import '../widgets/skeletons/ticket_skeletons.dart';
import '../widgets/ticket_card_new.dart';
import '../widgets/tickets_top_bar.dart';
import '../widgets/tickets_main_tabs.dart';
import '../widgets/tickets_filter_chips.dart';
import '../widgets/filter_department_sheet.dart';
import '../widgets/acknowledge_ticket_bottom_sheet.dart';
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

  /// Top-tab badge counts. Sourced from the realtime cache so they always
  /// match the filter-chip counts on the Today tab. Falls back to zero
  /// while the cache is still loading.
  Map<TicketsMainTab, int> _calculateTabCounts() {
    final state = ref.watch(myTicketsNotifierProvider).valueOrNull;
    if (state == null) {
      return const {
        TicketsMainTab.incoming: 0,
        TicketsMainTab.today: 0,
        TicketsMainTab.backlog: 0,
        TicketsMainTab.done: 0,
      };
    }
    return {
      TicketsMainTab.incoming: state.incomingCount,
      TicketsMainTab.today: state.todayAllCount,
      TicketsMainTab.backlog: state.backlogAllCount,
      TicketsMainTab.done: state.doneCount,
    };
  }

  /// Today filter-chip counts derived from the realtime cache. Returns
  /// zeroes while the cache is still loading.
  Map<String, int> _todayFilterCounts() {
    final state = ref.watch(myTicketsNotifierProvider).valueOrNull;
    if (state == null) {
      return const {'all': 0, 'accepted': 0, 'inprogress': 0, 'overdue': 0};
    }
    return {
      'all': state.todayAllCount,
      'accepted': state.todayAcceptedCount,
      'inprogress': state.todayInProgressCount,
      'overdue': state.todayOverdueCount,
    };
  }

  /// Backlog filter-chip counts — mirrors [_todayFilterCounts] for the
  /// non-today bucket. Same chip keys so the chip widget needs no changes.
  Map<String, int> _backlogFilterCounts() {
    final state = ref.watch(myTicketsNotifierProvider).valueOrNull;
    if (state == null) {
      return const {'all': 0, 'accepted': 0, 'inprogress': 0, 'overdue': 0};
    }
    return {
      'all': state.backlogAllCount,
      'accepted': state.backlogAcceptedCount,
      'inprogress': state.backlogInProgressCount,
      'overdue': state.backlogOverdueCount,
    };
  }

  void _showFilterSheet(BuildContext context) {
    FilterDepartmentSheet.show(context);
  }

  Widget _buildList(TicketsMainTab mainTab) {
    // All three tabs are paginated against `/tickets/get_my_tickets`. The list
    // widget watches the paged provider for its tab and triggers
    // infinite scroll near the end.
    return _PagedTicketsTabList(tab: _ticketsTabFromMain(mainTab));
  }
}

TicketsTab _ticketsTabFromMain(TicketsMainTab mainTab) {
  switch (mainTab) {
    case TicketsMainTab.incoming:
      return TicketsTab.incoming;
    case TicketsMainTab.today:
      return TicketsTab.today;
    case TicketsMainTab.backlog:
      return TicketsTab.backlog;
    case TicketsMainTab.done:
      return TicketsTab.done;
  }
}

/// Narrows the Today / Backlog tab's already-fetched items down to the
/// chip the operator picked. Incoming and Done tabs are passthrough — their
/// chips are sort-only or absent.
///
/// Day predicate is `last_transition_at` (or its fallback) within today.
/// Today = predicate true; Backlog = predicate false. Overdue is its own
/// bucket and is mutually exclusive with Accepted / In Progress in both.
List<MyTicket> _applyTodaySubFilter(
  TicketsTab tab,
  List<MyTicket> items,
  String? filter,
) {
  final bool Function(MyTicket) dayPredicate;
  switch (tab) {
    case TicketsTab.today:
      dayPredicate = _isTransitionedToday;
      break;
    case TicketsTab.backlog:
      dayPredicate = (t) => !_isTransitionedToday(t);
      break;
    case TicketsTab.incoming:
    case TicketsTab.done:
      return items;
  }
  final scoped = items.where(dayPredicate).toList(growable: false);
  switch (filter) {
    case 'accepted':
      return scoped
          .where((t) => t.isAccepted && !t.isOverdue)
          .toList(growable: false);
    case 'inprogress':
      return scoped
          .where((t) => t.isInProgress && !t.isOverdue)
          .toList(growable: false);
    case 'overdue':
      return scoped
          .where((t) => (t.isAccepted || t.isInProgress) && t.isOverdue)
          .toList(growable: false);
    case 'all':
    case null:
    default:
      return scoped
          .where((t) => t.isAccepted || t.isInProgress)
          .toList(growable: false);
  }
}

/// True when [t]'s `due_at` is on today's local calendar. Today/Backlog
/// bucketing is driven by due date, not by `last_transition_at` — so a
/// non-status patch (e.g. change-due-time pushing due to next week) does
/// NOT pull a backlog ticket into Today. Tickets with no due (`dueAt == 0`)
/// are never Today.
bool _isTransitionedToday(MyTicket t) {
  if (t.dueAt <= 0) return false;
  final dt = DateTime.fromMillisecondsSinceEpoch(t.dueAt).toLocal();
  final now = ServerClock.now();
  return dt.year == now.year && dt.month == now.month && dt.day == now.day;
}

/// Builds an `onAccept` handler that opens the acknowledge sheet and
/// applies the resulting status change. When the user picks
/// "Accept & Start" the ticket goes straight to IN_PROGRESS.
VoidCallback _acceptHandler(
  BuildContext context,
  WidgetRef ref,
  Ticket ticket,
) {
  return () async {
    final result = await AcknowledgeTicketBottomSheet.show(
      context: context,
      ticketCode: ticket.code,
      ticketTitle: ticket.title,
      hasGuest: ticket.guest != null,
    );
    if (result == null || !context.mounted) return;

    // The sheet now resolves the due-at epoch itself for any picked preset
    // or custom date/time. Future dates are accepted — the today-only gate
    // was dropped along with the sheet's "Accept & Start" gating.
    final dueTimeMs = result.dueAtEpochMs;

    try {
      // Step 1: Mark ticket as transitioning (show shimmer effect)
      for (final tab in kAllTicketsTabs) {
        ref
            .read(ticketsPagedProvider(specForTab(tab)).notifier)
            .markTicketTransitioning(ticket.id);
      }

      // Step 2: Update tab counts immediately (optimistic update)
      ref
          .read(ticketsPagedProvider(specForTab(TicketsTab.incoming)).notifier)
          .updateTabCountImmediate(delta: -1);

      ref
          .read(ticketsPagedProvider(specForTab(TicketsTab.today)).notifier)
          .updateTabCountImmediate(delta: 1);

      // Step 3: Make API call
      if (result.startImmediately) {
        // Use acknowledge_and_start API
        await ref
            .read(ticketRepositoryProvider)
            .acknowledgeAndStartTicket(
              ticketId: ticket.id,
              dueAt: dueTimeMs,
              notes: result.notes,
            );
      } else {
        // Use acknowledge API
        await ref
            .read(ticketRepositoryProvider)
            .acknowledgeTicket(
              ticketId: ticket.id,
              dueAt: dueTimeMs,
              notes: result.notes,
            );
      }

      // Step 4: Update ticket status immediately (remove from incoming, add
      // to today). Mirror the API call's target status so the optimistic
      // local view matches what the server just persisted — picking
      // "Accept & Start" lands the ticket in IN_PROGRESS, not ACCEPTED.
      final optimisticStatus =
          result.startImmediately ? 'IN_PROGRESS' : 'ACCEPTED';
      ref
          .read(ticketsPagedProvider(specForTab(TicketsTab.incoming)).notifier)
          .updateTicketStatusImmediate(ticket.id, optimisticStatus);

      ref
          .read(ticketsPagedProvider(specForTab(TicketsTab.today)).notifier)
          .updateTicketStatusImmediate(ticket.id, optimisticStatus);

      // Step 5: Refresh other providers as backup
      ref.read(myTicketsNotifierProvider.notifier).refresh();
    } catch (e) {
      if (context.mounted) {
        context.showFailure(e.toString());
        // Revert optimistic updates on error
        ref
            .read(
              ticketsPagedProvider(specForTab(TicketsTab.incoming)).notifier,
            )
            .updateTabCountImmediate(delta: 1);

        ref
            .read(ticketsPagedProvider(specForTab(TicketsTab.today)).notifier)
            .updateTabCountImmediate(delta: -1);
      }
    }
  };
}

VoidCallback _openHandler(BuildContext context, Ticket ticket) {
  return () => Navigator.of(context).push(
    MaterialPageRoute<void>(
      // Forward the list-built Ticket as a preset so the detail header /
      // type / source come straight from what the user just saw on the
      // card, no cache lookup race.
      builder: (_) => TicketDetailScreen(
        ticketId: ticket.id,
        presetTicket: ticket,
      ),
    ),
  );
}

Future<void> _startWorkHandler(
  BuildContext context,
  WidgetRef ref,
  Ticket ticket,
) async {
  final confirmed = await showStartWorkConfirmation(context: context);
  if (confirmed != true || !context.mounted) return;

  try {
    // Step 1: Mark ticket as transitioning (show shimmer effect)
    for (final tab in kAllTicketsTabs) {
      ref
          .read(ticketsPagedProvider(specForTab(tab)).notifier)
          .markTicketTransitioning(ticket.id);
    }

    // Step 2: Update tab counts immediately (today -> today, count stays same)
    // No count change needed for IN_PROGRESS transition

    // Step 3: Make API call
    await ref
        .read(ticketRepositoryProvider)
        .changeTicketStatus(ticketId: ticket.id, newStatus: 'IN_PROGRESS');

    // Step 4: Update ticket status immediately
    ref
        .read(ticketsPagedProvider(specForTab(TicketsTab.today)).notifier)
        .updateTicketStatusImmediate(ticket.id, 'IN_PROGRESS');

    // Step 5: Refresh other providers as backup
    ref.read(myTicketsNotifierProvider.notifier).refresh();
  } catch (e) {
    if (context.mounted) context.showFailure(e.toString());
  }
}

Future<void> _markDoneHandler(
  BuildContext context,
  WidgetRef ref,
  Ticket ticket,
) async {
  final note = await MarkDoneBottomSheet.show(context);
  if (note == null || !context.mounted) return;

  try {
    // Step 1: Mark ticket as transitioning (show shimmer effect)
    for (final tab in kAllTicketsTabs) {
      ref
          .read(ticketsPagedProvider(specForTab(tab)).notifier)
          .markTicketTransitioning(ticket.id);
    }

    // Step 2: Update tab counts immediately (today -> done)
    ref
        .read(ticketsPagedProvider(specForTab(TicketsTab.today)).notifier)
        .updateTabCountImmediate(delta: -1);

    ref
        .read(ticketsPagedProvider(specForTab(TicketsTab.done)).notifier)
        .updateTabCountImmediate(delta: 1);

    // Step 3: Make API call
    await ref
        .read(ticketRepositoryProvider)
        .markDoneWithNote(ticketId: ticket.id, resolutionNote: note);

    // Step 4: Update ticket status immediately (remove from today, add to done)
    ref
        .read(ticketsPagedProvider(specForTab(TicketsTab.today)).notifier)
        .updateTicketStatusImmediate(ticket.id, 'DONE');

    ref
        .read(ticketsPagedProvider(specForTab(TicketsTab.done)).notifier)
        .updateTicketStatusImmediate(ticket.id, 'DONE');

    // Step 5: Refresh other providers as backup
    ref.read(myTicketsNotifierProvider.notifier).refresh();
  } catch (e) {
    if (context.mounted) {
      context.showFailure(e.toString());
      // Revert optimistic updates on error
      ref
          .read(ticketsPagedProvider(specForTab(TicketsTab.today)).notifier)
          .updateTabCountImmediate(delta: 1);

      ref
          .read(ticketsPagedProvider(specForTab(TicketsTab.done)).notifier)
          .updateTabCountImmediate(delta: -1);
    }
  }
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
          Icons.error_outline_rounded,
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
