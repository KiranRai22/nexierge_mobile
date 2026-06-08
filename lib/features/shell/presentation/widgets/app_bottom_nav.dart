import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/services/sound_manager.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/typography_manager.dart';

/// Bottom navigation tab identifier shared between the shell and router.
enum ShellTab { dashboard, tickets, profile }

/// Flat 3-slot bottom navigation matching hotel-ops.lovable.app/dashboard:
/// Dashboard · Tickets · Profile. The Create action lives in a separate
/// floating action button (Scaffold.floatingActionButton), not in the bar.
class AppBottomNav extends StatelessWidget {
  final ShellTab current;
  final ValueChanged<ShellTab> onSelect;

  const AppBottomNav({
    super.key,
    required this.current,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final c = context.themeColors;
    return Material(
      color: c.bgComponent,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _slot(
                context,
                ShellTab.dashboard,
                LucideIcons.grid2x2Check100,
                LucideIcons.grid2x2,
                s.navDashboard,
              ),
              _slot(
                context,
                ShellTab.tickets,
                LucideIcons.ticket100,
                LucideIcons.ticket,
                s.navTickets,
              ),
              _slot(
                context,
                ShellTab.profile,
                LucideIcons.userRound100,
                LucideIcons.userRound,
                s.navProfile,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Expanded _slot(
    BuildContext context,
    ShellTab tab,
    IconData inactive,
    IconData active,
    String label,
  ) {
    final c = context.themeColors;
    final isActive = current == tab;
    final color = isActive ? c.tagPurpleIcon : c.fgMuted;
    return Expanded(
      child: Container(
        decoration: isActive
            ? BoxDecoration(
                border: Border(
                  top: BorderSide(color: c.tagPurpleIcon, width: 1),
                ),
              )
            : null,
        child: InkWell(
          onTap: () async {
            await SoundManager.instance.play(SoundCategory.navigation);
            onSelect(tab);
          },
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(1),
          ),
          splashColor: c.fgMuted.withValues(alpha: 0.1),
          highlightColor: c.fgMuted.withValues(alpha: 0.05),
          child: Semantics(
            label: label,
            selected: isActive,
            button: true,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(isActive ? active : inactive, size: 22, color: color),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TypographyManager.labelSmall.copyWith(
                    color: color,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
