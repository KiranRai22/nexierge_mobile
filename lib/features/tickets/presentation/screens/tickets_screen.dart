import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/i18n/language_picker_sheet.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/theme/theme_mode_controller.dart';
import '../../../../core/theme/typography_manager.dart';
import '../../domain/models/ticket.dart';
import '../providers/session_providers.dart';
import '../providers/tickets_list_controller.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/filter_department_sheet.dart';
import '../widgets/kpi_strip.dart';
import '../widgets/scope_segmented_tabs.dart';
import '../widgets/sub_tab_bar.dart';
import '../widgets/ticket_card.dart';
import 'ticket_detail_screen.dart';

/// Top-level dashboard for the operator. Composes top bar, scope tabs,
/// search, KPI strip, sub-tab bar and the grouped list.
class TicketsScreen extends ConsumerStatefulWidget {
  const TicketsScreen({super.key});

  @override
  ConsumerState<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends ConsumerState<TicketsScreen> {
  late final TextEditingController _searchCtl;

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

  void _showNotificationsHint(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.comingSoonNotifications)),
    );
  }

  Future<void> _refresh() async {
    // No backend yet — wait one frame so the indicator animates out.
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    // Kick the providers so dependents recompute (e.g. ETA strings).
    ref.invalidate(ticketsListProvider);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(operatorSessionProvider);
    final scope = ref.watch(ticketScopeProvider);
    final subTab = ref.watch(ticketsSubTabProvider);
    final filter = ref.watch(departmentFilterProvider);
    final asyncList = ref.watch(ticketsListProvider);

    return Container(
      color: ColorPalette.opsSurface,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AppTopBar(
                avatarInitials: session.displayName.isEmpty
                    ? '?'
                    : session.displayName[0].toUpperCase(),
                hasUnreadNotifications: true,
                onThemeToggle: () => ref
                    .read(themeModeControllerProvider.notifier)
                    .toggle(),
                onLanguageTap: () => LanguagePickerSheet.show(context),
                onNotifications: () => _showNotificationsHint(context),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: _Greeting(name: session.displayName),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: ScopeSegmentedTabs(
                scope: scope,
                hasActiveFilter: filter.isNotEmpty,
                onScopeChanged: (s) =>
                    ref.read(ticketScopeProvider.notifier).state = s,
                onFilterTap: () => FilterDepartmentSheet.show(context),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: _SearchField(controller: _searchCtl),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: asyncList.when(
                data: (v) => KpiStrip(
                  incoming: v.kpiIncoming,
                  inProgress: v.kpiInProgress,
                  overdue: v.kpiOverdue,
                ),
                loading: () => const KpiStrip(
                  incoming: 0,
                  inProgress: 0,
                  overdue: 0,
                ),
                error: (_, __) => const KpiStrip(
                  incoming: 0,
                  inProgress: 0,
                  overdue: 0,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SubTabBar(
                selected: subTab,
                onChanged: (t) =>
                    ref.read(ticketsSubTabProvider.notifier).state = t,
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                color: ColorPalette.opsPurple,
                child: asyncList.when(
                  data: (v) => _TicketsList(view: v),
                  loading: () => const _LoadingList(),
                  error: (e, st) => _ErrorView(error: e.toString()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  final String name;
  const _Greeting({required this.name});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        context.l10n.greeting(name),
        style: TypographyManager.headlineSmall.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 22,
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
    return TextField(
      controller: controller,
      style: TypographyManager.bodyMedium,
      onChanged: (v) =>
          ref.read(ticketsSearchQueryProvider.notifier).state = v,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: context.l10n.ticketsSearchHint,
        hintStyle: TypographyManager.bodyMedium.copyWith(
          color: ColorPalette.textSecondary,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: ColorPalette.textSecondary,
        ),
        filled: true,
        fillColor: ColorPalette.opsSurfaceSubtle,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ColorPalette.opsBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ColorPalette.opsBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ColorPalette.opsPurple),
        ),
      ),
    );
  }
}

class _TicketsList extends StatelessWidget {
  final TicketsListView view;
  const _TicketsList({required this.view});

  @override
  Widget build(BuildContext context) {
    if (view.isEmpty) return const _EmptyView();

    final s = context.l10n;
    final sections = <_Section>[
      if (view.incomingNow.isNotEmpty)
        _Section(s.sectionIncomingNow, view.incomingNow),
      if (view.inProgress.isNotEmpty)
        _Section(s.sectionInProgress, view.inProgress),
      if (view.completedToday.isNotEmpty)
        _Section(s.sectionCompletedToday, view.completedToday),
      if (view.scheduled.isNotEmpty)
        _Section(s.sectionScheduled, view.scheduled),
    ];

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
      itemCount: sections.fold<int>(
        0,
        (sum, s) => sum + s.tickets.length + 1,
      ),
      itemBuilder: (context, raw) {
        var i = raw;
        for (final s in sections) {
          if (i == 0) return _SectionHeader(title: s.title, count: s.tickets.length);
          i -= 1;
          if (i < s.tickets.length) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TicketCard(
                ticket: s.tickets[i],
                onTap: () => _openDetail(context, s.tickets[i]),
              ),
            );
          }
          i -= s.tickets.length;
        }
        return const SizedBox.shrink();
      },
    );
  }

  void _openDetail(BuildContext context, Ticket t) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TicketDetailScreen(ticketId: t.id),
      ),
    );
  }
}

class _Section {
  final String title;
  final List<Ticket> tickets;
  const _Section(this.title, this.tickets);
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 12, 2, 8),
      child: Row(
        children: [
          Text(title, style: TypographyManager.sectionOverline),
          const SizedBox(width: 6),
          Text(
            '· $count',
            style: TypographyManager.sectionOverline.copyWith(
              color: ColorPalette.textDisabled,
            ),
          ),
        ],
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
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          height: 92,
          decoration: BoxDecoration(
            color: ColorPalette.opsSurfaceSubtle,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ColorPalette.opsBorder),
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
          color: ColorPalette.textDisabled,
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            context.l10n.emptyState,
            style: TypographyManager.bodyMedium.copyWith(
              color: ColorPalette.textSecondary,
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
        const Icon(
          Icons.error_outline_rounded,
          size: 56,
          color: ColorPalette.statusOverdue,
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
