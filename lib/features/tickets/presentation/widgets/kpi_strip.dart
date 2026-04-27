import 'package:flutter/material.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/theme/typography_manager.dart';

/// Three-up KPI strip: Incoming · In Progress · Overdue.
/// Numbers reflect the full snapshot, not the filtered sub-tab.
class KpiStrip extends StatelessWidget {
  final int incoming;
  final int inProgress;
  final int overdue;

  const KpiStrip({
    super.key,
    required this.incoming,
    required this.inProgress,
    required this.overdue,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    return Row(
      children: [
        Expanded(
          child: _KpiCard(
            label: s.kpiIncoming,
            count: incoming,
            background: ColorPalette.kpiNeutralTint,
            countColor: ColorPalette.textPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _KpiCard(
            label: s.kpiInProgress,
            count: inProgress,
            background: ColorPalette.kpiNeutralTint,
            countColor: ColorPalette.textPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _KpiCard(
            label: s.kpiOverdue,
            count: overdue,
            background: ColorPalette.kpiOverdueTint,
            countColor: ColorPalette.kpiOverdueText,
          ),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final int count;
  final Color background;
  final Color countColor;

  const _KpiCard({
    required this.label,
    required this.count,
    required this.background,
    required this.countColor,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label $count',
      container: true,
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$count',
              style: TypographyManager.kpiCount.copyWith(color: countColor),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TypographyManager.kpiLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
