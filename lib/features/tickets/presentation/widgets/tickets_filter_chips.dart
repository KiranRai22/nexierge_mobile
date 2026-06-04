import 'package:flutter/material.dart';
import 'package:nexierge/l10n/generated/app_localizations.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/services/sound_manager.dart';
import '../../../../core/theme/unified_theme_manager.dart';
import '../../../../core/theme/typography_manager.dart';
import 'tickets_main_tabs.dart';

/// Filter chips that change based on the selected main tab.
///
/// [filterCounts] is an optional map from filter key (e.g. 'all',
/// 'accepted') to the number of tickets in that bucket. When provided,
/// chips render the count beside the label.
class TicketsFilterChips extends StatelessWidget {
  final TicketsMainTab selectedTab;
  final String? selectedFilter;
  final ValueChanged<String?> onFilterChanged;
  final Map<String, int>? filterCounts;

  const TicketsFilterChips({
    super.key,
    required this.selectedTab,
    this.selectedFilter,
    required this.onFilterChanged,
    this.filterCounts,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;

    final filters = _getFiltersForTab(s, selectedTab);

    return SizedBox(
      height: 27,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: filters.map((filter) {
          final isSelected = selectedFilter == filter.key;
          final count = filterCounts?[filter.key];
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: _FilterChip(
              label: filter.label,
              count: count,
              isSelected: isSelected,
              isDanger: filter.isDanger,
              onTap: () { if (!isSelected) onFilterChanged(filter.key); },
            ),
          );
        }).toList(),
      ),
    );
  }

  List<_FilterOption> _getFiltersForTab(
    AppLocalizations s,
    TicketsMainTab tab,
  ) {
    switch (tab) {
      case TicketsMainTab.today:
        return [
          _FilterOption('active', s.statusActive),
          _FilterOption('overdue', s.statusOverdue, isDanger: true),
        ];
      case TicketsMainTab.incoming:
      case TicketsMainTab.backlog:
      case TicketsMainTab.done:
        return [];
    }
  }
}

class _FilterOption {
  final String key;
  final String label;
  final bool isDanger;
  const _FilterOption(this.key, this.label, {this.isDanger = false});
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int? count;
  final bool isSelected;
  final bool isDanger;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    final bg = isSelected
        ? (isDanger ? c.tagRedBg : c.tagPurpleBg)
        : c.bgSubtle;
    final border = isSelected
        ? (isDanger ? c.tagRedIcon : c.tagPurpleIcon)
        : c.borderBase;
    final fg = isSelected
        ? (isDanger ? c.tagRedText : c.tagPurpleText)
        : c.fgBase;
    final showCount = count != null;
    return GestureDetector(
      onTap: tapSound(onTap, SoundCategory.preference),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TypographyManager.labelSmall.copyWith(
                fontSize: 12,
                color: fg,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            if (showCount) ...[
              const SizedBox(width: 6),
              Text(
                '$count',
                style: TypographyManager.labelSmall.copyWith(
                  fontSize: 12,
                  color: fg,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
