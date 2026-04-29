import 'package:flutter/material.dart';

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
    final palette = _palette(severity);

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
                  color: palette.shadow.withOpacity(0.2),
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

_ToastPalette _palette(ToastSeverity severity) {
  switch (severity) {
    case ToastSeverity.error:
      return const _ToastPalette(
        bg: Color(0xFFFFE5E5), // Light red
        fg: Color(0xFFB91C1C), // Dark red
        border: Color(0xFFFECACA), // Red border
        shadow: Color(0xFFEF4444),
        icon: Icons.error_outline_rounded,
      );
    case ToastSeverity.info:
      return const _ToastPalette(
        bg: Color(0xFFDBEAFE), // Light blue
        fg: Color(0xFF1D4ED8), // Dark blue
        border: Color(0xFFBFDBFE), // Blue border
        shadow: Color(0xFF3B82F6),
        icon: Icons.info_outline_rounded,
      );
    case ToastSeverity.success:
      return const _ToastPalette(
        bg: Color(0xFFDCFCE7), // Light green
        fg: Color(0xFF15803D), // Dark green
        border: Color(0xFFBBF7D0), // Green border
        shadow: Color(0xFF22C55E),
        icon: Icons.check_circle_outline_rounded,
      );
  }
}

/// Extension to map old severity to new
extension ToastSeverityMapping on Enum {
  ToastSeverity? get asToastSeverity {
    if (this.toString().contains('error')) return ToastSeverity.error;
    if (this.toString().contains('info')) return ToastSeverity.info;
    if (this.toString().contains('success')) return ToastSeverity.success;
    return null;
  }
}
