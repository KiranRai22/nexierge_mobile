import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/theme/app_colors.dart';

/// Top bar for the tickets screen — theme toggle, notifications bell with
/// unread dot, and a search toggle button. Mirrors [AppTopBar] layout but
/// replaces the avatar with a search affordance.
class TicketsTopBar extends StatelessWidget {
  final bool hasUnreadNotifications;
  final bool isDarkMode;
  final bool isSearchVisible;
  final VoidCallback? onThemeToggle;
  final VoidCallback? onNotifications;
  final VoidCallback? onSearchToggle;

  const TicketsTopBar({
    super.key,
    this.hasUnreadNotifications = false,
    this.isDarkMode = false,
    this.isSearchVisible = false,
    this.onThemeToggle,
    this.onNotifications,
    this.onSearchToggle,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final c = context.appColors;
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          // Search toggle
          IconButton(
            tooltip: s.ticketsSearchHint,
            onPressed: onSearchToggle,
            icon: Icon(
              isSearchVisible ? LucideIcons.x : LucideIcons.search,
              color: c.fgBase,
              size: 20,
            ),
          ),
          const Spacer(),
          // Theme toggle
          IconButton(
            tooltip: s.tooltipToggleTheme,
            onPressed: onThemeToggle,
            icon: Icon(
              isDarkMode ? LucideIcons.sun : LucideIcons.moon,
              color: c.fgBase,
              size: 20,
            ),
          ),
          // Notifications bell
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                tooltip: s.tooltipNotifications,
                onPressed: onNotifications,
                icon: Icon(LucideIcons.bell, color: c.fgBase, size: 20),
              ),
              if (hasUnreadNotifications)
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: c.tagRedText,
                      shape: BoxShape.circle,
                      border: Border.all(color: c.bgBase, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
