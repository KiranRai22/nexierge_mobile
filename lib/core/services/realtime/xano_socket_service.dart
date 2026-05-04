import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/io.dart';

import 'socket_connection_status.dart';

/// Plain WebSocket service for Xano Realtime (not Socket.IO).
/// Xano uses raw WebSocket with Sec-WebSocket-Protocol auth.
abstract class XanoSocketService {
  Stream<SocketConnectionStatus> get statusStream;
  SocketConnectionStatus get status;
  bool get isConnected;
  Stream<dynamic> get messageStream;

  Future<void> connect(String authToken);
  Future<void> disconnect();
  Future<void> dispose();
  void logSocketDetails();

  /// Send a message to the WebSocket
  void sendMessage(Map<String, dynamic> message);

  /// Join the notifications channel for a specific hotel and user
  void joinNotificationChannel({
    required String hotelId,
    required String userId,
  });
}

class _XanoSocketServiceImpl implements XanoSocketService {
  static const _host = 'xvmf-wx0g-xvlj.b2.xano.io';
  static const _port = 443;
  static const _channelId = 'N5xe92RieNtfawyeIyRYpyPtVSY';

  IOWebSocketChannel? _socketChannel;
  String? _token;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const _maxReconnectDelay = 10; // seconds

  final StreamController<SocketConnectionStatus> _statusCtrl =
      StreamController<SocketConnectionStatus>.broadcast();
  SocketConnectionStatus _status = SocketConnectionStatus.idle;

  /// Broadcast fan-out for incoming WS frames. The underlying
  /// `IOWebSocketChannel.stream` is single-subscription, so we listen to it
  /// once internally and republish to a broadcast controller. Multiple
  /// providers (e.g. realtime ticket listener, debug logger) can then
  /// subscribe without stealing each other's events.
  final StreamController<dynamic> _messageCtrl =
      StreamController<dynamic>.broadcast();

  @override
  Stream<SocketConnectionStatus> get statusStream => _statusCtrl.stream;

  @override
  SocketConnectionStatus get status => _status;

  @override
  bool get isConnected => _socketChannel != null;

  @override
  Future<void> connect(String authToken) async {
    debugPrint('[XanoSocket] connect() called');
    debugPrint('[XanoSocket] host: $_host');
    debugPrint('[XanoSocket] channel: $_channelId');
    debugPrint('[XanoSocket] token: ${authToken.substring(0, 20)}...');

    if (_token == authToken && isConnected) {
      debugPrint('[XanoSocket] Already connected with same token');
      return;
    }

    if (_socketChannel != null) {
      debugPrint('[XanoSocket] Disconnecting old connection');
      await disconnect();
    }

    _token = authToken;
    _reconnectAttempts = 0;
    await _doConnect(authToken);
  }

  Future<void> _doConnect(String authToken) async {
    _emit(SocketConnectionStatus.connecting);
    debugPrint('[XanoSocket] Connecting to https://$_host/rt/$_channelId');
    debugPrint('[XanoSocket] With Sec-WebSocket-Protocol header');

    try {
      // Use HttpClient with proper WebSocket upgrade handling
      final client = HttpClient();
      client.badCertificateCallback = (cert, host, port) => true;

      // Build the WebSocket handshake request
      final key = _generateWebSocketKey();
      final url = Uri.parse('https://$_host/rt/$_channelId');

      debugPrint('[XanoSocket] Opening connection to $url');
      final request = await client.openUrl('GET', url);

      // Add WebSocket upgrade headers
      request.headers
        ..add('Upgrade', 'websocket')
        ..add('Connection', 'Upgrade')
        ..add('Sec-WebSocket-Key', key)
        ..add('Sec-WebSocket-Version', '13')
        ..add('Sec-WebSocket-Protocol', authToken);

      debugPrint('[XanoSocket] Sending upgrade request...');
      final response = await request.close();

      debugPrint('[XanoSocket] Response status: ${response.statusCode}');

      if (response.statusCode != 101) {
        throw Exception('WebSocket upgrade failed: ${response.statusCode}');
      }

      // Detach the socket for WebSocket use
      final socket = await response.detachSocket();

      debugPrint('[XanoSocket] Socket detached, creating WebSocket...');

      // Create WebSocket from the upgraded socket
      final webSocket = WebSocket.fromUpgradedSocket(
        socket,
        protocol: 'ws',
        serverSide: false,
      );

      _socketChannel = IOWebSocketChannel(webSocket);
      _emit(SocketConnectionStatus.connected);
      debugPrint('[XanoSocket] CONNECTED with header auth');
      _reconnectAttempts = 0;

      // Single internal subscription that fans out to the broadcast
      // controller exposed via `messageStream`. Debug logging is now just
      // another consumer downstream.
      _socketChannel!.stream.listen(
        (message) {
          if (kDebugMode) debugPrint('[XanoSocket] Received: $message');
          if (!_messageCtrl.isClosed) _messageCtrl.add(message);
        },
        onError: (error) {
          debugPrint('[XanoSocket] Stream error: $error');
          _emit(SocketConnectionStatus.error);
          _scheduleReconnect();
        },
        onDone: () {
          debugPrint('[XanoSocket] Connection closed');
          _emit(SocketConnectionStatus.disconnected);
          _scheduleReconnect();
        },
      );

      // Notify that connection is ready for channel joins
      debugPrint(
        '[XanoSocket] Socket ready, waiting for channel join requests',
      );
    } catch (e, st) {
      debugPrint('[XanoSocket] Connection failed: $e');
      debugPrint('[XanoSocket] Stack trace: $st');
      _emit(SocketConnectionStatus.error);
      _scheduleReconnect();
    }
  }

