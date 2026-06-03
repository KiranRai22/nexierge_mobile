import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nexierge/l10n/generated/app_localizations.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/services/sound_manager.dart';
import '../../../../core/theme/unified_theme_manager.dart';
import '../../../../core/theme/typography_manager.dart';

/// Full-width tabs for Incoming, In Progress, Done with optional collapsible Backlog.
/// Backlog is hidden by default and revealed via the toggle button at the end.
class TicketsMainTabs extends StatelessWidget {
  final TicketsMainTab selectedTab;
  final ValueChanged<TicketsMainTab> onChanged;
  final Map<TicketsMainTab, int> counts;
  final bool isBacklogExpanded;
  final VoidCallback onToggleBacklog;

  const TicketsMainTabs({
    super.key,
    required this.selectedTab,
    required this.onChanged,
    required this.counts,
    required this.isBacklogExpanded,
    required this.onToggleBacklog,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    final s = context.l10n;

    final visibleTabs = isBacklogExpanded
        ? TicketsMainTab.values.toList()
        : TicketsMainTab.values
              .where((t) => t != TicketsMainTab.backlog)
              .toList();

    return Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.borderBase,
        borderRadius: BorderRadius.circular(10),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 240),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          child: child,
        ),
        child: Row(
          key: ValueKey(isBacklogExpanded),
          children: [
            ...visibleTabs.map((tab) {
              final isSelected = selectedTab == tab;
              return Expanded(
                child: _TabItem(
                  label: _getTabLabel(s, tab),
                  count: counts[tab] ?? 0,
                  isSelected: isSelected,
                  onTap: () => onChanged(tab),
                  colors: c,
                ),
              );
            }),
            _BacklogToggleButton(
              isExpanded: isBacklogExpanded,
              onTap: onToggleBacklog,
              colors: c,
            ),
          ],
        ),
      ),
    );
  }

  String _getTabLabel(AppLocalizations s, TicketsMainTab tab) {
    switch (tab) {
      case TicketsMainTab.incoming:
        return s.subTabIncoming;
      case TicketsMainTab.today:
        return s.subTabToday;
      case TicketsMainTab.backlog:
        return s.subTabBacklog;
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
  final AppColors colors;

  const _TabItem({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return GestureDetector(
      onTap: tapSound(onTap, SoundCategory.navigation),
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: isSelected
              ? BoxDecoration(
                  color: c.bgBase,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: c.borderBase),
                )
              : null,
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
                    color: isSelected ? c.tagPurpleBg : c.bgSubtle,
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
      ),
    );
  }
}

class _BacklogToggleButton extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onTap;
  final AppColors colors;

  const _BacklogToggleButton({
    required this.isExpanded,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return GestureDetector(
      onTap: tapSound(onTap, SoundCategory.navigation),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 38,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // if (!isExpanded) ...[
            //   Text(
            //     '...',
            //     style: TypographyManager.tabText.copyWith(
            //       fontSize: 9,
            //       color: c.fgMuted,
            //       fontWeight: FontWeight.w700,
            //       height: 1,
            //     ),
            //   ),
            //   const SizedBox(height: 2),
            // ],
            Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.bgSubtle,
                shape: BoxShape.circle,
                border: Border.all(color: c.borderBase),
              ),
              child: AnimatedRotation(
                turns: isExpanded ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeInOut,
                child: Icon(
                  LucideIcons.chevronLeft,
                  size: 11,
                  color: c.fgMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum TicketsMainTab { incoming, today, done, backlog }
