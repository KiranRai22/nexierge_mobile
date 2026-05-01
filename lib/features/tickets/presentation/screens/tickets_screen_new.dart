import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/i18n/l10n_extension.dart';
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
import '../widgets/ticket_card_new.dart';
import '../widgets/tickets_top_bar.dart';
import '../widgets/tickets_main_tabs.dart';
import '../widgets/tickets_filter_chips.dart';
import '../widgets/filter_department_sheet.dart';
import '../widgets/accept_sheet.dart';
import '../../../notifications/presentation/widgets/notifications_sheet.dart';
import 'ticket_detail_screen.dart';

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
    await ref.read(myTicketsNotifierProvider.notifier).refresh();
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
    final asyncList = ref.watch(myTicketsListProvider);
    final userProfile = ref.watch(userProfileProvider);
    final session = ref.watch(operatorSessionProvider);
    final themeMode =
        ref.watch(themeModeControllerProvider).valueOrNull ?? ThemeMode.system;
    final isDarkMode = themeMode == ThemeMode.dark;

    final c = context.themeColors;

    // Calculate counts for each main tab
    final counts = _calculateTabCounts(asyncList);

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

    return Container(
      color: c.bgBase,
      child: SafeArea(
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
                  // Title should always be "All Tickets"
                  Text(
                    context.l10n.navTickets,
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
                child: _buildList(asyncList, mainTab),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<TicketsMainTab, int> _calculateTabCounts(TicketsListView? view) {
    if (view == null) {
      return {for (var tab in TicketsMainTab.values) tab: 0};
    }

    return {
      TicketsMainTab.incoming: view.incomingNow.length,
      TicketsMainTab.today: view.inProgress.length + view.completedToday.length,
      TicketsMainTab.scheduled: view.scheduled.length,
      TicketsMainTab.done: view.completedToday.length,
    };
  }

  void _showFilterSheet(BuildContext context) {
    FilterDepartmentSheet.show(context);
  }

  Widget _buildList(TicketsListView? view, TicketsMainTab mainTab) {
    if (view == null) {
      return const _LoadingList();
    }
    return _TicketsList(view: view, mainTab: mainTab);
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

class _TicketsList extends StatelessWidget {
  final TicketsListView view;
  final TicketsMainTab mainTab;
  const _TicketsList({required this.view, required this.mainTab});

  @override
  Widget build(BuildContext context) {
    final tickets = _getTicketsForMainTab(view, mainTab);

    if (tickets.isEmpty) return const _EmptyView();

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
      itemCount: tickets.length,
      itemBuilder: (context, index) {
        final ticket = tickets[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TicketCardNew(
            ticket: ticket,
            onTap: () => _openDetail(context, ticket),
            onAccept: () => _showAcceptSheet(context, ticket),
          ),
        );
      },
    );
  }

  List<Ticket> _getTicketsForMainTab(
    TicketsListView view,
    TicketsMainTab mainTab,
  ) {
    switch (mainTab) {
      case TicketsMainTab.incoming:
        return view.incomingNow;
      case TicketsMainTab.today:
        return [...view.inProgress, ...view.completedToday];
      case TicketsMainTab.scheduled:
        return view.scheduled;
      case TicketsMainTab.done:
        return view.completedToday;
    }
  }

  void _openDetail(BuildContext context, Ticket t) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TicketDetailScreen(ticketId: t.id),
      ),
    );
  }

  Future<void> _showAcceptSheet(BuildContext context, Ticket ticket) async {
    final result = await AcceptSheet.show(
      context: context,
      ticketCode: ticket.code,
      ticketTitle: ticket.title,
      ticketType: _mapTicketKind(ticket.kind),
      hasGuest: ticket.guest != null,
    );

    if (result != null && context.mounted) {
      // TODO: Call accept ticket API with ETA result
      // result.mode, result.minutesFromNow, result.customTime
    }
  }

  TicketAcceptType _mapTicketKind(TicketKind kind) {
    switch (kind) {
      case TicketKind.universal:
        return TicketAcceptType.universal;
      case TicketKind.catalog:
        return TicketAcceptType.paid;
      case TicketKind.manual:
        return TicketAcceptType.manual;
    }
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
