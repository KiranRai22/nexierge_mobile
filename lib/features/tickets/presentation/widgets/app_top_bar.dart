import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/services/sound_manager.dart';
import '../../../../core/theme/unified_theme_manager.dart';
import '../../../../core/theme/typography_manager.dart';

/// Shared top bar used by Dashboard / Tickets / Activity. Mirrors the React
/// HotelOps shell: avatar (left) · theme toggle · optional language ·
/// notifications bell with red dot (right). All glyphs are Lucide.
///
/// The language button is opt-in — supply `onLanguageTap` to show it. The
/// dashboard hides it (matching `Dashboard.tsx`); other screens keep it.
class AppTopBar extends StatelessWidget {
  final String avatarInitials;
  final String? avatarImageUrl;
  final int unreadCount;

  /// Drives the theme-toggle glyph: `true` shows a Sun (tap → go light),
  /// `false` shows a Moon (tap → go dark). Mirrors the React behaviour.
  final bool isDarkMode;
  final VoidCallback? onThemeToggle;
  final VoidCallback? onLanguageTap;
  final VoidCallback? onNotifications;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onRefresh;

  const AppTopBar({
    super.key,
    required this.avatarInitials,
    this.avatarImageUrl,
    this.unreadCount = 0,
    this.isDarkMode = false,
    this.onThemeToggle,
    this.onLanguageTap,
    this.onNotifications,
    this.onAvatarTap,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final c = context.themeColors;
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          _Avatar(
            initials: avatarInitials,
            imageUrl: avatarImageUrl,
            onTap: onAvatarTap,
          ),
          const Spacer(),
          if (onRefresh != null)
            IconButton(
              tooltip: 'Refresh',
              onPressed: () async {
                await SoundManager.instance.play(SoundCategory.preference);
                onRefresh!();
              },
              icon: Icon(
                LucideIcons.refreshCw,
                color: c.fgBase,
                size: 20,
              ),
            ),
          IconButton(
            tooltip: s.tooltipToggleTheme,
            onPressed: onThemeToggle == null
                ? null
                : () async {
                    await SoundManager.instance.play(SoundCategory.preference);
                    onThemeToggle!();
                  },
            icon: Icon(
              isDarkMode ? LucideIcons.sun : LucideIcons.moon,
              color: c.fgBase,
              size: 20,
            ),
          ),
          if (onLanguageTap != null)
            IconButton(
              tooltip: s.tooltipLanguage,
              onPressed: () async {
                await SoundManager.instance.play(SoundCategory.preference);
                onLanguageTap!();
              },
              icon: Icon(Icons.language_outlined, color: c.fgBase),
            ),
          _BellIcon(
            unreadCount: unreadCount,
            tooltip: s.tooltipNotifications,
            onTap: onNotifications,
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

class _BellIcon extends StatelessWidget {
  final int unreadCount;
  final String tooltip;
  final VoidCallback? onTap;
  const _BellIcon({required this.unreadCount, required this.tooltip, this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: tooltip,
          onPressed: onTap,
          icon: Icon(LucideIcons.bell, color: c.fgBase, size: 20),
        ),
        if (unreadCount > 0)
          Positioned(
            right: 6,
            top: 6,
            child: _UnreadBadge(count: unreadCount),
          ),
      ],
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  final int count;
  const _UnreadBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    final label = count > 99 ? '99+' : count.toString();
    return Container(
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      padding: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: c.tagRedText,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.bgBase, width: 1.5),
      ),
      child: Text(
        label,
        style: TypographyManager.labelSmall.copyWith(
          fontSize: 9,
          color: Colors.white,
          fontWeight: FontWeight.w700,
          height: 1.4,
        ),
      ),
    );
  }
}