  /// Generate a random WebSocket key for handshake
  String _generateWebSocketKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64.encode(bytes);
  }

  void _scheduleReconnect() {
    if (_token == null) return;
    if (_reconnectAttempts > 100) return;

    _reconnectAttempts++;
    final delay = Duration(
      seconds: _reconnectAttempts.clamp(1, _maxReconnectDelay),
    );
    debugPrint(
      '[XanoSocket] Reconnect attempt #$_reconnectAttempts in ${delay.inSeconds}s',
    );

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      if (_token != null) {
        _doConnect(_token!);
      }
    });
  }

  @override
  Future<void> disconnect() async {
    debugPrint('[XanoSocket] disconnect() called');
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    if (_socketChannel != null) {
      debugPrint('[XanoSocket] Closing channel');
      await _socketChannel!.sink.close();
      _socketChannel = null;
    }
    _token = null;
    _reconnectAttempts = 0;
    _emit(SocketConnectionStatus.idle);
  }

  @override
  Future<void> dispose() async {
    debugPrint('[XanoSocket] dispose() called');
    await disconnect();
    await _statusCtrl.close();
    if (!_messageCtrl.isClosed) await _messageCtrl.close();
  }

  @override
  void logSocketDetails() {
    debugPrint('========== XANO SOCKET DETAILS ==========');
    debugPrint('[XanoSocket] host: $_host:$_port');
    debugPrint('[XanoSocket] channel: $_channelId');
    debugPrint('[XanoSocket] status: $_status');
    debugPrint('[XanoSocket] has token: ${_token != null}');
    if (_token != null) {
      debugPrint('[XanoSocket] token length: ${_token!.length}');
      debugPrint(
        '[XanoSocket] token preview: ${_token!.substring(0, _token!.length > 30 ? 30 : _token!.length)}...',
      );
    }
    debugPrint('[XanoSocket] channel present: ${_socketChannel != null}');
    debugPrint('[XanoSocket] reconnect attempts: $_reconnectAttempts');
    debugPrint('=========================================');
  }

  @override
  Stream<dynamic> get messageStream => _messageCtrl.stream;

  @override
  void sendMessage(Map<String, dynamic> message) {
    if (_socketChannel == null) {
      debugPrint('[XanoSocket] Cannot send message: not connected');
      return;
    }
    final json = jsonEncode(message);
    debugPrint('[XanoSocket] Sending: $json');
    _socketChannel!.sink.add(json);
  }

  @override
  void joinNotificationChannel({
    required String hotelId,
    required String userId,
  }) {
    // final channelName = 'notifications/$hotelId/$userId';
    final channelName = 'liveTickets/$hotelId';
    debugPrint('[XanoSocket] Joining channel: $channelName');

    final message = {
      'action': 'join',
      'options': {'channel': channelName},
      'payload': {'history': false, 'presence': true},
    };

    sendMessage(message);
  }

  void _emit(SocketConnectionStatus next) {
    _status = next;
    if (!_statusCtrl.isClosed) _statusCtrl.add(next);
  }
}

final xanoSocketServiceProvider = Provider<XanoSocketService>((ref) {
  final service = _XanoSocketServiceImpl();
  ref.onDispose(service.dispose);
  return service;
});
