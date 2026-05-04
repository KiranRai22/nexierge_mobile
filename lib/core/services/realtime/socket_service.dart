import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import 'socket_connection_status.dart';

/// Realtime socket abstraction. Connection-only at this stage —
/// per-feature event subscriptions (tickets etc.) will plug in later.
abstract class SocketService {
  Stream<SocketConnectionStatus> get statusStream;
  SocketConnectionStatus get status;
  bool get isConnected;

  Future<void> connect(String authToken);
  Future<void> disconnect();
  Future<void> dispose();

  /// Log current socket details to console for debugging
  void logSocketDetails();
}

class _SocketServiceImpl implements SocketService {
  static const _baseUrl = 'wss://xvmf-wx0g-xvlj.b2.xano.io';
  static const _channel = 'N5xe92RieNtfawyeIyRYpyPtVSY';

  io.Socket? _socket;
  String? _token;

  final StreamController<SocketConnectionStatus> _statusCtrl =
      StreamController<SocketConnectionStatus>.broadcast();
  SocketConnectionStatus _status = SocketConnectionStatus.idle;

  @override
  Stream<SocketConnectionStatus> get statusStream => _statusCtrl.stream;

  @override
  SocketConnectionStatus get status => _status;

  @override
  bool get isConnected => _socket?.connected ?? false;

  @override
  Future<void> connect(String authToken) async {
    debugPrint('[Socket] connect() called');
    debugPrint('[Socket] baseUrl: $_baseUrl');
    debugPrint('[Socket] channel: $_channel');
    debugPrint(
      '[Socket] token: ${authToken.substring(0, authToken.length > 20 ? 20 : authToken.length)}...',
    );

    if (_socket != null && _token == authToken) {
      debugPrint('[Socket] Same token, reusing socket. connected=$isConnected');
      // Same token — keep existing socket. Force a reconnect if dropped.
      if (!isConnected) {
        debugPrint('[Socket] Socket not connected, calling connect()');
        _socket!.connect();
      }
      return;
    }

    // Token rotated → tear down before opening a new handshake.
    if (_socket != null) {
      debugPrint('[Socket] Token rotated, disconnecting old socket');
      await disconnect();
    }

    _token = authToken;
    _emit(SocketConnectionStatus.connecting);

    final opts = io.OptionBuilder()
        .setTransports(['websocket', 'polling'])
        .disableAutoConnect()
        .enableReconnection()
        .setReconnectionAttempts(1 << 30)
        .setReconnectionDelay(2000)
        .setReconnectionDelayMax(10000)
        .setRandomizationFactor(0.5)
        .setTimeout(15000)
        // Xano realtime: channel in path, auth via Sec-WebSocket-Protocol header
        // Note: setExtraHeaders has limited support in WebSocket transport
        .setPath('/rt/$_channel')
        .setExtraHeaders({'Sec-WebSocket-Protocol': authToken})
        .setAuth({'token': authToken})
        .setQuery({'token': authToken})
        .build();

    debugPrint('[Socket] Creating socket with path: /rt/$_channel');
    debugPrint(
      '[Socket] Extra headers: {Sec-WebSocket-Protocol: ${authToken.substring(0, 20)}...}',
    );
    final socket = io.io(_baseUrl, opts);
    debugPrint('[Socket] Socket instance created: ${socket.hashCode}');
    debugPrint(
      '[Socket] Socket opts: transports=${(opts['transports'] as List).join(',')}',
    );

    socket.onConnect((_) {
      _emit(SocketConnectionStatus.connected);
      debugPrint('[Socket] CONNECTED - socket.id: ${socket.id}');
      debugPrint('[Socket] CONNECTED - connected: ${socket.connected}');
      debugPrint('[Socket] CONNECTED - disconnected: ${socket.disconnected}');
    });

    socket.onDisconnect((reason) {
      _emit(SocketConnectionStatus.disconnected);
      debugPrint('[Socket] DISCONNECTED - reason: $reason');
      debugPrint('[Socket] DISCONNECTED - socket.id: ${socket.id}');
    });

    socket.onConnectError((err) {
      _emit(SocketConnectionStatus.error);
      debugPrint('[Socket] CONNECT_ERROR: $err');
      debugPrint('[Socket] CONNECT_ERROR - socket.id: ${socket.id}');
    });

    socket.onError((err) {
      _emit(SocketConnectionStatus.error);
      debugPrint('[Socket] ERROR: $err');
    });

    socket.onReconnectAttempt((n) {
      _emit(SocketConnectionStatus.reconnecting);
      debugPrint('[Socket] RECONNECT_ATTEMPT #$n');
    });

    socket.onReconnect((_) {
      _emit(SocketConnectionStatus.connected);
      debugPrint('[Socket] RECONNECTED - socket.id: ${socket.id}');
    });

    socket.onReconnectFailed((_) {
      _emit(SocketConnectionStatus.error);
      debugPrint('[Socket] RECONNECT_FAILED');
    });

    _socket = socket;
    debugPrint('[Socket] Calling socket.connect()...');
    debugPrint(
      '[Socket] Full URL: $_baseUrl/rt/$_channel?token=${authToken.substring(0, 10)}...',
    );
    socket.connect();
    debugPrint('[Socket] connect() called, active: ${socket.active}');

    // Add timeout check for initial connection
    Future.delayed(const Duration(seconds: 5), () {
      if (_socket == socket && !socket.connected) {
        debugPrint('[Socket] WARNING: Still not connected after 5 seconds');
        debugPrint(
          '[Socket] Socket state - active: ${socket.active}, id: ${socket.id}',
        );
      }
    });
  }

