import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/presentation/providers/auth_session_controller.dart';
import 'xano_socket_service.dart';

/// Binds the Xano realtime socket lifecycle to the auth session.
///
/// - Token present → connect (idempotent on token rotation).
/// - Session cleared → disconnect.
///
/// Watch this provider once near the app root so the binding is alive
/// for the whole session. Reconnect on transport drops is handled by
/// the underlying WebSocketChannel (see `xano_socket_service.dart`).
final xanoSocketLifecycleProvider = Provider<void>((ref) {
  final service = ref.watch(xanoSocketServiceProvider);

  ref.listen(
    authSessionControllerProvider,
    (_, next) {
      final token = next.valueOrNull?.authToken;
      if (token != null && token.isNotEmpty) {
        service.connect(token);
      } else {
        service.disconnect();
      }
    },
    fireImmediately: true,
  );

  if (kDebugMode) debugPrint('[XanoSocket] lifecycle bound to auth session');
});
