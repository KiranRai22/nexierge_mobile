import 'package:flutter/material.dart';
import 'package:nexierge/l10n/generated/app_localizations.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/theme/unified_theme_manager.dart';
import '../../../../core/theme/typography_manager.dart';
import 'tickets_main_tabs.dart';

/// Filter chips that change based on the selected main tab
class TicketsFilterChips extends StatelessWidget {
  final TicketsMainTab selectedTab;
  final String? selectedFilter;
  final ValueChanged<String?> onFilterChanged;

  const TicketsFilterChips({
    super.key,
    required this.selectedTab,
    this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;

    final filters = _getFiltersForTab(s, selectedTab);

    return SizedBox(
      height: 32,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: filters.map((filter) {
          final isSelected = selectedFilter == filter.key;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: _FilterChip(
              label: filter.label,
              isSelected: isSelected,
              onTap: () => onFilterChanged(isSelected ? null : filter.key),
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
      case TicketsMainTab.incoming:
        return [
          _FilterOption('newest', s.filterNewestFirst),
          _FilterOption('oldest', s.filterOldestFirst),
        ];
      case TicketsMainTab.today:
        return [
          _FilterOption('all', s.activityTypeAll),
          _FilterOption('accepted', s.statusAccepted),
          _FilterOption('inprogress', s.statusInProgress),
        ];
      case TicketsMainTab.scheduled:
        return [
          _FilterOption('all', s.activityTypeAll),
          _FilterOption('today', s.subTabToday),
          _FilterOption('thisweek', s.filterThisWeek),
        ];
      case TicketsMainTab.done:
        return [
          _FilterOption('today', s.subTabToday),
          _FilterOption('thisweek', s.filterThisWeek),
          _FilterOption('thismonth', s.filterThisMonth),
        ];
    }
  }
}

class _FilterOption {
  final String key;
  final String label;
  const _FilterOption(this.key, this.label);
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? c.tagPurpleBg : c.bgSubtle,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? c.tagPurpleIcon : c.borderBase,
          ),
        ),
        child: Text(
          label,
          style: TypographyManager.labelSmall.copyWith(
            fontSize: 12,
            color: isSelected ? c.tagPurpleText : c.fgBase,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
