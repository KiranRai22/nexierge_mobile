import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/services/sound_manager.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/typography_manager.dart';

/// Top bar for the tickets screen — avatar + title (left), search / filter /
/// bell (right). The filter button sits between search and notifications,
/// matching the design. Supply [onFilter] + [filterActiveCount] to show it.
class TicketsTopBar extends StatelessWidget {
  final String avatarInitials;
  final String? avatarImageUrl;
  final int unreadCount;
  final bool isDarkMode;
  final bool isSearchVisible;

  /// Optional screen title shown next to the avatar, e.g. "All Tickets".
  final String? title;

  /// Opens the filter sheet. Supply to show the funnel button.
  final VoidCallback? onFilter;

  /// Badge count on the filter button (purple badge when > 0).
  final int filterActiveCount;

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
    this.title,
    this.onFilter,
    this.filterActiveCount = 0,
    this.onThemeToggle,
    this.onNotifications,
    this.onSearchToggle,
    this.onAvatarTap,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final c = context.themeColors;
    return SizedBox(
      height: 60,
      child: Row(
        children: [
          // Avatar
          _Avatar(
            initials: avatarInitials,
            imageUrl: avatarImageUrl,
            onTap: onAvatarTap,
          ),
          // Title next to avatar
          if (title != null) ...[
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TypographyManager.textHeading.copyWith(
                  color: c.fgBase,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ] else
            const Spacer(),
          // Search toggle
          _CircleIconButton(
            tooltip: s.ticketsSearchHint,
            onPressed: onSearchToggle,
            icon: isSearchVisible ? LucideIcons.x : LucideIcons.search,
          ),
          const SizedBox(width: 8),
          // Filter funnel — between search and notifications
          if (onFilter != null) ...[
            _CircleIconButton(
              tooltip: s.filterTitle,
              onPressed: onFilter,
              icon: LucideIcons.funnel,
              unreadCount: filterActiveCount,
              badgeColor: c.tagPurpleIcon,
            ),
            const SizedBox(width: 8),
          ],
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
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: c.bgSubtle,
          shape: BoxShape.circle,
          border: Border.all(color: c.borderBase),
        ),
        child: ClipOval(
          child: imageUrl != null
              ? Image.network(
                  imageUrl!,
                  width: 44,
                  height: 44,
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
  final Color? badgeColor;

  const _CircleIconButton({
    required this.tooltip,
    this.onPressed,
    required this.icon,
    this.unreadCount = 0,
    this.badgeColor,
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
                  color: badgeColor ?? c.tagRedText,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: c.bgBase, width: 1.5),
                ),
                child: Text(
                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                  style: TypographyManager.labelSmall.copyWith(
                    fontSize: 8,
                    color: context.appColors.fgOnBrand,
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
