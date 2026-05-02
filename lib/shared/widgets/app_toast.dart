import 'package:flutter/material.dart';

import '../../../core/theme/typography_manager.dart';

/// Toast types supported by the app
enum ToastType { success, failure, info, warning }

/// Toast position on screen
enum ToastPosition { top, bottom }

/// Generic app toast manager - reusable across the entire application.
///
/// Usage:
/// ```dart
/// AppToast.show(
///   context,
///   title: context.l10n.successTitle,
///   subtitle: 'Ticket created successfully',
///   type: ToastType.success,
///   position: ToastPosition.top,
///   duration: Duration(seconds: 3),
/// );
/// ```
class AppToast {
  static OverlayEntry? _currentOverlay;

  /// Show a toast notification
  static void show(
    BuildContext context, {
    required String title,
    String? subtitle,
    ToastType type = ToastType.info,
    ToastPosition position = ToastPosition.top,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onClose,
  }) {
    // Remove existing toast if any
    hide();

    final overlay = Overlay.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = _ToastPalette.fromType(type, isDark);

    _currentOverlay = OverlayEntry(
      builder: (context) => Positioned(
        top: position == ToastPosition.top
            ? MediaQuery.of(context).padding.top + 16
            : null,
        bottom: position == ToastPosition.bottom
            ? MediaQuery.of(context).padding.bottom + 16
            : null,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: palette.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: palette.border, width: 1),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: palette.iconBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(palette.icon, color: palette.iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TypographyManager.bodyMedium.copyWith(
                          color: palette.text,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (subtitle != null && subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TypographyManager.bodySmall.copyWith(
                            color: palette.subtitle,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Close button
                GestureDetector(
                  onTap: () {
                    hide();
                    onClose?.call();
                  },
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: palette.closeBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.close,
                      color: palette.closeIcon,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(_currentOverlay!);

    // Auto dismiss
    Future.delayed(duration, () => hide());
  }

  /// Hide the current toast if any
  static void hide() {
    _currentOverlay?.remove();
    _currentOverlay = null;
  }
}

/// Palette definition for each toast type (light and dark themes)
class _ToastPalette {
  final Color background;
  final Color border;
  final Color iconBg;
  final Color iconColor;
  final Color text;
  final Color subtitle;
  final Color closeBg;
  final Color closeIcon;
  final IconData icon;

  const _ToastPalette({
    required this.background,
    required this.border,
    required this.iconBg,
    required this.iconColor,
    required this.text,
    required this.subtitle,
    required this.closeBg,
    required this.closeIcon,
    required this.icon,
  });

  factory _ToastPalette.fromType(ToastType type, bool isDark) {
    switch (type) {
      case ToastType.success:
        return _ToastPalette(
          background: isDark
              ? const Color(0xFF1C2B1C)
              : const Color(0xFFE8F5E9),
          border: isDark ? const Color(0xFF34A853) : const Color(0xFF34A853),
          iconBg: isDark ? const Color(0xFF2E7D32) : const Color(0xFF34A853),
          iconColor: Colors.white,
          text: isDark ? Colors.white : const Color(0xFF1B5E20),
          subtitle: isDark ? const Color(0xFFB0B0B0) : const Color(0xFF4A4A4A),
          closeBg: isDark
              ? const Color(0xFF2E7D32)
              : const Color(0xFF34A853).withValues(alpha: 0.1),
          closeIcon: isDark ? Colors.white : const Color(0xFF34A853),
          icon: Icons.check,
        );
      case ToastType.failure:
        return _ToastPalette(
          background: isDark
              ? const Color(0xFF2B1C1C)
              : const Color(0xFFFFEBEE),
          border: isDark ? const Color(0xFFEA4335) : const Color(0xFFEA4335),
          iconBg: isDark ? const Color(0xFFC62828) : const Color(0xFFEA4335),
          iconColor: Colors.white,
          text: isDark ? Colors.white : const Color(0xFFB71C1C),
          subtitle: isDark ? const Color(0xFFB0B0B0) : const Color(0xFF4A4A4A),
          closeBg: isDark
              ? const Color(0xFFC62828)
              : const Color(0xFFEA4335).withValues(alpha: 0.1),
          closeIcon: isDark ? Colors.white : const Color(0xFFEA4335),
          icon: Icons.close,
        );
      case ToastType.info:
        return _ToastPalette(
          background: isDark
              ? const Color(0xFF1C2435)
              : const Color(0xFFE3F2FD),
          border: isDark ? const Color(0xFF1A73E8) : const Color(0xFF1A73E8),
          iconBg: isDark ? const Color(0xFF1565C0) : const Color(0xFF1A73E8),
          iconColor: Colors.white,
          text: isDark ? Colors.white : const Color(0xFF0D47A1),
          subtitle: isDark ? const Color(0xFFB0B0B0) : const Color(0xFF4A4A4A),
          closeBg: isDark
              ? const Color(0xFF1565C0)
              : const Color(0xFF1A73E8).withValues(alpha: 0.1),
          closeIcon: isDark ? Colors.white : const Color(0xFF1A73E8),
          icon: Icons.info_outline,
        );
      case ToastType.warning:
        return _ToastPalette(
          background: isDark
              ? const Color(0xFF2D2818)
              : const Color(0xFFFFF8E1),
          border: isDark ? const Color(0xFFFBBC04) : const Color(0xFFFBBC04),
          iconBg: isDark ? const Color(0xFFF57F17) : const Color(0xFFFBBC04),
          iconColor: Colors.white,
          text: isDark ? Colors.white : const Color(0xFF8D6E63),
          subtitle: isDark ? const Color(0xFFB0B0B0) : const Color(0xFF4A4A4A),
          closeBg: isDark
              ? const Color(0xFFF57F17)
              : const Color(0xFFFBBC04).withValues(alpha: 0.1),
          closeIcon: isDark ? Colors.white : const Color(0xFFE65100),
          icon: Icons.warning_amber_rounded,
        );
    }
  }
}

/// Extension for easier toast access from BuildContext
extension AppToastExtension on BuildContext {
  /// Show success toast
  void showSuccess(
    String title, {
    String? subtitle,
    ToastPosition position = ToastPosition.top,
  }) {
    AppToast.show(
      this,
      title: title,
      subtitle: subtitle,
      type: ToastType.success,
      position: position,
    );
  }

  /// Show failure/error toast
  void showFailure(
    String title, {
    String? subtitle,
    ToastPosition position = ToastPosition.top,
  }) {
    AppToast.show(
      this,
      title: title,
      subtitle: subtitle,
      type: ToastType.failure,
      position: position,
    );
  }

  /// Show info toast
  void showInfo(
    String title, {
    String? subtitle,
    ToastPosition position = ToastPosition.top,
  }) {
    AppToast.show(
      this,
      title: title,
      subtitle: subtitle,
      type: ToastType.info,
      position: position,
    );
  }

  /// Show warning toast
  void showWarning(
    String title, {
    String? subtitle,
    ToastPosition position = ToastPosition.top,
  }) {
    AppToast.show(
      this,
      title: title,
      subtitle: subtitle,
      type: ToastType.warning,
      position: position,
    );
  }
}
