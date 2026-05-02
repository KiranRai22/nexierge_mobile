import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/i18n/language_picker_sheet.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../core/theme/theme_mode_controller.dart';
import '../../../../core/theme/typography_manager.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../tickets/presentation/providers/session_providers.dart';
import '../../../tickets/presentation/screens/ticket_detail_screen.dart';
import '../../../tickets/presentation/widgets/app_top_bar.dart';
import '../../../tickets/presentation/widgets/filter_department_sheet.dart';
import '../../../tickets/presentation/widgets/scope_segmented_tabs.dart';
import '../../domain/models/activity_event.dart';
import '../providers/activity_controller.dart';
import '../widgets/activity_row.dart';
import '../widgets/activity_type_chip_bar.dart';
import '../widgets/day_section.dart';

/// Activity feed — full-history view with type filter and day grouping.
class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  Future<void> _refresh() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    ref.invalidate(activityFeedProvider);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final asyncFeed = ref.watch(activityFeedProvider);
    final scope = ref.watch(ticketScopeProvider);
    final filter = ref.watch(activityFilterProvider);
    final deptFilter = ref.watch(departmentFilterProvider);
    final session = ref.watch(operatorSessionProvider);

    return Container(
      color: ColorPalette.opsSurface,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AppTopBar(
                avatarInitials: session.displayName.isEmpty
                    ? '?'
                    : session.displayName[0].toUpperCase(),
                hasUnreadNotifications: true,
                onThemeToggle: () =>
                    ref.read(themeModeControllerProvider.notifier).toggle(),
                onLanguageTap: () => LanguagePickerSheet.show(context),
                onNotifications: () =>
                    context.showInfo(s.comingSoonNotifications),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Text(
                s.navActivity,
                style: TypographyManager.headlineSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: ScopeSegmentedTabs(
                scope: scope,
                hasActiveFilter: deptFilter.isNotEmpty,
                onScopeChanged: (s) =>
                    ref.read(ticketScopeProvider.notifier).state = s,
                onFilterTap: () => FilterDepartmentSheet.show(context),
              ),
            ),
            ActivityTypeChipBar(
              selected: filter,
              onChanged: (f) =>
                  ref.read(activityFilterProvider.notifier).state = f,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                color: ColorPalette.opsPurple,
                child: asyncFeed.when(
                  data: (events) => _ActivityList(events: events),
                  loading: () => const _LoadingFeed(),
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

class _ActivityList extends StatelessWidget {
  final List<ActivityEvent> events;
  const _ActivityList({required this.events});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const _EmptyView();

    final s = context.l10n;
    final groups = _groupByDay(events, s.dayToday, s.dayYesterday, s.dayOlder);
    final flat = <_FeedItem>[];
    for (final g in groups) {
      flat.add(_FeedItem.section(g.label));
      for (final e in g.events) {
        flat.add(_FeedItem.event(e));
      }
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.only(bottom: 120),
      itemCount: flat.length,
      itemBuilder: (context, i) {
        final item = flat[i];
        if (item.isSection) {
          return DaySection(label: item.sectionLabel!);
        }
        return ActivityRow(
          event: item.event!,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  TicketDetailScreen(ticketId: item.event!.ticketId),
            ),
          ),
        );
      },
    );
  }

  List<_DayGroup> _groupByDay(
    List<ActivityEvent> events,
    String todayLabel,
    String yesterdayLabel,
    String olderLabel,
  ) {
    final today = <ActivityEvent>[];
    final yesterday = <ActivityEvent>[];
    final older = <ActivityEvent>[];
    for (final e in events) {
      switch (AppDateUtils.bucket(e.at)) {
        case DayBucket.today:
          today.add(e);
        case DayBucket.yesterday:
          yesterday.add(e);
        case DayBucket.older:
          older.add(e);
      }
    }
    return [
      if (today.isNotEmpty) _DayGroup(todayLabel, today),
      if (yesterday.isNotEmpty) _DayGroup(yesterdayLabel, yesterday),
      if (older.isNotEmpty) _DayGroup(olderLabel, older),
    ];
  }
}

class _DayGroup {
  final String label;
  final List<ActivityEvent> events;
  const _DayGroup(this.label, this.events);
}

class _FeedItem {
  final String? sectionLabel;
  final ActivityEvent? event;
  const _FeedItem._(this.sectionLabel, this.event);
  factory _FeedItem.section(String label) => _FeedItem._(label, null);
  factory _FeedItem.event(ActivityEvent e) => _FeedItem._(null, e);
  bool get isSection => sectionLabel != null;
}

class _LoadingFeed extends StatelessWidget {
  const _LoadingFeed();
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 5,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: ColorPalette.opsSurfaceSubtle,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 14,
                decoration: BoxDecoration(
                  color: ColorPalette.opsSurfaceSubtle,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
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
        const Icon(
          Icons.timeline_outlined,
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
