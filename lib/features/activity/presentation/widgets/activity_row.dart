import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/typography_manager.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/models/activity_event.dart';

/// One row in the activity feed: tinted icon + title line + meta line.
class ActivityRow extends StatelessWidget {
  final ActivityEvent event;
  final VoidCallback? onTap;
  const ActivityRow({super.key, required this.event, this.onTap});

  @override
  Widget build(BuildContext context) {
    final spec = _resolve(context.appColors, event.type);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IconBadge(icon: spec.icon, bg: spec.bg, fg: spec.fg),
              const SizedBox(width: 12),
              Expanded(child: _TextBlock(event: event)),
              const SizedBox(width: 8),
              Text(
                AppDateUtils.relative(event.at),
                style: TypographyManager.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static ({IconData icon, Color bg, Color fg}) _resolve(AppColors c, ActivityType t) {
    switch (t) {
      case ActivityType.created:
        return (
          icon: LucideIcons.circlePlus,
          bg: c.tagNeutralBg,
          fg: c.tagNeutralText,
        );
      case ActivityType.accepted:
        return (
          icon: LucideIcons.circleCheck,
          bg: c.brandPrimaryTint,
          fg: c.brandPrimaryHover,
        );
      case ActivityType.done:
        return (
          icon: LucideIcons.circleCheckBig,
          bg: c.tagGreenBg,
          fg: c.tagGreenText,
        );
      case ActivityType.overdue:
        return (
          icon: LucideIcons.circleAlert,
          bg: c.tagRedBg,
          fg: c.fgDanger,
        );
      case ActivityType.cancelled:
        return (
          icon: LucideIcons.circleX,
          bg: c.tagNeutralBg,
          fg: c.fgMuted,
        );
      case ActivityType.note:
        return (
          icon: LucideIcons.stickyNote,
          bg: c.tagAmberBg,
          fg: c.tagAmberText,
        );
      case ActivityType.reassigned:
        return (
          icon: LucideIcons.arrowLeftRight,
          bg: c.tagBlueBg,
          fg: c.tagBlueText,
        );
    }
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Color bg;
  final Color fg;
  const _IconBadge({required this.icon, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Icon(icon, size: 18, color: fg),
    );
  }
}

class _TextBlock extends StatelessWidget {
  final ActivityEvent event;
  const _TextBlock({required this.event});

  String _title(AppLocalizations s) {
    switch (event.type) {
      case ActivityType.created:
        return s.activityCreatedTitle;
      case ActivityType.accepted:
        return s.activityAcceptedTitle(event.actorName ?? '');
      case ActivityType.done:
        return s.activityDoneTitle(event.actorName ?? '');
      case ActivityType.overdue:
        return s.activityOverdueTitle;
      case ActivityType.cancelled:
        return s.activityCancelledTitle(event.actorName ?? '');
      case ActivityType.note:
        return s.activityNoteTitle(event.actorName ?? '');
      case ActivityType.reassigned:
        final target = event.targetDepartment?.label(s) ?? '';
        return s.activityReassignedTitle(event.actorName ?? '', target);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _title(s),
          style: TypographyManager.titleSmall.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          '${event.ticketCode}  ·  ${event.ticketTitle}'
          '  ·  ${s.roomNumber(event.roomNumber)}',
          style: TypographyManager.bodySmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
