import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/services/sound_manager.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/typography_manager.dart';

/// Bottom sheet shown when the user taps the logout button.
/// Matches the design of reset acknowledgement bottom sheet.
class LogoutConfirmationBottomSheet extends StatefulWidget {
  const LogoutConfirmationBottomSheet._();

  /// Returns true if user confirmed logout, null if dismissed.
  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const LogoutConfirmationBottomSheet._(),
    );
  }

  @override
  State<LogoutConfirmationBottomSheet> createState() =>
      _LogoutConfirmationBottomSheetState();
}

class _LogoutConfirmationBottomSheetState
    extends State<LogoutConfirmationBottomSheet> {
  void _handleConfirm() {
    Navigator.of(context).pop(true);
  }

  void _handleCancel() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    final s = context.l10n;

    return PopScope(
      canPop: true,
      child: Container(
        decoration: BoxDecoration(
          color: c.bgBase,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: c.borderBase,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header row
            Row(
              children: [
                Expanded(
                  child: Text(
                    s.profileLogoutConfirmTitle,
                    style: TypographyManager.titleLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      color: c.fgBase,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(LucideIcons.x, size: 20, color: c.fgMuted),
                  onPressed: tapSound(_handleCancel, SoundCategory.back),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Body text
            Text(
              s.profileLogoutConfirmBody,
              style: TypographyManager.bodyMedium.copyWith(color: c.fgMuted),
            ),
            const SizedBox(height: 28),
            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: tapSound(_handleCancel, SoundCategory.back),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: c.borderBase),
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      s.profileLogoutConfirmCancel,
                      style: TypographyManager.labelLarge.copyWith(
                        color: c.fgBase,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: tapSound(_handleConfirm),
                    icon: const Icon(LucideIcons.logOut, size: 18),
                    label: Text(s.profileLogoutConfirmAction),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: c.tagRedIcon,
                      foregroundColor: context.appColors.fgOnBrand,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: TypographyManager.labelLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
