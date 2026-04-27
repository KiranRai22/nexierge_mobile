import 'package:flutter/material.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/theme/typography_manager.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../tickets/domain/models/department.dart';
import '../providers/dashboard_view.dart';

/// "Needs attention" block: list of high-priority tickets, or an
/// "All caught up" empty state when nothing is urgent.
class NeedsAttentionList extends StatelessWidget {
  final List<AttentionItem> items;
  final Department? deptHint;
  final void Function(AttentionItem item) onItemTap;
  final VoidCallback onViewAll;

  const NeedsAttentionList({
    super.key,
    required this.items,
    required this.onItemTap,
    required this.onViewAll,
    this.deptHint,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                s.dashboardNeedsAttention,
                style: TypographyManager.titleMedium.copyWith(
                  color: ColorPalette.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (items.isNotEmpty)
                _ViewAllButton(label: s.dashboardViewAll, onTap: onViewAll),
            ],
          ),
        ),
        if (items.isEmpty)
          _AllCaughtUpEmpty(deptHint: deptHint)
        else
          Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                _AttentionRow(
                  item: items[i],
                  onTap: () => onItemTap(items[i]),
                ),
              ],
            ],
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Text(
          label,
          style: TypographyManager.labelLarge.copyWith(
            color: ColorPalette.opsPurple,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _AllCaughtUpEmpty extends StatelessWidget {
  final Department? deptHint;
  const _AllCaughtUpEmpty({this.deptHint});

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final body = deptHint == null
        ? s.dashboardAllCaughtUpGeneric
        : s.dashboardAllCaughtUpDept(deptHint!.label(s));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: ColorPalette.activityDoneBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.done_all_rounded,
              color: ColorPalette.activityDoneFg,
              size: 22,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            s.dashboardAllCaughtUp,
            style: TypographyManager.titleSmall.copyWith(
              color: ColorPalette.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            textAlign: TextAlign.center,
            style: TypographyManager.bodyMedium.copyWith(
              color: ColorPalette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttentionRow extends StatelessWidget {
  final AttentionItem item;
  final VoidCallback onTap;

  const _AttentionRow({required this.item, required this.onTap});

  ({Color iconBg, Color iconFg, Color pillBg, Color pillFg}) _palette() {
    switch (item.severity) {
      case AttentionSeverity.overdue:
        return (
          iconBg: ColorPalette.activityOverdueBg,
          iconFg: ColorPalette.activityOverdueFg,
          pillBg: ColorPalette.activityOverdueBg,
          pillFg: ColorPalette.activityOverdueFg,
        );
      case AttentionSeverity.warning:
        return (
          iconBg: ColorPalette.chipManualBg,
          iconFg: ColorPalette.chipManualFg,
          pillBg: ColorPalette.chipManualBg,
          pillFg: ColorPalette.chipManualFg,
        );
      case AttentionSeverity.eta:
        return (
          iconBg: ColorPalette.chipCatalogBg,
          iconFg: ColorPalette.chipCatalogFg,
          pillBg: ColorPalette.chipCatalogBg,
          pillFg: ColorPalette.chipCatalogFg,
        );
    }
  }

  String _pillLabel(AppLocalizations s) {
    if (item.severity == AttentionSeverity.eta) {
      return s.dashboardEtaPill(item.waitMin);
    }
    return s.dashboardWaitPill(item.waitMin);
  }

  String _subtitle(AppLocalizations s) {
    final parts = <String>[
      s.dashboardRoomPrefix(item.ticket.room.number),
      item.ticket.department.label(s),
      if (item.severity == AttentionSeverity.eta &&
          item.ticket.assigneeName != null)
        item.ticket.assigneeName!,
    ];
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final p = _palette();
    return Material(
      color: ColorPalette.opsSurface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ColorPalette.opsBorder, width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration:
                    BoxDecoration(color: p.iconBg, shape: BoxShape.circle),
                child: Icon(
                  item.severity == AttentionSeverity.overdue
                      ? Icons.error_outline
                      : Icons.access_time_rounded,
                  color: p.iconFg,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.ticket.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TypographyManager.bodyMedium.copyWith(
                        color: ColorPalette.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _subtitle(s),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TypographyManager.bodySmall.copyWith(
                        color: ColorPalette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _SeverityPill(
                label: _pillLabel(s),
                bg: p.pillBg,
                fg: p.pillFg,
                showClock: item.severity != AttentionSeverity.eta,
              ),
            ],
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
  final bool showClock;

  const _SeverityPill({
    required this.label,
    required this.bg,
    required this.fg,
    required this.showClock,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showClock) ...[
            Icon(Icons.access_time_rounded, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TypographyManager.labelSmall.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
