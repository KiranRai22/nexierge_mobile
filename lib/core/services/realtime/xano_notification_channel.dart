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
///   - `notification_created` → refreshes the inbox and unread count to fetch new notifications.
///   - `notification_read` → refreshes the inbox to sync read state.
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

      final data = payload['data'] as Map<String, dynamic>?;
      if (data == null) return;

      final typeKey = data['type_key'] as String?;

      switch (typeKey) {
        case 'notification_read':
          _handleNotificationRead(ref, payload);

        default:
          // Any other hub_notifications event (ticket_created, sla_overdue, etc.)
          // → refresh the unread count.
          _handleNotificationCreated(ref, payload);
      }
    },
    onError: (Object e) {
      //debugPrint('[HubNotificationsListener] stream error: $e');
    },
  );

  ref.onDispose(sub.cancel);

  if (kDebugMode) {
    //debugPrint('[HubNotificationsListener] subscribed to hub_notifications');
  }
});

// ─── Keep legacy logger provider for backward compat ─────────────────────────
// (watched in main.dart — replaced by the listener above but we keep the
//  symbol alive so main.dart doesn't need a change)
final xanoHubNotificationsLoggerProvider = Provider<void>((ref) {
  ref.watch(xanoHubNotificationsListenerProvider);
});

// ─── Handlers ────────────────────────────────────────────────────────────────

void _handleNotificationCreated(Ref ref, Map<String, dynamic> payload) {
  // Extract the data object which contains the notification details
  final data = payload['data'] as Map<String, dynamic>?;
  if (data == null) return;

  final hotelId = data['hotel_id'] as String?;
  if (hotelId == null) return;

  // Verify this notification is for the current user's hotel.
  // All hub_notifications are scoped to the current user already by the server,
  // so if it arrived on the channel, it's for us.
  final profile = ref
      .read(dashboardBootstrapControllerProvider)
      .valueOrNull
      ?.userProfile;
  final currentHotelId = profile?.hotelDetails?.hotel.id;

  if (currentHotelId == null || hotelId != currentHotelId) return;

  ref
      .read(notificationInboxControllerProvider.notifier)
      .refreshUnreadCount();

  if (kDebugMode) {
    //debugPrint(
    //   '[HubNotificationsListener] notification_created → refresh triggered',
    // );
  }
}

void _handleNotificationRead(Ref ref, Map<String, dynamic> payload) {
  final notificationId = payload['notification_event_id'] as String?;
  final readByUserId = payload['read_by_hotel_user_id'] as String?;

  if (readByUserId == null) return;

  // Only refresh for the current user's reads to avoid unnecessary API calls.
  final profile = ref
      .read(dashboardBootstrapControllerProvider)
      .valueOrNull
      ?.userProfile;
  final currentUserId = profile?.id;

  if (currentUserId == null || readByUserId != currentUserId) return;

  ref
      .read(notificationInboxControllerProvider.notifier)
      .refresh();

  if (kDebugMode) {
    //debugPrint(
    //   '[HubNotificationsListener] notification_read → refresh triggered for: $notificationId',
    // );
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
