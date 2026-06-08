import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/typography_manager.dart';

/// Severity for the top-positioned toast
enum ToastSeverity { error, info, success }

/// Custom top-positioned toast for login screen
/// Shows at top of screen with circular edges and light backgrounds
class LoginTopToast {
  static OverlayEntry? _currentOverlay;

  static void show(
    BuildContext context, {
    required ToastSeverity severity,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    // Remove existing toast if any
    hide();

    final overlay = Overlay.of(context);
    final palette = _palette(context.appColors, severity);

    _currentOverlay = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: palette.bg,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: palette.border, width: 1),
              boxShadow: [
                BoxShadow(
                  color: palette.shadow.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Icon(palette.icon, color: palette.fg, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: TypographyManager.bodyMedium.copyWith(
                      color: palette.fg,
                      fontWeight: FontWeight.w500,
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

  static void hide() {
    _currentOverlay?.remove();
    _currentOverlay = null;
  }
}

class _ToastPalette {
  final Color bg;
  final Color fg;
  final Color border;
  final Color shadow;
  final IconData icon;

  const _ToastPalette({
    required this.bg,
    required this.fg,
    required this.border,
    required this.shadow,
    required this.icon,
  });
}

_ToastPalette _palette(AppColors c, ToastSeverity severity) {
  switch (severity) {
    case ToastSeverity.error:
      return _ToastPalette(
        bg: c.bgError,
        fg: c.fgError,
        border: c.borderError,
        shadow: c.fgError,
        icon: LucideIcons.triangleAlert,
      );
    case ToastSeverity.info:
      return _ToastPalette(
        bg: c.bgInfo,
        fg: c.fgInfo,
        border: c.borderInfo,
        shadow: c.fgInfo,
        icon: Icons.info_outline_rounded,
      );
    case ToastSeverity.success:
      return _ToastPalette(
        bg: c.bgSuccess,
        fg: c.fgSuccess,
        border: c.borderSuccess,
        shadow: c.fgSuccess,
        icon: Icons.check_circle_outline_rounded,
      );
  }
}

/// Extension to map old severity to new
extension ToastSeverityMapping on Enum {
  ToastSeverity? get asToastSeverity {
    if (toString().contains('error')) return ToastSeverity.error;
    if (toString().contains('info')) return ToastSeverity.info;
    if (toString().contains('success')) return ToastSeverity.success;
    return null;
  }
}
