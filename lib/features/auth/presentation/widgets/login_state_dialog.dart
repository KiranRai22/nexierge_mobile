import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/services/sound_manager.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/theme/typography_manager.dart';

/// Acknowledge-only dialog for state-based account errors (pending
/// review, rejected, disabled, hotel inactive). Spec §10 / §15.4.
abstract class LoginStateDialog {
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          actionsPadding: const EdgeInsets.fromLTRB(8, 8, 12, 12),
          actionsAlignment: MainAxisAlignment.end,
          title: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                LucideIcons.triangleAlert,
                color: ColorPalette.activityOverdueFg,
                size: 32,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TypographyManager.titleMedium.copyWith(
                  color: ColorPalette.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: TypographyManager.bodyMedium.copyWith(
              color: ColorPalette.textSecondary,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: tapSound(() => Navigator.of(ctx).pop()),
              child: Text(ctx.l10n.confirm),
            ),
          ],
        );
      },
    );
  }
}
