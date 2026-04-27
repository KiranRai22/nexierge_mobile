import 'package:flutter/material.dart';

import '../../../../core/theme/color_palette.dart';
import '../../../../core/theme/typography_manager.dart';

/// Severity for the toast banner shown above the login button.
enum LoginAlertSeverity { error, info, success }

/// Themed toast/snack bar for the login screen. Used for transient
/// errors (validation, network, generic auth failure). State-based
/// account errors use [LoginStateDialog] instead — they need
/// acknowledgement, not an auto-dismissing chip.
abstract class LoginAlert {
  static void show(
    BuildContext context, {
    required LoginAlertSeverity severity,
    required String message,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    final palette = _palette(severity);

    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          backgroundColor: palette.bg,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: palette.border, width: 1),
          ),
          duration: const Duration(seconds: 4),
          content: Row(
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
      );
  }
}

class _Palette {
  final Color bg;
  final Color fg;
  final Color border;
  final IconData icon;
  const _Palette({
    required this.bg,
    required this.fg,
    required this.border,
    required this.icon,
  });
}

_Palette _palette(LoginAlertSeverity severity) {
  switch (severity) {
    case LoginAlertSeverity.error:
      return const _Palette(
        bg: ColorPalette.activityOverdueBg,
        fg: ColorPalette.activityOverdueFg,
        border: ColorPalette.activityOverdueFg,
        icon: Icons.error_outline,
      );
    case LoginAlertSeverity.info:
      return const _Palette(
        bg: ColorPalette.chipCatalogBg,
        fg: ColorPalette.chipCatalogFg,
        border: ColorPalette.chipCatalogFg,
        icon: Icons.info_outline,
      );
    case LoginAlertSeverity.success:
      return const _Palette(
        bg: ColorPalette.activityDoneBg,
        fg: ColorPalette.activityDoneFg,
        border: ColorPalette.activityDoneFg,
        icon: Icons.check_circle_outline,
      );
  }
}
