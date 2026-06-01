import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/services/sound_manager.dart';
import '../../../../core/theme/unified_theme_manager.dart';
import '../../../../core/theme/typography_manager.dart';

/// Top bar for the tickets screen — avatar, theme toggle, notifications bell with
/// unread dot, and a search toggle button. Mirrors [AppTopBar] layout.
class TicketsTopBar extends StatelessWidget {
  final String avatarInitials;
  final String? avatarImageUrl;
  final int unreadCount;
  final bool isDarkMode;
  final bool isSearchVisible;
  final VoidCallback? onThemeToggle;
  final VoidCallback? onNotifications;
  final VoidCallback? onSearchToggle;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onRefresh;

  const TicketsTopBar({
    super.key,
    required this.avatarInitials,
    this.avatarImageUrl,
    this.unreadCount = 0,
    this.isDarkMode = false,
    this.isSearchVisible = false,
    this.onThemeToggle,
    this.onNotifications,
    this.onSearchToggle,
    this.onAvatarTap,
    this.onRefresh,
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
          // Refresh
          if (onRefresh != null) ...[
            _CircleIconButton(
              tooltip: 'Refresh',
              onPressed: onRefresh,
              icon: LucideIcons.refreshCw,
            ),
            const SizedBox(width: 8),
          ],
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
            unreadCount: unreadCount,
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
      onTap: onTap == null
          ? null
          : () async {
              await SoundManager.instance.play(SoundCategory.button);
              onTap!();
            },
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
  final int unreadCount;

  const _CircleIconButton({
    required this.tooltip,
    this.onPressed,
    required this.icon,
    this.unreadCount = 0,
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
            onTap: tapSound(onPressed),
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
          if (unreadCount > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                padding: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: c.tagRedText,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: c.bgBase, width: 1.5),
                ),
                child: Text(
                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                  style: TypographyManager.labelSmall.copyWith(
                    fontSize: 8,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
