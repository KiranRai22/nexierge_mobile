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
class ConnectivityService {
  ConnectivityService({Connectivity? connectivity, Duration? pollInterval})
      : _connectivity = connectivity ?? Connectivity(),
        _pollInterval = pollInterval ?? const Duration(seconds: 10);

  final Connectivity _connectivity;
  final Duration _pollInterval;

  final _controller = StreamController<ConnectivityStatus>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _interfaceSub;
  Timer? _pollTimer;
  ConnectivityStatus? _last;

  Stream<ConnectivityStatus> get stream => _controller.stream;

  Future<void> start() async {
    _interfaceSub = _connectivity.onConnectivityChanged.listen(
      (_) => _probeAndEmit(),
      onError: (_) {},
    );
    _pollTimer = Timer.periodic(_pollInterval, (_) => _probeAndEmit());
    await _probeAndEmit();
  }

  Future<void> _probeAndEmit() async {
    final next = await _check();
    if (next == _last) return;
    _last = next;
    _controller.add(next);
  }

  Future<ConnectivityStatus> _check() async {
    // If the native plugin isn't registered yet (cold-start race, or a
    // hot-restart after adding the dep before a full rebuild) treat the
    // interface as "present" and fall through to the DNS probe — that's
    // the authoritative signal anyway.
    bool hasInterface = true;
    try {
      final results = await _connectivity.checkConnectivity();
      hasInterface = results.any((r) => r != ConnectivityResult.none);
    } catch (_) {
      hasInterface = true;
    }
    if (!hasInterface) return ConnectivityStatus.offline;
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
