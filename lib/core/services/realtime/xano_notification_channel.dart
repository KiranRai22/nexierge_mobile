import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/dashboard/presentation/providers/dashboard_bootstrap_controller.dart';
import '../../../features/notifications/presentation/providers/notification_inbox_controller.dart';
import 'socket_connection_status.dart';
import 'xano_socket_service.dart';

/// Provider that exposes the socket status stream. Public so other features
/// (e.g. reconciliation on reconnect) can react to connection-state changes.
final xanoSocketStatusProvider = StreamProvider<SocketConnectionStatus>((ref) {
  final socketService = ref.watch(xanoSocketServiceProvider);
  return socketService.statusStream;
});

/// Joins the `liveTickets/{hotelId}` channel when socket connects.
/// This channel is used by the tickets realtime listener — it is NOT the
/// hub_notifications channel (that is joined by dashboard_bootstrap_controller).
final xanoNotificationChannelProvider = Provider<void>((ref) {
  final socketService = ref.watch(xanoSocketServiceProvider);
  final statusAsync = ref.watch(xanoSocketStatusProvider);
  final bootstrapAsync = ref.watch(dashboardBootstrapControllerProvider);

  final socketConnected =
      statusAsync.valueOrNull == SocketConnectionStatus.connected;
  final profile = bootstrapAsync.valueOrNull?.userProfile;

  if (socketConnected && profile != null) {
    final hotelId = profile.hotelDetails?.hotel.id ?? '';
    final userId = profile.id;

    if (hotelId.isNotEmpty && userId.isNotEmpty) {
      socketService.joinNotificationChannel(
        hotelId: hotelId,
        userId: userId,
      );
    }
  }
});

/// Subscribes to `hub_notifications/{hotelId}/{hubPresetId}` events and
/// applies them to [notificationInboxControllerProvider].
///
/// Handles:
///   - `notification_read` → marks the notification read locally so the
///     unread dot disappears without a full refetch.
///
/// The channel JOIN itself is performed by `dashboard_bootstrap_controller`
/// right after auth/me, before this provider is even initialised.
final xanoHubNotificationsListenerProvider = Provider<void>((ref) {
  final socket = ref.watch(xanoSocketServiceProvider);

  final sub = socket.messageStream.listen(
    (raw) {
      final decoded = _decodeFrame(raw);
      if (decoded == null) return;

      // Only process hub_notifications channel frames
      final channel = decoded['channel'] as String?;
      if (channel == null || !channel.startsWith('hub_notifications')) return;

      final payload = decoded['payload'];
      if (payload is! Map<String, dynamic>) return;

      final eventAction = payload['event_action'] as String?;

      switch (eventAction) {
        case 'notification_read':
          _handleNotificationRead(ref, payload);

        default:
          // Log unknown event actions in debug for future extension
          if (kDebugMode) {
            debugPrint(
              '[HubNotificationsListener] unhandled event_action: $eventAction',
            );
          }
      }
    },
    onError: (Object e) {
      debugPrint('[HubNotificationsListener] stream error: $e');
    },
  );

  ref.onDispose(sub.cancel);

  if (kDebugMode) {
    debugPrint('[HubNotificationsListener] subscribed to hub_notifications');
  }
});

// ─── Keep legacy logger provider for backward compat ─────────────────────────
// (watched in main.dart — replaced by the listener above but we keep the
//  symbol alive so main.dart doesn't need a change)
final xanoHubNotificationsLoggerProvider = Provider<void>((ref) {
  ref.watch(xanoHubNotificationsListenerProvider);
});

// ─── Handlers ────────────────────────────────────────────────────────────────

void _handleNotificationRead(Ref ref, Map<String, dynamic> payload) {
  final notificationId = payload['notification_event_id'] as String?;
  final readByUserId = payload['read_by_hotel_user_id'] as String?;

  if (notificationId == null || readByUserId == null) return;

  // Only update if this event is for the current user (user-level isolation).
  final profile = ref
      .read(dashboardBootstrapControllerProvider)
      .valueOrNull
      ?.userProfile;
  final currentUserId = profile?.id;

  if (currentUserId == null || readByUserId != currentUserId) return;

  ref
      .read(notificationInboxControllerProvider.notifier)
      .markReadLocally(notificationId);

  if (kDebugMode) {
    debugPrint(
      '[HubNotificationsListener] notification_read applied locally: $notificationId',
    );
  }
}

// ─── Frame decoder ────────────────────────────────────────────────────────────

/// Decodes a raw socket frame (String JSON or already-decoded Map) into a
/// typed map. Returns null for frames we can't use.
Map<String, dynamic>? _decodeFrame(dynamic raw) {
  if (raw == null) return null;
  if (raw is Map<String, dynamic>) return raw;
  if (raw is String) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
  }
  return null;
}
