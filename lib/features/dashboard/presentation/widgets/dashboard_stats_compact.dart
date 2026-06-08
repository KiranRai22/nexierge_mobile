import 'package:flutter/material.dart';
// import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/services/sound_manager.dart';
import '../../../../core/theme/card_theme.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/typography_manager.dart';

/// Compact KPI cards for scroll-responsive dashboard.
/// Single row layout: INCOMING | IN PROGRESS | OVERDUE | DONE
/// This enables smooth transition from the full 2x2 grid on scroll.
class DashboardStatsCompact extends StatelessWidget {
  final int incoming;
  final int inProgress;
  final int overdue;
  final int done;

  final VoidCallback onTapIncoming;
  final VoidCallback onTapInProgress;
  final VoidCallback onTapOverdue;
  final VoidCallback onTapDone;

  const DashboardStatsCompact({
    super.key,
    required this.incoming,
    required this.inProgress,
    required this.overdue,
    required this.done,
    required this.onTapIncoming,
    required this.onTapInProgress,
    required this.onTapOverdue,
    required this.onTapDone,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    return Row(
      children: [
        // INCOMING
        Expanded(
          child: _CompactStatCard(
            label: 'INCOMING',
            count: incoming,
            color: c.tagNeutralIcon,
            onTap: onTapIncoming,
          ),
        ),
        const SizedBox(width: 8),
        // IN PROGRESS
        Expanded(
          child: _CompactStatCard(
            label: 'IN PROGRESS',
            count: inProgress,
            color: c.tagPurpleIcon,
            onTap: onTapInProgress,
          ),
        ),
        const SizedBox(width: 8),
        // OVERDUE
        Expanded(
          child: _CompactStatCard(
            label: 'OVERDUE',
            count: overdue,
            color: overdue > 0 ? c.tagRedIcon : c.tagOrangeIcon,
            onTap: onTapOverdue,
          ),
        ),
        const SizedBox(width: 8),
        // DONE
        Expanded(
          child: _CompactStatCard(
            label: 'DONE',
            count: done,
            color: c.tagGreenIcon,
            onTap: onTapDone,
          ),
        ),
      ],
    );
  }
}

class _CompactStatCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final VoidCallback onTap;

  const _CompactStatCard({
    required this.label,
    required this.count,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    return Material(
      color: c.bgBase,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () async {
          await SoundManager.instance.play(SoundCategory.card);
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: CardDecoration.raised(
            colors: c,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Column(
            children: [
              Text(
                label,
                style: TypographyManager.textCaption.copyWith(
                  color: c.fgMuted,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '$count',
                style: TypographyManager.textTitle.copyWith(
                  color: c.fgBase,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
