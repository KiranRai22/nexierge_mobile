import 'package:flutter/material.dart';

import '../../../../core/i18n/l10n_extension.dart';
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
          title: Row(
            children: [
              const Icon(
                Icons.error_outline,
                color: ColorPalette.activityOverdueFg,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TypographyManager.titleMedium.copyWith(
                    color: ColorPalette.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: TypographyManager.bodyMedium.copyWith(
              color: ColorPalette.textSecondary,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(ctx.l10n.confirm),
            ),
          ],
        );
      },
    );
  }
}
