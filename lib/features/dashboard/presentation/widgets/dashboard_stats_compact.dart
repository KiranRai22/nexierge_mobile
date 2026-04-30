import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/services/sound_manager.dart';
import '../../../../core/theme/unified_theme_manager.dart';
import '../../../../core/theme/typography_manager.dart';

/// Compact KPI cards row for scroll-responsive dashboard.
/// Shows only icon and count in a single row with 25% width each.
class DashboardStatsCompact extends StatelessWidget {
  final int incoming;
  final int accepted;
  final int inProgress;
  final int overdue;

  final VoidCallback onTapIncoming;
  final VoidCallback onTapInProgress;
  final VoidCallback onTapOverdue;
  final VoidCallback onTapAccepted;

  const DashboardStatsCompact({
    super.key,
    required this.incoming,
    required this.accepted,
    required this.inProgress,
    required this.overdue,
    required this.onTapIncoming,
    required this.onTapInProgress,
    required this.onTapOverdue,
    required this.onTapAccepted,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    return Row(
      children: [
        Expanded(
          child: _CompactStatCard(
            icon: LucideIcons.bell,
            count: incoming,
            color: c.tagNeutralIcon,
            onTap: onTapIncoming,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _CompactStatCard(
            icon: LucideIcons.play,
            count: inProgress,
            color: c.tagPurpleIcon,
            onTap: onTapInProgress,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _CompactStatCard(
            icon: LucideIcons.triangleAlert,
            count: overdue,
            color: overdue > 0 ? c.tagRedIcon : c.tagOrangeIcon,
            onTap: onTapOverdue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _CompactStatCard(
            icon: LucideIcons.clock,
            count: accepted,
            color: c.tagBlueIcon,
            onTap: onTapAccepted,
          ),
        ),
      ],
    );
  }
}

class _CompactStatCard extends StatelessWidget {
  final IconData icon;
  final int count;
  final Color color;
  final VoidCallback onTap;

  const _CompactStatCard({
    required this.icon,
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
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.borderBase, width: 1),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 4),
              Text(
                '$count',
                style: TypographyManager.textBodyStrong.copyWith(
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
