import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dart:async';

import '../../../features/dashboard/presentation/providers/dashboard_bootstrap_controller.dart';
import '../../../features/dashboard/presentation/providers/dashboard_counts_controller.dart';
import '../../../features/notifications/presentation/providers/notification_inbox_controller.dart';
import '../../../features/tickets/presentation/providers/tickets_main_tab_provider.dart';
import '../../../features/tickets/presentation/providers/tickets_paged_notifier.dart';
import '../../../features/tickets/presentation/widgets/tickets_main_tabs.dart';
import 'socket_connection_status.dart';
import 'xano_socket_service.dart';

/// Provider that exposes the socket status stream. Public so other features
/// (e.g. reconciliation on reconnect) can react to connection-state changes.
final xanoSocketStatusProvider = StreamProvider<SocketConnectionStatus>((ref) {
  final socketService = ref.watch(xanoSocketServiceProvider);
  return socketService.statusStream;
});

/// Maps the user's currently-selected main tab to the set of paged tab(s)
/// that back its on-screen list. Used by the hub-notifications listener to
/// decide which paged providers must refresh eagerly vs be marked stale.
///
/// Today (In Progress) actually overlays IN_PROGRESS + OVERDUE on the same
/// screen via a client-side sub-filter, so realtime events targeting either
/// shape must refresh both backing providers for the visible counts to stay
/// accurate.
Set<TicketsTab> _visiblePagedTabsFor(TicketsMainTab mainTab) {
  switch (mainTab) {
    case TicketsMainTab.incoming:
      return {TicketsTab.incoming};
    case TicketsMainTab.today:
      return {TicketsTab.todayInProgress, TicketsTab.overdue};
    case TicketsMainTab.backlog:
      return {TicketsTab.backlog};
    case TicketsMainTab.done:
      return {TicketsTab.todayDone};
  }
}

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
    final hotelId = profile.hotelDetails.hotel.id;
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

  // All five paged tabs the user can land on.
  const allTabs = <TicketsTab>[
    TicketsTab.incoming,
    TicketsTab.todayInProgress,
    TicketsTab.overdue,
    TicketsTab.todayDone,
    TicketsTab.backlog,
  ];

  // Debounce realtime-driven refreshes so a burst of hub events collapses
  // into a single per-tab refresh.
  Timer? ticketsRefreshDebounce;
  void scheduleTicketsRefresh() {
    ticketsRefreshDebounce?.cancel();
    ticketsRefreshDebounce = Timer(const Duration(milliseconds: 600), () {
      // Resolve the user's currently-visible main tab. We only eagerly
      // refresh the paged provider(s) backing that tab — the other tabs
      // are marked stale so they refetch when (and only when) the user
      // navigates to them via the existing `refreshIfStale` tab-switch
      // hook. This replaces the previous fan-out that refreshed all five
      // tabs on every event regardless of visibility.
      final mainTab = ref.read(ticketsMainTabProvider);
      final visibleTabs = _visiblePagedTabsFor(mainTab);

      for (final tab in allTabs) {
        final notifier = ref.read(
          ticketsPagedProvider(specForTab(tab)).notifier,
        );
        if (visibleTabs.contains(tab)) {
          // ignore: discarded_futures
          notifier.refresh();
        } else {
          notifier.markStale();
        }
      }
      // Counts are visible on the tab bar regardless of which tab is open,
      // so they always refresh.
      ref.invalidate(dashboardCountsControllerProvider);
    });
  }

  final sub = socket.messageStream.listen(
    (raw) {
      final decoded = _decodeFrame(raw);
      if (decoded == null) return;

      // Channel lives at `options.channel` in Xano frames; tolerate legacy
      // top-level `channel` too.
      final channel =
          ((decoded['options'] as Map<String, dynamic>?)?['channel']
                  as String?) ??
              (decoded['channel'] as String?);
      if (channel == null || !channel.startsWith('hub_notifications')) return;

      final action = decoded['action'] as String?;
      // Refresh all ticket tabs on every `action: event` frame on the hub
      // channel (skip presence_update, join acks, etc.).
      if (action == 'event') {
        scheduleTicketsRefresh();
      }

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

  ref.onDispose(() {
    ticketsRefreshDebounce?.cancel();
    sub.cancel();
  });

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
  // All hub_notifications are scoped to this user/hotel by the server —
  // if this frame arrived on our channel, it is meant for us.
  ref
      .read(notificationInboxControllerProvider.notifier)
      .refreshUnreadCount();
}

void _handleNotificationRead(Ref ref, Map<String, dynamic> payload) {
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
