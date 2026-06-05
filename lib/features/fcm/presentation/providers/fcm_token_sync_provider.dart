import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/device_token_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../auth/presentation/providers/auth_session_controller.dart';
import '../../data/repositories/fcm_repository.dart';

/// Listens to Firebase token-refresh events while the user is authenticated
/// and updates the backend via POST /fcm_token/edit (remove: false).
///
/// Wire up with `ref.watch(fcmTokenSyncProvider)` in MyApp so it stays
/// active for the lifetime of the app. It is a no-op when the user is
/// logged out — the auth check prevents spurious unauthenticated calls.
final fcmTokenSyncProvider = Provider<void>((ref) {
  final session = ref.watch(authSessionControllerProvider).valueOrNull;
  if (session == null) return;

  final repo = ref.read(fcmRepositoryProvider);

  final sub = NotificationService.instance.onTokenRefresh.listen((newToken) async {
    await DeviceTokenService.saveToken(newToken);
    try {
      await repo.edit(fcmToken: newToken, remove: false);
    } catch (_) {
      // Best-effort: token will re-sync on next login if this fails.
    }
  });

  ref.onDispose(sub.cancel);
});
