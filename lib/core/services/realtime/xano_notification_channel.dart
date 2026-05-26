import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/dashboard/presentation/providers/dashboard_bootstrap_controller.dart';
import 'socket_connection_status.dart';
import 'xano_socket_service.dart';

/// Provider that exposes the socket status stream. Public so other features
/// (e.g. reconciliation on reconnect) can react to connection-state changes.
final xanoSocketStatusProvider = StreamProvider<SocketConnectionStatus>((ref) {
  final socketService = ref.watch(xanoSocketServiceProvider);
  return socketService.statusStream;
});

/// Automatically joins the notifications channel when socket connects and profile is available.
/// Uses hotel_id and user_id from dashboard bootstrap.
final xanoNotificationChannelProvider = Provider<void>((ref) {
  final socketService = ref.watch(xanoSocketServiceProvider);

  // Watch the socket status stream
  final statusAsync = ref.watch(xanoSocketStatusProvider);

  // Watch the bootstrap state to get profile availability
  final bootstrapAsync = ref.watch(dashboardBootstrapControllerProvider);

  // Check both socket connection and profile availability
  final socketConnected =
      statusAsync.valueOrNull == SocketConnectionStatus.connected;
  final profile = bootstrapAsync.valueOrNull?.userProfile;

  if (socketConnected && profile != null) {
    final hotelId = profile.hotelDetails.hotel.id;
    final userId = profile.id;

    if (hotelId.isNotEmpty && userId.isNotEmpty) {
      debugPrint(
        '[XanoNotificationChannel] Socket connected and profile available, joining channel',
      );
      debugPrint(
        '[XanoNotificationChannel] hotelId: $hotelId, userId: $userId',
      );
      socketService.joinNotificationChannel(hotelId: hotelId, userId: userId);
    } else {
      debugPrint(
        '[XanoNotificationChannel] Cannot join: empty hotelId or userId',
      );
    }
  } else if (socketConnected && profile == null) {
    debugPrint(
      '[XanoNotificationChannel] Socket connected but profile not available, waiting...',
    );
  }

  if (kDebugMode) {
    debugPrint(
      '[XanoNotificationChannel] Provider initialized, waiting for socket connection and profile',
    );
  }
});

/// Subscribes to the socket message stream and logs every frame that arrives
/// on the `hub_notifications` channel. Watch this once at the app root
/// alongside [xanoHubNotificationsChannelProvider].
final xanoHubNotificationsLoggerProvider = Provider<void>((ref) {
  final socket = ref.watch(xanoSocketServiceProvider);

  final sub = socket.messageStream.listen(
    (raw) {
      if (!kDebugMode) return;
      final msg = raw?.toString() ?? '';
      if (msg.contains('hub_notifications')) {
        debugPrint('[XanoHubNotificationsChannel] Event received: $msg');
      }
    },
    onError: (Object e) {
      debugPrint('[XanoHubNotificationsChannel] Stream error: $e');
    },
  );

  ref.onDispose(sub.cancel);

  if (kDebugMode) {
    debugPrint('[XanoHubNotificationsChannel] Logger subscribed to socket messages');
  }
});
