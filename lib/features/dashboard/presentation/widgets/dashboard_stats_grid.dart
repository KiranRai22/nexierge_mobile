import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/theme/typography_manager.dart';
import '../providers/dashboard_view.dart';

/// 2×2 stat grid that mirrors `Dashboard.tsx`:
///
/// ```
/// ┌────────────────────────────┐
/// │     Needs acknowledgment   │  ← col-span-2, big
/// ├──────────────┬─────────────┤
/// │ In progress  │  Overdue    │
/// ├──────────────┴─────────────┤
/// │       Not started          │  ← col-span-2
/// └────────────────────────────┘
/// ```
class DashboardStatsGrid extends StatelessWidget {
  final int incoming;
  final int accepted;
  final int inProgress;
  final int overdue;
  final IncomingBreakdown breakdown;

  /// Tap routes for each card. The host screen decides where each one goes
  /// — keeps this widget free of navigation concerns.
  final VoidCallback onTapIncoming;
  final VoidCallback onTapInProgress;
  final VoidCallback onTapOverdue;
  final VoidCallback onTapAccepted;

  const DashboardStatsGrid({
    super.key,
    required this.incoming,
    required this.accepted,
    required this.inProgress,
    required this.overdue,
    required this.breakdown,
    required this.onTapIncoming,
    required this.onTapInProgress,
    required this.onTapOverdue,
    required this.onTapAccepted,
  });

  _OverdueVariant get _overdueVariant {
    if (overdue == 0) return _OverdueVariant.zero;
    if (overdue >= 3) return _OverdueVariant.danger;
    return _OverdueVariant.warning;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final breakdownText = <String>[
      if (breakdown.universal > 0)
        s.dashboardBreakdownUniversal(breakdown.universal),
      if (breakdown.catalog > 0) s.dashboardBreakdownCatalog(breakdown.catalog),
      if (breakdown.manual > 0) s.dashboardBreakdownManual(breakdown.manual),
    ].join(' · ');

    final overdueTone = switch (_overdueVariant) {
      _OverdueVariant.danger => StatNoteTone.red,
      _OverdueVariant.warning => StatNoteTone.orange,
      _OverdueVariant.zero => StatNoteTone.neutral,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StatNoteCard(
          tone: StatNoteTone.neutral,
          badgeLabel: s.dashboardNeedsAcknowledgment,
          value: incoming,
          footer: breakdownText.isNotEmpty
              ? breakdownText
              : s.dashboardIncomingFooterEmpty,
          size: StatNoteSize.large,
          trailing: const Icon(
            LucideIcons.chevronRight,
            size: 18,
            color: ColorPalette.textDisabled,
          ),
          onTap: onTapIncoming,
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: StatNoteCard(
                tone: StatNoteTone.purple,
                badgeLabel: s.dashboardInProgressLabel,
                value: inProgress,
                footer: s.dashboardInProgressFooter,
                size: StatNoteSize.medium,
                onTap: onTapInProgress,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatNoteCard(
                tone: overdueTone,
                badgeLabel: s.dashboardOverdueLabel,
                value: overdue,
                footer: s.dashboardOverdueFooter,
                size: StatNoteSize.medium,
                onTap: onTapOverdue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        StatNoteCard(
          tone: accepted > 0 ? StatNoteTone.blue : StatNoteTone.neutral,
          badgeLabel: s.dashboardNotStartedLabel,
          value: accepted,
          footer: s.dashboardNotStartedFooter,
          size: StatNoteSize.medium,
          onTap: onTapAccepted,
        ),
      ],
    );
  }
}

enum _OverdueVariant { zero, warning, danger }

/// Visual tone of a [StatNoteCard]. Each tone resolves to a (background,
/// foreground, accent) triple from [ColorPalette] — no hex literals here so
/// theming stays centralised per `docs/04_BASE_LAYER_RULES.md`.
enum StatNoteTone { neutral, purple, red, orange, blue }

enum StatNoteSize { medium, large }

/// Reusable KPI tile. Mirrors the `StatNoteCard` component from
/// `docs/ai_prompts/Dashboard.tsx`. Shape: ALL-CAPS badge, big number, soft
/// footer line, optional trailing glyph; rounded card surface tinted by tone.
class StatNoteCard extends StatelessWidget {
  final StatNoteTone tone;
  final String badgeLabel;
  final int value;
  final String footer;
  final StatNoteSize size;
  final Widget? trailing;
  final VoidCallback? onTap;

  const StatNoteCard({
    super.key,
    required this.tone,
    required this.badgeLabel,
    required this.value,
    required this.footer,
    this.size = StatNoteSize.medium,
    this.trailing,
    this.onTap,
  });

  _TonePalette _palette() {
    switch (tone) {
      case StatNoteTone.neutral:
        return _TonePalette(
          background: ColorPalette.opsSurface,
          accent: ColorPalette.textSecondary,
          number: ColorPalette.textPrimary,
          footer: ColorPalette.textSecondary,
        );
      case StatNoteTone.purple:
        return _TonePalette(
          background: ColorPalette.opsPurpleSoft,
          accent: ColorPalette.opsPurpleDark,
          number: ColorPalette.opsPurpleDark,
          footer: ColorPalette.opsPurpleDark,
        );
      case StatNoteTone.red:
        return _TonePalette(
          background: ColorPalette.kpiOverdueTint,
          accent: ColorPalette.kpiOverdueText,
          number: ColorPalette.kpiOverdueText,
          footer: ColorPalette.kpiOverdueText,
        );
      case StatNoteTone.orange:
        return _TonePalette(
          background: ColorPalette.chipManualBg,
          accent: ColorPalette.chipManualFg,
          number: ColorPalette.chipManualFg,
          footer: ColorPalette.chipManualFg,
        );
      case StatNoteTone.blue:
        return _TonePalette(
          background: ColorPalette.chipCatalogBg,
          accent: ColorPalette.chipCatalogFg,
          number: ColorPalette.chipCatalogFg,
          footer: ColorPalette.chipCatalogFg,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _palette();
    final isLarge = size == StatNoteSize.large;
    final radius = BorderRadius.circular(16);

    return Material(
      color: ColorPalette.white,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: ColorPalette.opsBorder, width: 1),
          ),
          padding: EdgeInsets.all(isLarge ? 18 : 14),
          child: Semantics(
            label: '$badgeLabel $value',
            button: onTap != null,
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Colored title pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: p.accent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badgeLabel.toUpperCase(),
                        style: TypographyManager.kpiLabel.copyWith(
                          color: ColorPalette.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$value',
                      style: isLarge
                          ? TypographyManager.kpiHeroCount.copyWith(
                              color: p.number,
                            )
                          : TypographyManager.headlineMedium.copyWith(
                              color: p.number,
                              fontWeight: FontWeight.w600,
                              height: 1.15,
                            ),
                    ),
                    Divider(color: p.accent, thickness: .05),
                    Text(
                      footer,
                      style: TypographyManager.bodySmall.copyWith(
                        color: p.footer,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                if (trailing != null)
                  Positioned(top: 2, right: 0, child: trailing!),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TonePalette {
  final Color background;
  final Color accent;
  final Color number;
  final Color footer;

  const _TonePalette({
    required this.background,
    required this.accent,
    required this.number,
    required this.footer,
  });
}
