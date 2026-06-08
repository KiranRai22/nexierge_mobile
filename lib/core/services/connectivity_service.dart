import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ConnectivityStatus { online, offline }

/// Continuously monitors device connectivity.
///
/// Combines two signals:
/// 1. `connectivity_plus` interface change events (wifi/cellular/none).
/// 2. An active DNS lookup probe — interface "connected" does not guarantee
///    real internet (captive portals, no upstream, airplane wifi, etc.).
///
/// Re-probes on every interface change AND on a periodic timer so we catch
/// upstream outages while the interface stays up.
///
/// **Cold-start behaviour:** the very first DNS lookup after launch often
/// fails because the OS network stack hasn't finished bringing the
/// interface up. To avoid the "No Internet" dialog flashing for ~5 s on
/// every cold start, we:
/// 1. Emit an *optimistic* `online` immediately if the interface reports
///    wifi/cellular — without waiting for the DNS probe.
/// 2. Require [_offlineConfirmationStreak] consecutive failed probes
///    before emitting `offline`, so a single transient DNS hiccup doesn't
///    trip the dialog.
class ConnectivityService {
  ConnectivityService({Connectivity? connectivity, Duration? pollInterval})
      : _connectivity = connectivity ?? Connectivity(),
        _pollInterval = pollInterval ?? const Duration(seconds: 10);

  final Connectivity _connectivity;
  final Duration _pollInterval;

  /// Number of consecutive failed probes required before we declare the
  /// device offline. Two ≈ ~10 s of sustained failure with the default
  /// poll interval — long enough to absorb cold-start DNS flakiness,
  /// short enough that a real outage still surfaces quickly.
  static const int _offlineConfirmationStreak = 2;

  final _controller = StreamController<ConnectivityStatus>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _interfaceSub;
  Timer? _pollTimer;
  ConnectivityStatus? _last;
  int _offlineStreak = 0;

  Stream<ConnectivityStatus> get stream => _controller.stream;

  Future<void> start() async {
    _interfaceSub = _connectivity.onConnectivityChanged.listen(
      (_) => _probeAndEmit(),
      onError: (_) {},
    );
    _pollTimer = Timer.periodic(_pollInterval, (_) => _probeAndEmit());

    // Optimistic initial state: if the OS reports a usable interface,
    // emit `online` straight away so the UI doesn't render an offline
    // dialog while the first DNS probe is still in flight. The probe
    // runs in the background and will correct the state if it actually
    // fails [_offlineConfirmationStreak] times in a row.
    final hasInterface = await _hasInterface();
    if (hasInterface) {
      _last = ConnectivityStatus.online;
      _controller.add(ConnectivityStatus.online);
    }
    unawaited(_probeAndEmit());
  }

  Future<void> _probeAndEmit() async {
    final probed = await _check();
    if (probed == ConnectivityStatus.online) {
      _offlineStreak = 0;
      if (_last != ConnectivityStatus.online) {
        _last = ConnectivityStatus.online;
        _controller.add(ConnectivityStatus.online);
      }
      return;
    }
    // probed == offline — only act once we've confirmed it.
    _offlineStreak++;
    if (_offlineStreak < _offlineConfirmationStreak) return;
    if (_last != ConnectivityStatus.offline) {
      _last = ConnectivityStatus.offline;
      _controller.add(ConnectivityStatus.offline);
    }
  }

  Future<bool> _hasInterface() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.any((r) => r != ConnectivityResult.none);
    } catch (_) {
      // Native plugin not registered yet (cold-start race) — assume yes
      // and let the DNS probe be the authority.
      return true;
    }
  }

  Future<ConnectivityStatus> _check() async {
    if (!await _hasInterface()) return ConnectivityStatus.offline;
    try {
      final lookup = await InternetAddress.lookup('one.one.one.one')
          .timeout(const Duration(seconds: 4));
      final reachable =
          lookup.isNotEmpty && lookup.first.rawAddress.isNotEmpty;
      return reachable ? ConnectivityStatus.online : ConnectivityStatus.offline;
    } catch (_) {
      return ConnectivityStatus.offline;
    }
  }

  Future<void> dispose() async {
    await _interfaceSub?.cancel();
    _pollTimer?.cancel();
    await _controller.close();
  }
}

/// Long-lived service. Started once at app boot via [connectivityStatusProvider].
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  ref.onDispose(service.dispose);
  return service;
});

/// Emits the current connectivity status. Watch this anywhere to react to
/// the device going on/offline. Stream stays alive for the app's lifetime.
final connectivityStatusProvider = StreamProvider<ConnectivityStatus>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  // Fire-and-forget: start() awaits an initial probe but the stream will
  // emit the first value as soon as the probe lands.
  service.start();
  return service.stream;
});
