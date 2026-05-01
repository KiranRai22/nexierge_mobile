import 'package:flutter/material.dart';
import 'package:nexierge/l10n/generated/app_localizations.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/theme/unified_theme_manager.dart';
import '../../../../core/theme/typography_manager.dart';

/// Full-width tabs for Incoming, Today, Scheduled, Done with counts
class TicketsMainTabs extends StatelessWidget {
  final TicketsMainTab selectedTab;
  final ValueChanged<TicketsMainTab> onChanged;
  final Map<TicketsMainTab, int> counts;

  const TicketsMainTabs({
    super.key,
    required this.selectedTab,
    required this.onChanged,
    required this.counts,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    final s = context.l10n;

    return Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.bgSubtle,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: TicketsMainTab.values.map((tab) {
          final isSelected = selectedTab == tab;
          final count = counts[tab] ?? 0;
          return Expanded(
            child: _TabItem(
              label: _getTabLabel(s, tab),
              count: count,
              isSelected: isSelected,
              onTap: () => onChanged(tab),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getTabLabel(AppLocalizations s, TicketsMainTab tab) {
    switch (tab) {
      case TicketsMainTab.incoming:
        return s.subTabIncoming;
      case TicketsMainTab.today:
        return s.subTabToday;
      case TicketsMainTab.scheduled:
        return s.subTabScheduled;
      case TicketsMainTab.done:
        return s.subTabDone;
    }
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabItem({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected ? c.bgComponent : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TypographyManager.tabText.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 12,
                  color: isSelected ? c.fgBase : c.fgMuted,
                ),
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Container(
                width: 18,
                height: 18,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? c.tagPurpleBg : c.borderBase,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  count > 99 ? '99+' : count.toString(),
                  style: TypographyManager.labelSmall.copyWith(
                    fontSize: 9,
                    color: isSelected ? c.tagPurpleText : c.fgMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum TicketsMainTab { incoming, today, scheduled, done }
