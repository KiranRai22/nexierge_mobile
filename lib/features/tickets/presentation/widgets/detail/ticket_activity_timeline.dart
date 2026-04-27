import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/i18n/l10n_extension.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/typography_manager.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../../../activity/domain/models/activity_event.dart';
import '../../providers/repository_providers.dart';

/// Activity timeline for a single ticket. Subscribes to the activity feed
/// and renders only the events whose `ticketId` matches the given id.
///
/// Visual:
///   ●─┐  Title           [pill]
///     │  timestamp
///     ●  Title           [pill]
///        timestamp
class TicketActivityTimeline extends ConsumerWidget {
  final String ticketId;
  const TicketActivityTimeline({super.key, required this.ticketId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(activityRepositoryProvider);
    return StreamBuilder<List<ActivityEvent>>(
      stream: repo.watchEvents(),
      initialData: repo.eventsSnapshot(),
      builder: (context, snapshot) {
        final all = snapshot.data ?? const <ActivityEvent>[];
        final events = all.where((e) => e.ticketId == ticketId).toList()
          ..sort((a, b) => b.at.compareTo(a.at));
        if (events.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < events.length; i++)
              _TimelineRow(event: events[i], isLast: i == events.length - 1),
          ],
        );
      },
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final ActivityEvent event;
  final bool isLast;
  const _TimelineRow({required this.event, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final s = context.l10n;
    final visual = _resolve(c, s, event.type);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: visual.iconBg,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(visual.icon, size: 14, color: visual.iconFg),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    color: c.borderBase,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          visual.title,
                          style: TypographyManager.textBodyStrong.copyWith(
                            color: c.fgBase,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: visual.pillBg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          visual.pillLabel,
                          style: TypographyManager.textMicro.copyWith(
                            color: visual.pillFg,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDateTime(event.at),
                    style: TypographyManager.textMeta.copyWith(
                      color: c.fgMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  ({
    Color iconBg,
    Color iconFg,
    IconData icon,
    String title,
    String pillLabel,
    Color pillBg,
    Color pillFg,
  })
  _resolve(AppColors c, AppLocalizations s, ActivityType type) {
    switch (type) {
      case ActivityType.created:
        return (
          iconBg: c.tagBlueBg,
          iconFg: c.tagBlueText,
          icon: LucideIcons.circlePlus,
          title: s.ticketActivityCreated,
          pillLabel: s.ticketActivityBadgeCreated,
          pillBg: c.tagNeutralBg,
          pillFg: c.tagNeutralText,
        );
      case ActivityType.accepted:
        return (
          iconBg: c.tagGreenBg,
          iconFg: c.tagGreenText,
          icon: LucideIcons.circleCheck,
          title: s.ticketActivityStatusChange(s.statusNew, s.statusAccepted),
          pillLabel: s.ticketActivityBadgeAcknowledged,
          pillBg: c.tagGreenBg,
          pillFg: c.tagGreenText,
        );
      case ActivityType.done:
        return (
          iconBg: c.tagGreenBg,
          iconFg: c.tagGreenText,
          icon: LucideIcons.circleCheck,
          title: s.ticketActivityStatusChange(s.statusInProgress, s.statusDone),
          pillLabel: s.ticketActivityBadgeDone,
          pillBg: c.tagGreenBg,
          pillFg: c.tagGreenText,
        );
      case ActivityType.cancelled:
        return (
          iconBg: c.tagRedBg,
          iconFg: c.tagRedText,
          icon: LucideIcons.circleX,
          title: s.ticketActivityStatusChange(
            s.statusInProgress,
            s.statusCancelled,
          ),
          pillLabel: s.ticketActivityBadgeCancelled,
          pillBg: c.tagRedBg,
          pillFg: c.tagRedText,
        );
      case ActivityType.overdue:
        return (
          iconBg: c.tagRedBg,
          iconFg: c.tagRedText,
          icon: LucideIcons.triangleAlert,
          title: s.activityOverdueTitle,
          pillLabel: s.ticketActivityBadgeOverdue,
          pillBg: c.tagRedBg,
          pillFg: c.tagRedText,
        );
      case ActivityType.note:
        return (
          iconBg: c.tagAmberBg,
          iconFg: c.tagAmberText,
          icon: LucideIcons.notebookPen,
          title: s.ticketActivityBadgeNote,
          pillLabel: s.ticketActivityBadgeNote,
          pillBg: c.tagAmberBg,
          pillFg: c.tagAmberText,
        );
      case ActivityType.reassigned:
        return (
          iconBg: c.tagPurpleBg,
          iconFg: c.tagPurpleText,
          icon: LucideIcons.repeat,
          title: s.ticketActivityBadgeReassigned,
          pillLabel: s.ticketActivityBadgeReassigned,
          pillBg: c.tagPurpleBg,
          pillFg: c.tagPurpleText,
        );
    }
  }

  /// Formats `Apr 26, 2026, 2:35 PM` — locale-friendly enough without
  /// pulling in the full `intl` package wiring (already in pubspec; using
  /// it here would require passing the active locale around).
  String _formatDateTime(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour24 = dt.hour;
    final isPm = hour24 >= 12;
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = isPm ? 'PM' : 'AM';
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}, $hour12:$minute $ampm';
  }
}
