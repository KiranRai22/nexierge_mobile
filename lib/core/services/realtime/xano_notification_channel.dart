import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/dashboard/presentation/providers/dashboard_bootstrap_controller.dart';
import 'socket_connection_status.dart';
import 'xano_socket_service.dart';

/// Provider that exposes the socket status stream
final _xanoSocketStatusProvider = StreamProvider<SocketConnectionStatus>((ref) {
  final socketService = ref.watch(xanoSocketServiceProvider);
  return socketService.statusStream;
});

/// Automatically joins the notifications channel when socket connects and profile is available.
/// Uses hotel_id and user_id from dashboard bootstrap.
final xanoNotificationChannelProvider = Provider<void>((ref) {
  final socketService = ref.watch(xanoSocketServiceProvider);

  // Watch the socket status stream
  final statusAsync = ref.watch(_xanoSocketStatusProvider);

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
