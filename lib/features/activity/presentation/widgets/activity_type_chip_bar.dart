import 'package:flutter/material.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/theme/typography_manager.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../providers/activity_controller.dart';

/// Horizontally scrollable filter pills above the activity feed.
class ActivityTypeChipBar extends StatelessWidget {
  final ActivityFilter selected;
  final ValueChanged<ActivityFilter> onChanged;
  const ActivityTypeChipBar({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  static const List<ActivityFilter> _filters = [
    ActivityFilter.all,
    ActivityFilter.created,
    ActivityFilter.accepted,
    ActivityFilter.done,
    ActivityFilter.overdue,
    ActivityFilter.cancelled,
    ActivityFilter.notes,
    ActivityFilter.reassigned,
  ];

  String _label(AppLocalizations s, ActivityFilter f) {
    switch (f) {
      case ActivityFilter.all:
        return s.activityTypeAll;
      case ActivityFilter.created:
        return s.activityTypeCreated;
      case ActivityFilter.accepted:
        return s.activityTypeAccepted;
      case ActivityFilter.done:
        return s.activityTypeDone;
      case ActivityFilter.overdue:
        return s.activityTypeOverdue;
      case ActivityFilter.cancelled:
        return s.activityTypeCancelled;
      case ActivityFilter.notes:
        return s.activityTypeNotes;
      case ActivityFilter.reassigned:
        return s.activityTypeReassigned;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final f = _filters[i];
          return _Chip(
            label: _label(s, f),
            selected: f == selected,
            onTap: () => onChanged(f),
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? ColorPalette.subTabActiveBg
                : ColorPalette.subTabBg,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: TypographyManager.tabText.copyWith(
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected
                  ? ColorPalette.subTabActiveFg
                  : ColorPalette.subTabInactiveFg,
            ),
          ),
        ),
      ),
    );
  }
}
