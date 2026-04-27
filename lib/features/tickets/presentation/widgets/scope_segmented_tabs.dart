import 'package:flutter/material.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/theme/typography_manager.dart';
import '../providers/session_providers.dart';

/// Pill-style segmented control: My Dept | All Hotel, with a trailing
/// filter icon button. Pure UI — caller wires state via [scope] /
/// [onScopeChanged] / [onFilterTap].
class ScopeSegmentedTabs extends StatelessWidget {
  final TicketScope scope;
  final ValueChanged<TicketScope> onScopeChanged;
  final VoidCallback onFilterTap;
  final bool hasActiveFilter;

  const ScopeSegmentedTabs({
    super.key,
    required this.scope,
    required this.onScopeChanged,
    required this.onFilterTap,
    this.hasActiveFilter = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SegmentedTrack(scope: scope, onChanged: onScopeChanged),
        ),
        const SizedBox(width: 8),
        _FilterButton(active: hasActiveFilter, onTap: onFilterTap),
      ],
    );
  }
}

class _SegmentedTrack extends StatelessWidget {
  final TicketScope scope;
  final ValueChanged<TicketScope> onChanged;
  const _SegmentedTrack({required this.scope, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    return Container(
      height: 36,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: ColorPalette.subTabBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          _SegmentTab(
            label: s.scopeMyDept,
            selected: scope == TicketScope.myDept,
            onTap: () => onChanged(TicketScope.myDept),
          ),
          _SegmentTab(
            label: s.scopeAllHotel,
            selected: scope == TicketScope.allHotel,
            onTap: () => onChanged(TicketScope.allHotel),
          ),
        ],
      ),
    );
  }
}

class _SegmentTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SegmentTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? ColorPalette.white : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              label,
              style: TypographyManager.tabText.copyWith(
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected
                    ? ColorPalette.textPrimary
                    : ColorPalette.subTabInactiveFg,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  const _FilterButton({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.l10n.filterTitle,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 36,
          width: 36,
          decoration: BoxDecoration(
            color: active ? ColorPalette.opsPurpleTint : ColorPalette.subTabBg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: active ? ColorPalette.opsPurple : ColorPalette.opsBorder,
            ),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.tune_rounded,
            size: 18,
            color: active ? ColorPalette.opsPurple : ColorPalette.textSecondary,
          ),
        ),
      ),
    );
  }
}
