import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/services/sound_manager.dart';
import '../../../../core/theme/unified_theme_manager.dart';
import '../../../../core/theme/typography_manager.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/needs_attention_item.dart';

/// "Needs attention" block using API data. Displays items from
/// dashboard/needs_attention endpoint, or shimmer while loading.
class NeedsAttentionApiList extends StatelessWidget {
  final List<NeedsAttentionItem> items;
  final bool isLoading;
  final VoidCallback onViewAll;
  final ValueChanged<String> onItemTap;
  final bool showHeader;

  const NeedsAttentionApiList({
    super.key,
    required this.items,
    required this.isLoading,
    required this.onViewAll,
    required this.onItemTap,
    this.showHeader = true,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final c = context.themeColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showHeader)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                s.dashboardNeedsAttention,
                style: TypographyManager.textHeading.copyWith(color: c.fgBase),
              ),
              if (!isLoading && items.isNotEmpty)
                _ViewAllButton(label: s.dashboardViewAll, onTap: onViewAll),
            ],
          ),
        // Needs attention list content
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: isLoading
              ? const _NeedsAttentionShimmer()
              : items.isEmpty
              ? const _AllClearEmpty()
              : Column(
                  children: [
                    for (var i = 0; i < items.length; i++) ...[
                      if (i > 0) const SizedBox(height: 8),
                      _AttentionRow(
                        item: items[i],
                        onTap: () => onItemTap(items[i].id),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _ViewAllButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ViewAllButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Text(
          label,
          style: TypographyManager.textCaption.copyWith(color: c.tagPurpleIcon),
        ),
      ),
    );
  }
}

class _AllClearEmpty extends StatelessWidget {
  const _AllClearEmpty();

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final c = context.themeColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: c.tagGreenBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.checkCheck,
              color: c.tagGreenIcon,
              size: 22,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            s.dashboardAllClearTitle,
            style: TypographyManager.textBodyStrong.copyWith(color: c.fgBase),
          ),
          const SizedBox(height: 4),
          Text(
            s.dashboardAllClearBody,
            textAlign: TextAlign.center,
            style: TypographyManager.textBody.copyWith(color: c.fgMuted),
          ),
          const SizedBox(height: 4),
          Text(
            s.dashboardAllClearHint,
            textAlign: TextAlign.center,
            style: TypographyManager.textMicro.copyWith(color: c.fgSubtle),
          ),
        ],
      ),
    );
  }
}

class _AttentionRow extends StatelessWidget {
  final NeedsAttentionItem item;
  final VoidCallback onTap;

  const _AttentionRow({required this.item, required this.onTap});

  ({Color iconBg, Color iconFg, Color pillBg, Color pillFg, IconData glyph})
  _palette(AppColors c) {
    switch (item.status) {
      case 'ACCEPTED':
        return (
          iconBg: c.tagBlueBg,
          iconFg: c.tagBlueIcon,
          pillBg: c.tagBlueBg,
          pillFg: c.tagBlueText,
          glyph: LucideIcons.circlePause,
        );
      case 'NEW':
        return (
          iconBg: c.tagNeutralBg,
          iconFg: c.tagNeutralIcon,
          pillBg: c.tagNeutralBg,
          pillFg: c.tagNeutralText,
          glyph: LucideIcons.circlePlay,
        );
      default:
        return (
          iconBg: c.tagOrangeBg,
          iconFg: c.tagOrangeIcon,
          pillBg: c.tagOrangeBg,
          pillFg: c.tagOrangeText,
          glyph: LucideIcons.clock,
        );
    }
  }

  String _pillLabel(AppLocalizations s) {
    switch (item.status) {
      case 'ACCEPTED':
        return s.dashboardNotStartedPill;
      case 'NEW':
        return 'Waiting ${AppDateUtils.timeAgo(item.createdAt)}';
      default:
        return item.status;
    }
  }

  String _roomLabel() {
    return 'Room No: ${item.onbRoomNumber}';
  }

  String _departmentLabel() {
    return item.department.name;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final c = context.themeColors;
    final p = _palette(c);
    final radius = BorderRadius.circular(12);
    return Material(
      color: c.bgBase,
      borderRadius: radius,
      child: InkWell(
        onTap: () async {
          await SoundManager.instance.play(SoundCategory.card);
          onTap();
        },
        borderRadius: radius,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: c.borderBase, width: 1),
            boxShadow: [
              BoxShadow(
                color: c.borderBase.withValues(alpha: 0.04),
                offset: const Offset(0, 1),
                blurRadius: 2,
              ),
              BoxShadow(
                color: c.borderBase.withValues(alpha: 0.04),
                offset: const Offset(0, 0),
                blurRadius: 1,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: p.iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(p.glyph, color: p.iconFg, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.guestName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TypographyManager.textBodyStrong.copyWith(
                          color: c.fgBase,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _roomLabel(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TypographyManager.textMeta.copyWith(
                          color: c.fgMuted,
                        ),
                      ),
                      Text(
                        _departmentLabel(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TypographyManager.textMeta.copyWith(
                          color: c.fgMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _SeverityPill(label: _pillLabel(s), bg: p.pillBg, fg: p.pillFg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SeverityPill extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;

  const _SeverityPill({
    required this.label,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TypographyManager.textCaption.copyWith(color: fg),
      ),
    );
  }
}

class _NeedsAttentionShimmer extends StatelessWidget {
  const _NeedsAttentionShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _ShimmerRow(),
        ],
      ],
    );
  }
}

class _ShimmerRow extends StatelessWidget {
  const _ShimmerRow();

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: c.bgBase,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.borderBase, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: c.borderBase.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 16,
                    width: 120,
                    decoration: BoxDecoration(
                      color: c.borderBase.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 12,
                    width: 80,
                    decoration: BoxDecoration(
                      color: c.borderBase.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 50,
              height: 24,
              decoration: BoxDecoration(
                color: c.borderBase.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
