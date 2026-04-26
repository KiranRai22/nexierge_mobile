import 'package:flutter/material.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/theme/typography_manager.dart';
import '../providers/dashboard_view.dart';

/// 3-card stats grid: a wide *Incoming Now* card on top, then a row of
/// *In Progress* and *Overdue* cards.
class DashboardStatsGrid extends StatelessWidget {
  final int incoming;
  final int inProgress;
  final int overdue;
  final IncomingBreakdown breakdown;
  final VoidCallback onTapAll;

  const DashboardStatsGrid({
    super.key,
    required this.incoming,
    required this.inProgress,
    required this.overdue,
    required this.breakdown,
    required this.onTapAll,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final breakdownText = <String>[
      if (breakdown.universal > 0)
        s.dashboardBreakdownUniversal(breakdown.universal),
      if (breakdown.catalog > 0) s.dashboardBreakdownCatalog(breakdown.catalog),
      if (breakdown.manual > 0) s.dashboardBreakdownManual(breakdown.manual),
    ].join(' · ');

    return Column(
      children: [
        _IncomingCard(
          count: incoming,
          breakdown: breakdownText,
          onTap: onTapAll,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _SmallStatCard(
                count: inProgress,
                label: s.dashboardInProgressLabel,
                onTap: onTapAll,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _OverdueCard(
                count: overdue,
                label: s.dashboardOverdueLabel,
                onTap: onTapAll,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CardSurface extends StatelessWidget {
  final Color background;
  final EdgeInsetsGeometry padding;
  final Widget child;
  final VoidCallback? onTap;
  final String? semanticsLabel;

  const _CardSurface({
    required this.background,
    required this.padding,
    required this.child,
    this.onTap,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ColorPalette.opsBorder, width: 1),
          ),
          padding: padding,
          child: Semantics(
            label: semanticsLabel,
            button: onTap != null,
            child: child,
          ),
        ),
      ),
    );
  }
}

class _IncomingCard extends StatelessWidget {
  final int count;
  final String breakdown;
  final VoidCallback onTap;

  const _IncomingCard({
    required this.count,
    required this.breakdown,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    return _CardSurface(
      background: ColorPalette.opsSurface,
      padding: const EdgeInsets.all(18),
      onTap: onTap,
      semanticsLabel: '${s.dashboardIncomingNow} $count',
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.dashboardIncomingNow.toUpperCase(),
                style: TypographyManager.kpiLabel.copyWith(
                  color: ColorPalette.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text('$count', style: TypographyManager.kpiHeroCount),
              if (breakdown.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  breakdown,
                  style: TypographyManager.bodyMedium.copyWith(
                    color: ColorPalette.textSecondary,
                  ),
                ),
              ],
            ],
          ),
          Positioned(
            top: 2,
            right: 0,
            child: Icon(
              Icons.chevron_right,
              size: 20,
              color: ColorPalette.textDisabled,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallStatCard extends StatelessWidget {
  final int count;
  final String label;
  final VoidCallback onTap;

  const _SmallStatCard({
    required this.count,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _CardSurface(
      background: ColorPalette.opsSurface,
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      semanticsLabel: '$label $count',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$count',
            style: TypographyManager.headlineMedium.copyWith(
              color: ColorPalette.textPrimary,
              fontWeight: FontWeight.w600,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: TypographyManager.kpiLabel.copyWith(
              color: ColorPalette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

enum _OverdueVariant { zero, warning, danger }

class _OverdueCard extends StatelessWidget {
  final int count;
  final String label;
  final VoidCallback onTap;

  const _OverdueCard({
    required this.count,
    required this.label,
    required this.onTap,
  });

  _OverdueVariant get _variant {
    if (count == 0) return _OverdueVariant.zero;
    if (count >= 3) return _OverdueVariant.danger;
    return _OverdueVariant.warning;
  }

  @override
  Widget build(BuildContext context) {
    final v = _variant;
    final bg = switch (v) {
      _OverdueVariant.danger => ColorPalette.kpiOverdueTint,
      _OverdueVariant.warning => ColorPalette.chipManualBg,
      _OverdueVariant.zero => ColorPalette.opsSurface,
    };
    final fg = switch (v) {
      _OverdueVariant.danger => ColorPalette.kpiOverdueText,
      _OverdueVariant.warning => ColorPalette.chipManualFg,
      _OverdueVariant.zero => ColorPalette.textDisabled,
    };
    final labelColor = switch (v) {
      _OverdueVariant.danger => ColorPalette.kpiOverdueText,
      _OverdueVariant.warning => ColorPalette.chipManualFg,
      _OverdueVariant.zero => ColorPalette.textSecondary,
    };
    return _CardSurface(
      background: bg,
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      semanticsLabel: '$label $count',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$count',
            style: TypographyManager.headlineMedium.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: TypographyManager.kpiLabel.copyWith(color: labelColor),
          ),
        ],
      ),
    );
  }
}
