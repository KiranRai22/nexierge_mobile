import 'package:flutter/material.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/theme/typography_manager.dart';

/// Shared top bar used by Tickets and Activity. Mirrors the prototype:
/// avatar (left) · theme toggle · language · notifications bell with red dot
/// (right).
///
/// Language sits between theme and notifications per product order. The
/// destinations are decided by the host screen — this widget exposes
/// [onThemeToggle] / [onLanguageTap] / [onNotifications] callbacks so it
/// stays presentational and stateless.
class AppTopBar extends StatelessWidget {
  final String avatarInitials;
  final bool hasUnreadNotifications;
  final VoidCallback? onThemeToggle;
  final VoidCallback? onLanguageTap;
  final VoidCallback? onNotifications;
  final VoidCallback? onAvatarTap;

  const AppTopBar({
    super.key,
    required this.avatarInitials,
    this.hasUnreadNotifications = false,
    this.onThemeToggle,
    this.onLanguageTap,
    this.onNotifications,
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          _Avatar(initials: avatarInitials, onTap: onAvatarTap),
          const Spacer(),
          IconButton(
            tooltip: s.tooltipToggleTheme,
            onPressed: onThemeToggle,
            icon: const Icon(Icons.dark_mode_outlined,
                color: ColorPalette.textPrimary),
          ),
          IconButton(
            tooltip: s.tooltipLanguage,
            onPressed: onLanguageTap,
            icon: const Icon(Icons.language_outlined,
                color: ColorPalette.textPrimary),
          ),
          _BellIcon(
            hasUnread: hasUnreadNotifications,
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
  final VoidCallback? onTap;
  const _Avatar({required this.initials, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: ColorPalette.opsSurfaceSubtle,
          shape: BoxShape.circle,
          border: Border.all(color: ColorPalette.opsBorder),
        ),
        alignment: Alignment.center,
        child: Text(
          initials,
          style: TypographyManager.labelSmall.copyWith(
            color: ColorPalette.textPrimary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }
}

class _BellIcon extends StatelessWidget {
  final bool hasUnread;
  final String tooltip;
  final VoidCallback? onTap;
  const _BellIcon({
    required this.hasUnread,
    required this.tooltip,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: tooltip,
          onPressed: onTap,
          icon: const Icon(Icons.notifications_outlined,
              color: ColorPalette.textPrimary),
        ),
        if (hasUnread)
          const Positioned(
            right: 10,
            top: 10,
            child: _UnreadDot(),
          ),
      ],
    );
  }
}

class _UnreadDot extends StatelessWidget {
  const _UnreadDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: ColorPalette.kpiOverdueText,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
    );
  }
}
