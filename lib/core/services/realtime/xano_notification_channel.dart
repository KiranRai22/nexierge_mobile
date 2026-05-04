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

/// Automatically joins the notifications channel when socket connects.
/// Uses hotel_id and user_id from dashboard bootstrap.
final xanoNotificationChannelProvider = Provider<void>((ref) {
  final socketService = ref.watch(xanoSocketServiceProvider);

  // Watch the socket status stream
  final statusAsync = ref.watch(_xanoSocketStatusProvider);

  statusAsync.whenData((status) {
    if (status == SocketConnectionStatus.connected) {
      // Socket just connected, join the notification channel
      final bootstrap = ref
          .read(dashboardBootstrapControllerProvider)
          .valueOrNull;
      final userProfile = bootstrap?.userProfile;

      if (userProfile != null) {
        final hotelId = userProfile.hotelDetails.hotel.id;
        final userId = userProfile.id;

        if (hotelId.isNotEmpty && userId.isNotEmpty) {
          debugPrint(
            '[XanoNotificationChannel] Socket connected, joining channel',
          );
          debugPrint(
            '[XanoNotificationChannel] hotelId: $hotelId, userId: $userId',
          );
          socketService.joinNotificationChannel(
            hotelId: hotelId,
            userId: userId,
          );
        } else {
          debugPrint(
            '[XanoNotificationChannel] Cannot join: empty hotelId or userId',
          );
        }
      } else {
        debugPrint(
          '[XanoNotificationChannel] Cannot join: userProfile not available',
        );
      }
    }
  });

  if (kDebugMode) {
    debugPrint(
      '[XanoNotificationChannel] Provider initialized, waiting for socket connection',
    );
  }
});
