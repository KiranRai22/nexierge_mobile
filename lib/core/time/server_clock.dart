import 'dart:io' show HttpDate;

import 'package:flutter/foundation.dart';

/// Process-wide clock offset between this device and the backend.
///
/// The HTTP `Date` response header (RFC 7231) is read on every API response
/// via a Dio interceptor and used to compute `offset = serverNow - clientNow`.
/// All user-facing elapsed/relative time UI must read [ServerClock.now] so two
/// devices with unsynchronised wall clocks render the same elapsed labels.
///
/// Mobile-only (iOS + Android); `dart:io.HttpDate` is fine here.
class ServerClock {
  ServerClock._();

  static Duration _offset = Duration.zero;
  static DateTime? _lastSyncAt;

  /// Server-aligned "now". Falls back to [DateTime.now] until the first
  /// successful sync from a `Date` response header.
  static DateTime now() => DateTime.now().add(_offset);

  /// Current offset (server − client). Zero until first sync.
  static Duration get offset => _offset;

  /// Last time the offset was refreshed (client clock). Null = never synced.
  static DateTime? get lastSyncAt => _lastSyncAt;

  /// Parse an RFC 7231 `Date` header (e.g. `Mon, 10 May 2026 14:30:00 GMT`)
  /// and update the offset. Network latency means the parsed instant is
  /// slightly stale; we ignore that since UI granularity is seconds at best.
  static void updateFromHttpDate(String? header) {
    if (header == null || header.isEmpty) return;
    try {
      final serverNow = HttpDate.parse(header);
      _offset = serverNow.difference(DateTime.now());
      _lastSyncAt = DateTime.now();
    } catch (_) {
      if (kDebugMode) {
        debugPrint('[ServerClock] failed to parse Date header: $header');
      }
    }
  }

  @visibleForTesting
  static void resetForTest() {
    _offset = Duration.zero;
    _lastSyncAt = null;
  }

  @visibleForTesting
  static void setOffsetForTest(Duration offset) {
    _offset = offset;
    _lastSyncAt = DateTime.now();
  }
}
