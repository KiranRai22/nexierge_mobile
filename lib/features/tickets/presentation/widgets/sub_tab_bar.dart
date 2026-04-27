import 'package:flutter/material.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/theme/typography_manager.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../providers/tickets_list_controller.dart';

/// Pill-bar of sub-tabs: Incoming · Today · Scheduled · Done.
/// Horizontally scrollable so it never overflows on small phones.
class SubTabBar extends StatelessWidget {
  final TicketsSubTab selected;
  final ValueChanged<TicketsSubTab> onChanged;

  const SubTabBar({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  static const List<TicketsSubTab> _tabs = [
    TicketsSubTab.incoming,
    TicketsSubTab.today,
    TicketsSubTab.scheduled,
    TicketsSubTab.done,
  ];

  String _label(AppLocalizations s, TicketsSubTab t) {
    switch (t) {
      case TicketsSubTab.incoming:
        return s.subTabIncoming;
      case TicketsSubTab.today:
        return s.subTabToday;
      case TicketsSubTab.scheduled:
        return s.subTabScheduled;
      case TicketsSubTab.done:
        return s.subTabDone;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: _tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final tab = _tabs[i];
          return _SubTabPill(
            label: _label(s, tab),
            selected: tab == selected,
            onTap: () => onChanged(tab),
          );
        },
      ),
    );
  }
}

class _SubTabPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SubTabPill({
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
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 16),
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
