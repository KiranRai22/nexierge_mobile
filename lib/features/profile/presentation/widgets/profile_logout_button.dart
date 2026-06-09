import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/services/sound_manager.dart';
import '../../../../core/theme/typography_manager.dart';
import '../../../auth/presentation/providers/auth_session_controller.dart';
import '../../../auth/presentation/providers/user_profile_controller.dart'
    as auth_ctrl;
import '../../../fcm/data/repositories/fcm_repository.dart';
import '../../../tickets/data/services/tickets_cache_store.dart';
import '../../../../core/services/device_token_service.dart';
import 'logout_confirmation_bottom_sheet.dart';
import '../../../../core/theme/app_colors.dart';

/// Full-width destructive CTA at the bottom of the profile screen. Confirms
/// before signing out. Deregisters the FCM token from the backend (remove: true)
/// before clearing the auth session so the server stops pushing to this device.
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
    final confirmed = await LogoutConfirmationBottomSheet.show(context);
    if (confirmed != true) return;
    if (!mounted) return;

    setState(() => _busy = true);
    try {
      // Deregister FCM token from backend so the server stops pushing to this device.
      final token = await DeviceTokenService.getToken();
      if (token != null && token.isNotEmpty) {
        try {
          await ref.read(fcmRepositoryProvider).edit(fcmToken: token, remove: true);
        } catch (_) {
          // Best-effort: proceed with logout even if deregister fails.
        }
      }

      // Clear cached profile from SharedPreferences so the next user starts
      // fresh. Must happen before clearing the session so the controller can
      // still read its providers during teardown.
      await ref
          .read(auth_ctrl.userProfileControllerProvider.notifier)
          .clearProfile();

      // Drop the on-disk tickets cold-start cache so a different operator
      // logging into this device on next launch never briefly paints the
      // previous user's tickets while their own fetch is in flight.
      // Best-effort — `clearAll()` swallows internal failures.
      await ref.read(ticketsCacheStoreProvider).clearAll();

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
        onPressed: _busy ? null : tapSound(() => _confirmAndSignOut(context)),
        style: ElevatedButton.styleFrom(
          backgroundColor: context.appColors.brandPrimary,
          foregroundColor: context.appColors.fgOnBrand,
          disabledBackgroundColor: context.appColors.brandPrimary.withValues(alpha: 0.6),
          disabledForegroundColor: context.appColors.fgOnBrand,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _busy
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: context.appColors.fgOnBrand,
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
                      color: context.appColors.fgOnBrand,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
