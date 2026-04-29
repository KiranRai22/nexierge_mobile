import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/theme/unified_theme_manager.dart';
import '../../../../core/theme/typography_manager.dart';

/// Top bar for the tickets screen — avatar, theme toggle, notifications bell with
/// unread dot, and a search toggle button. Mirrors [AppTopBar] layout.
class TicketsTopBar extends StatelessWidget {
  final String avatarInitials;
  final String? avatarImageUrl;
  final bool hasUnreadNotifications;
  final bool isDarkMode;
  final bool isSearchVisible;
  final VoidCallback? onThemeToggle;
  final VoidCallback? onNotifications;
  final VoidCallback? onSearchToggle;
  final VoidCallback? onAvatarTap;

  const TicketsTopBar({
    super.key,
    required this.avatarInitials,
    this.avatarImageUrl,
    this.hasUnreadNotifications = false,
    this.isDarkMode = false,
    this.isSearchVisible = false,
    this.onThemeToggle,
    this.onNotifications,
    this.onSearchToggle,
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          // Avatar
          _Avatar(
            initials: avatarInitials,
            imageUrl: avatarImageUrl,
            onTap: onAvatarTap,
          ),
          const Spacer(),
          // Search toggle
          _CircleIconButton(
            tooltip: s.ticketsSearchHint,
            onPressed: onSearchToggle,
            icon: isSearchVisible ? LucideIcons.x : LucideIcons.search,
          ),
          const SizedBox(width: 8),
          // Theme toggle
          _CircleIconButton(
            tooltip: s.tooltipToggleTheme,
            onPressed: onThemeToggle,
            icon: isDarkMode ? LucideIcons.sun : LucideIcons.moon,
          ),
          const SizedBox(width: 8),
          // Notifications bell
          _CircleIconButton(
            tooltip: s.tooltipNotifications,
            onPressed: onNotifications,
            icon: LucideIcons.bell,
            badge: hasUnreadNotifications,
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String initials;
  final String? imageUrl;
  final VoidCallback? onTap;
  const _Avatar({required this.initials, this.imageUrl, this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: c.bgSubtle,
          shape: BoxShape.circle,
          border: Border.all(color: c.borderBase),
        ),
        child: ClipOval(
          child: imageUrl != null
              ? Image.network(
                  imageUrl!,
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback to initials on error
                    return _buildInitials(c);
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return _buildInitials(c);
                  },
                )
              : _buildInitials(c),
        ),
      ),
    );
  }

  Widget _buildInitials(AppColors c) {
    return Center(
      child: Text(
        initials,
        style: TypographyManager.labelSmall.copyWith(
          color: c.fgBase,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final String tooltip;
  final VoidCallback? onPressed;
  final IconData icon;
  final bool badge;

  const _CircleIconButton({
    required this.tooltip,
    this.onPressed,
    required this.icon,
    this.badge = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    return Tooltip(
      message: tooltip,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            onTap: onPressed,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: c.bgSubtle,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(icon, size: 18, color: c.fgBase),
            ),
          ),
          if (badge)
            Positioned(
              right: 0,
              top: 0,
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
    );
  }
}