  @override
  Future<void> disconnect() async {
    debugPrint('[Socket] disconnect() called');
    final s = _socket;
    if (s == null) {
      debugPrint('[Socket] disconnect() - no socket to disconnect');
      return;
    }
    debugPrint('[Socket] disconnect() - socket.id: ${s.id}');
    debugPrint('[Socket] disconnect() - connected: ${s.connected}');
    s.clearListeners();
    s.disconnect();
    s.dispose();
    _socket = null;
    _token = null;
    _emit(SocketConnectionStatus.idle);
  }

  @override
  Future<void> dispose() async {
    debugPrint('[Socket] dispose() called');
    await disconnect();
    await _statusCtrl.close();
  }

  @override
  void logSocketDetails() {
    debugPrint('========== SOCKET DETAILS ==========');
    debugPrint('[Socket] baseUrl: $_baseUrl');
    debugPrint('[Socket] channel: $_channel');
    debugPrint('[Socket] full path: /rt/$_channel');
    debugPrint('[Socket] status: $_status');
    debugPrint('[Socket] has token: ${_token != null}');
    if (_token != null) {
      debugPrint('[Socket] token length: ${_token!.length}');
      debugPrint(
        '[Socket] token preview: ${_token!.substring(0, _token!.length > 30 ? 30 : _token!.length)}...',
      );
    }
    final s = _socket;
    if (s != null) {
      debugPrint('[Socket] socket instance: ${s.hashCode}');
      debugPrint('[Socket] socket.id: ${s.id}');
      debugPrint('[Socket] connected: ${s.connected}');
      debugPrint('[Socket] disconnected: ${s.disconnected}');
      debugPrint('[Socket] active: ${s.active}');
      debugPrint('[Socket] nsp: ${s.nsp}');
      debugPrint('[Socket] io.opts: ${s.io.options}');
    } else {
      debugPrint('[Socket] socket instance: null');
    }
    debugPrint('====================================');
  }

  void _emit(SocketConnectionStatus next) {
    _status = next;
    if (!_statusCtrl.isClosed) _statusCtrl.add(next);
  }
}

final socketServiceProvider = Provider<SocketService>((ref) {
  final service = _SocketServiceImpl();
  ref.onDispose(service.dispose);
  return service;
});
