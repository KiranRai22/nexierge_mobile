import 'package:flutter/material.dart';
import 'package:nexierge/core/utils/string_utils.dart';
// import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/services/sound_manager.dart';
import '../../../../core/theme/card_theme.dart';
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
    final s = context.l10n;
    return Row(
      children: [
        Expanded(
          child: _CompactStatCard(
            // icon: LucideIcons.bell,
            label: s.dashboardNeedsAcknowledgment,
            count: incoming,
            color: c.tagNeutralIcon,
            onTap: onTapIncoming,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _CompactStatCard(
            // icon: LucideIcons.play,
            label: s.dashboardInProgressLabel,
            count: inProgress,
            color: c.tagPurpleIcon,
            onTap: onTapInProgress,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _CompactStatCard(
            // icon: LucideIcons.triangleAlert,
            label: s.dashboardOverdueLabel,
            count: overdue,
            color: overdue > 0 ? c.tagRedIcon : c.tagOrangeIcon,
            onTap: onTapOverdue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _CompactStatCard(
            // icon: LucideIcons.clock,
            label: s.dashboardNotStartedLabel,
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
  // final IconData icon;
  final String label;
  final int count;
  final Color color;
  final VoidCallback onTap;

  const _CompactStatCard({
    // required this.icon,
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
              // Icon(icon, size: 20, color: color),
              // const SizedBox(height: 4),
              Text(
                StringUtils.capitalizeWords(label),
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
