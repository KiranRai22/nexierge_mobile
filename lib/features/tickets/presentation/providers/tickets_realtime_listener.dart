import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/realtime/xano_notification_channel.dart';
import '../../../../core/services/realtime/xano_socket_service.dart';
import '../../data/services/ticket_realtime_event_mapper.dart';
import 'my_tickets_notifier.dart';

/// Subscribes to the Xano realtime socket and feeds ticket events into
/// [myTicketsNotifierProvider]. Watch this once at the app shell so the
/// subscription is alive for the whole logged-in session.
///
/// Lifecycle:
///   - Socket connect/disconnect is handled by `xano_socket_lifecycle`.
///   - Channel join is handled by `xanoNotificationChannelProvider`.
///   - This listener is the consumer that turns raw frames into Riverpod
///     state mutations.
final ticketsRealtimeListenerProvider = Provider<void>((ref) {
  // Ensure the channel-join provider is alive — joining `liveTickets/{hotelId}`
  // is what triggers the server to start pushing ticket events.
  ref.watch(xanoNotificationChannelProvider);

  final socket = ref.watch(xanoSocketServiceProvider);

  final sub = socket.messageStream.listen(
    (raw) {
      final event = parseTicketRealtimeEvent(raw);
      if (event == null) return;

      final notifier = ref.read(myTicketsNotifierProvider.notifier);
      switch (event) {
        case TicketUpsertEvent(:final ticket):
          notifier.upsertFromRealtime(ticket);
        case TicketDeleteEvent(:final ticketId):
          notifier.removeById(ticketId);
      }
    },
    onError: (Object e) {
      debugPrint('[TicketsRealtimeListener] stream error: $e');
    },
  );

  ref.onDispose(sub.cancel);

  if (kDebugMode) {
    debugPrint('[TicketsRealtimeListener] subscribed to socket messages');
  }
});
