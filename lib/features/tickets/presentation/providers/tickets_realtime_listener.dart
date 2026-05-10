import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/realtime/xano_notification_channel.dart';
import '../../../../core/services/realtime/xano_socket_service.dart';
import '../../../dashboard/presentation/providers/dashboard_counts_controller.dart';
import '../../data/services/ticket_realtime_event_mapper.dart';
import 'my_tickets_notifier.dart';
import 'ticket_detail_api_controller.dart';
import 'tickets_paged_notifier.dart';

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

  // Coalesce bursty socket events into a single counts refetch per ~600ms
  // window so a flurry of ticket transitions doesn't hammer /dashboard/numbers.
  Timer? countsDebounce;
  void scheduleCountsRefresh() {
    countsDebounce?.cancel();
    countsDebounce = Timer(const Duration(milliseconds: 600), () {
      ref.invalidate(dashboardCountsControllerProvider);
    });
  }

  final sub = socket.messageStream.listen(
    (raw) {
      final event = parseTicketRealtimeEvent(raw);
      if (event == null) return;

      final legacy = ref.read(myTicketsNotifierProvider.notifier);
      switch (event) {
        case TicketUpsertEvent(:final ticket):
          legacy.upsertFromRealtime(ticket);
          for (final tab in kAllTicketsTabs) {
            ref
                .read(ticketsPagedProvider(specForTab(tab)).notifier)
                .applyRealtimeUpsert(ticket);
          }
          scheduleCountsRefresh();
          // If the user is viewing this ticket's detail, pull the latest
          // payload so the activity timeline picks up the new transition
          // entry the backend just emitted.
          final openId = ref.read(ticketIdProvider);
          if (openId != null && openId == ticket.id) {
            ref.read(ticketDetailApiControllerProvider.notifier).silentRefresh();
          }
        case TicketDeleteEvent(:final ticketId):
          legacy.removeById(ticketId);
          for (final tab in kAllTicketsTabs) {
            ref
                .read(ticketsPagedProvider(specForTab(tab)).notifier)
                .applyRealtimeDelete(ticketId);
          }
          scheduleCountsRefresh();
      }
    },
    onError: (Object e) {
      debugPrint('[TicketsRealtimeListener] stream error: $e');
    },
  );

  ref.onDispose(() {
    countsDebounce?.cancel();
    sub.cancel();
  });

  if (kDebugMode) {
    debugPrint('[TicketsRealtimeListener] subscribed to socket messages');
  }
});
