import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../core/theme/unified_theme_manager.dart';
import '../../../../core/theme/theme_mode_controller.dart';
import '../../../../core/theme/typography_manager.dart';
import '../../../shell/presentation/widgets/app_bottom_nav.dart';
import '../../domain/models/ticket.dart';
import '../../../auth/presentation/providers/user_profile_controller.dart';
import '../providers/my_tickets_list_controller.dart';
import '../providers/my_tickets_notifier.dart';
import '../providers/session_providers.dart';
import '../providers/tickets_list_controller.dart';
import '../providers/tickets_main_tab_provider.dart';
import '../providers/tickets_paged_notifier.dart';
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

class _TicketsScreenNewState extends ConsumerState<TicketsScreenNew> {
  late final TextEditingController _searchCtl;
  bool _isSearchVisible = false;

  @override
  void initState() {
    super.initState();
    _searchCtl = TextEditingController();
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
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
    // Selecting the Today tab triggers a fresh page-1 fetch every time the
    // user lands on it.
    ref.listen<TicketsMainTab>(ticketsMainTabProvider, (prev, next) {
      if (next == TicketsMainTab.today && prev != TicketsMainTab.today) {
        ref
            .read(ticketsPagedProvider(specForTab(TicketsTab.today)).notifier)
            .refresh();
      }
    });
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
                      onTap: () => _showFilterSheet(context),
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

            // Filter chips based on selected main tab
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
              child: TicketsFilterChips(
                selectedTab: mainTab,
                selectedFilter: selectedFilter,
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

  Map<TicketsMainTab, int> _calculateTabCounts() {
    int totalFor(TicketsTab tab) {
      final s = ref.watch(ticketsPagedProvider(specForTab(tab))).valueOrNull;
      // Prefer server's itemsTotal; fall back to currently loaded item
      // count while the first page is in flight.
      return s == null ? 0 : (s.itemsTotal > 0 ? s.itemsTotal : s.items.length);
    }

    return {
      TicketsMainTab.incoming: totalFor(TicketsTab.incoming),
      TicketsMainTab.today: totalFor(TicketsTab.today),
      TicketsMainTab.scheduled: totalFor(TicketsTab.scheduled),
      TicketsMainTab.done: totalFor(TicketsTab.done),
    };
  }

  void _showFilterSheet(BuildContext context) {
    FilterDepartmentSheet.show(context);
  }

  Widget _buildList(TicketsMainTab mainTab) {
    // All four tabs are paginated against `/tickets/get/all`. The list
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
    case TicketsMainTab.scheduled:
      return TicketsTab.scheduled;
    case TicketsMainTab.done:
      return TicketsTab.done;
  }
}

/// Builds an `onAccept` handler matching the existing AcceptSheet contract.
VoidCallback _acceptHandler(BuildContext context, Ticket ticket) {
  return () async {
    await AcknowledgeTicketBottomSheet.show(
      context: context,
      ticketCode: ticket.code,
      ticketTitle: ticket.title,
      hasGuest: ticket.guest != null,
    );
  };
}

VoidCallback _openHandler(BuildContext context, Ticket ticket) {
  return () => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => TicketDetailScreen(ticketId: ticket.id),
    ),
  );
}

Future<void> _startWorkHandler(
  BuildContext context,
  WidgetRef ref,
  Ticket ticket,
) async {
  final etaLabel = () {
    final eta = ticket.eta;
    if (eta == null) return '—';
    final diff = eta.difference(DateTime.now());
    if (diff.isNegative) return '—';
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    return '${diff.inMinutes}m';
  }();

  final confirmed = await showStartWorkConfirmation(
    context: context,
    etaLabel: etaLabel,
  );
  if (confirmed != true || !context.mounted) return;

  try {
    await ref
        .read(ticketRepositoryProvider)
        .updateTicketStatus(ticketId: ticket.id);
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
    await ref
        .read(ticketRepositoryProvider)
        .markDoneWithNote(ticketId: ticket.id, resolutionNote: note);
    ref.read(myTicketsNotifierProvider.notifier).refresh();
  } catch (e) {
    if (context.mounted) context.showFailure(e.toString());
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
    // ignore: unawaited_futures
    ref.read(ticketsPagedProvider(spec).notifier).setSortOrder(order);

    return asyncState.when(
      loading: () => const _LoadingList(),
      error: (e, _) => _ErrorView(error: e.toString()),
      data: (page) {
        if (page.items.isEmpty) return const _EmptyView();
        final tickets = page.items
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
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
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
                  onAccept: _acceptHandler(context, ticket),
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
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
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
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      itemCount: 4,
      itemBuilder: (context, __) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          height: 92,
          decoration: BoxDecoration(
            color: context.themeColors.bgSubtle,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.themeColors.borderBase),
          ),
        ),
      ),
    );
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
