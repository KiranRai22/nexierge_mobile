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
    final c = context.themeColors;
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
          IconButton(
            tooltip: s.ticketsSearchHint,
            onPressed: onSearchToggle,
            icon: Icon(
              isSearchVisible ? LucideIcons.x : LucideIcons.search,
              color: c.fgBase,
              size: 20,
            ),
          ),
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
