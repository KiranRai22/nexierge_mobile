import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/services/sound_manager.dart';
import '../../../../core/theme/card_theme.dart';
import '../../../../core/theme/unified_theme_manager.dart';
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
    final c = context.themeColors;
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
          trailing: Icon(
            LucideIcons.chevronRight,
            size: 18,
            color: c.fgDisabled,
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
/// foreground, accent) triple from the active theme — see [_palette].
/// Brand purple is intentionally static (legacy `ColorPalette.opsPurple*`)
/// because brand colour stays consistent across light/dark.
enum StatNoteTone { neutral, purple, red, orange, blue }

enum StatNoteSize { medium, large }

/// Reusable KPI tile. Mirrors the `StatNoteCard` component from
/// `docs/ai_prompts/Dashboard.tsx`. Shape: ALL-CAPS badge in a tinted pill,
/// big number, soft footer line, optional trailing glyph.
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

  _TonePalette _palette(AppColors c) {
    switch (tone) {
      case StatNoteTone.neutral:
        return _TonePalette(
          accent: c.tagNeutralIcon,
          number: c.fgBase,
          footer: c.fgMuted,
        );
      case StatNoteTone.purple:
        // Brand purple — matches React tag-purple colors
        return _TonePalette(
          accent: c.tagPurpleIcon,
          number: c.tagPurpleText,
          footer: c.tagPurpleIcon,
        );
      case StatNoteTone.red:
        return _TonePalette(
          accent: c.tagRedIcon,
          number: c.tagRedText,
          footer: c.tagRedIcon,
        );
      case StatNoteTone.orange:
        return _TonePalette(
          accent: c.tagOrangeIcon,
          number: c.tagOrangeText,
          footer: c.tagOrangeIcon,
        );
      case StatNoteTone.blue:
        return _TonePalette(
          accent: c.tagBlueIcon,
          number: c.tagBlueText,
          footer: c.tagBlueIcon,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    final p = _palette(c);
    final isLarge = size == StatNoteSize.large;
    final radius = BorderRadius.circular(16);

    return Material(
      color: c.bgBase,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap == null
            ? null
            : () async {
                await SoundManager.instance.play(SoundCategory.card);
                onTap?.call();
              },
        borderRadius: radius,
        child: Container(
          decoration: CardDecoration.standard(colors: c, borderRadius: radius),
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
                    // Tinted badge pill — matches React bg-[rgb(var(--tag-*-bg))]
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: p.accent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badgeLabel.toUpperCase(),
                        style: TypographyManager.textCaption.copyWith(
                          color: c.fgBase,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$value',
                      style: isLarge
                          ? TypographyManager.headlineLarge.copyWith(
                              color: p.number,
                              fontWeight: FontWeight.w700,
                            )
                          : TypographyManager.headlineMedium.copyWith(
                              color: p.number,
                              fontWeight: FontWeight.w600,
                            ),
                    ),
                    // Dotted divider — matches React reference
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: SizedBox(
                        width: double.infinity,
                        height: 1,
                        child: CustomPaint(
                          painter: _DottedLinePainter(
                            color: c.fgMuted.withValues(alpha: 0.5),
                            dashWidth: 2.0,
                            gap: 3.0,
                          ),
                        ),
                      ),
                    ),
                    Text(
                      footer,
                      style: TypographyManager.textMeta.copyWith(
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
  final Color accent;
  final Color number;
  final Color footer;

  const _TonePalette({
    required this.accent,
    required this.number,
    required this.footer,
  });
}

class _DottedLinePainter extends CustomPainter {
  final Color color;
  final double dashWidth;
  final double gap;

  _DottedLinePainter({
    required this.color,
    required this.dashWidth,
    required this.gap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final y = size.height / 2;
    double x = 0;
    final total = size.width;
    while (x < total) {
      final candidate = x + dashWidth;
      final end = candidate > total ? total : candidate;
      canvas.drawLine(Offset(x, y), Offset(end, y), paint);
      x += dashWidth + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
