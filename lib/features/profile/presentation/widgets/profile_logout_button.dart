import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/theme/typography_manager.dart';
import '../../../auth/presentation/providers/auth_session_controller.dart';

/// Full-width destructive CTA at the bottom of the profile screen. Confirms
/// before signing out, then clears the auth session — the FCM device token
/// in `DeviceTokenService` is intentionally left alone so push notifications
/// can be re-bound on the next sign-in without re-requesting permission.
///
/// No imperative navigation: the root widget watches
/// `authSessionControllerProvider` and swaps to `LoginScreen` when the
/// session goes null.
class ProfileLogoutButton extends ConsumerStatefulWidget {
  const ProfileLogoutButton({super.key});

  @override
  ConsumerState<ProfileLogoutButton> createState() =>
      _ProfileLogoutButtonState();
}

class _ProfileLogoutButtonState extends ConsumerState<ProfileLogoutButton> {
  bool _busy = false;

  Future<void> _confirmAndSignOut(BuildContext context) async {
    if (_busy) return;
    final s = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s.profileLogoutConfirmTitle),
        content: Text(s.profileLogoutConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(s.profileLogoutConfirmCancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: ColorPalette.primary),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(s.profileLogoutConfirmAction),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;

    setState(() => _busy = true);
    try {
      await ref.read(authSessionControllerProvider.notifier).clear();
      // Root widget reactively swaps to LoginScreen — no Navigator call.
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _busy ? null : () => _confirmAndSignOut(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorPalette.primary,
          foregroundColor: ColorPalette.white,
          disabledBackgroundColor: ColorPalette.primary.withOpacity(0.6),
          disabledForegroundColor: ColorPalette.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _busy
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: ColorPalette.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.logOut, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    s.profileLogout,
                    style: TypographyManager.titleMedium.copyWith(
                      color: ColorPalette.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
