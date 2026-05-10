import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/realtime/socket_connection_status.dart';
import '../../../../core/services/realtime/xano_notification_channel.dart';
import '../../../dashboard/presentation/providers/dashboard_counts_controller.dart';
import 'my_tickets_notifier.dart';

/// Reconciliation layer for ticket state. Realtime socket frames are
/// best-effort — events can be lost while disconnected, while the app is
/// backgrounded, or during a channel-join race. This provider watches for
/// those moments and refetches the full state so missed events surface
/// within seconds without requiring user interaction.
///
/// Triggers a refresh whenever:
///   - the socket transitions from any non-connected state to `connected`
///     (initial connect, reconnect after a drop), OR
///   - the app lifecycle goes from background → resumed.
///
/// Refresh = `myTicketsNotifierProvider.refresh()` (which itself refetches
/// every paged tab) plus an invalidate on `dashboardCountsControllerProvider`.
/// Both keep previous data visible during the reload, so the UI never flashes
/// empty.
///
/// Watch this provider once in the shell so it's alive for the whole logged-in
/// session. The `refresh()` call is a no-op when nothing changed on the server,
/// so the cost is one round-trip per reconnect/resume event — cheap.
final ticketsReconcileProvider = Provider<void>((ref) {
  final observer = _ResumeObserver(() => _reconcile(ref, reason: 'resume'));
  WidgetsBinding.instance.addObserver(observer);

  ref.listen<AsyncValue<SocketConnectionStatus>>(
    xanoSocketStatusProvider,
    (prev, next) {
      final prevStatus = prev?.valueOrNull;
      final nextStatus = next.valueOrNull;
      // Only fire on a true reconnect: previously had a non-connected status
      // and now connected. Skip the initial null→connected transition since
      // the bootstrap fetch already covers cold start.
      if (prevStatus != null &&
          prevStatus != SocketConnectionStatus.connected &&
          nextStatus == SocketConnectionStatus.connected) {
        _reconcile(ref, reason: 'socket_reconnect');
      }
    },
  );

  ref.onDispose(() {
    WidgetsBinding.instance.removeObserver(observer);
  });

  if (kDebugMode) {
    debugPrint('[TicketsReconcile] armed (socket-reconnect + app-resume)');
  }
});

void _reconcile(Ref ref, {required String reason}) {
  if (kDebugMode) debugPrint('[TicketsReconcile] reason=$reason → refresh');
  // Refetch the legacy notifier (it also refetches every paged tab) and
  // invalidate the dashboard counts so the next read pulls /dashboard/numbers.
  ref.read(myTicketsNotifierProvider.notifier).refresh();
  ref.invalidate(dashboardCountsControllerProvider);
}

class _ResumeObserver extends WidgetsBindingObserver {
  _ResumeObserver(this.onResume);

  final VoidCallback onResume;
  AppLifecycleState? _last;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final prev = _last;
    _last = state;
    // Only fire on a genuine background → foreground transition, not on the
    // first lifecycle callback (which is `resumed` at startup but already
    // covered by the initial fetch).
    if (state == AppLifecycleState.resumed &&
        prev != null &&
        prev != AppLifecycleState.resumed) {
      onResume();
    }
  }
}
