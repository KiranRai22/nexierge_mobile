import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Disk-backed snapshot store for the tickets feature.
///
/// Caches the **raw server JSON** for each paged tab keyed by hotel so the
/// app can paint the last-known-good list on cold start instead of an
/// empty shimmer while the live fetch is in flight. The persisted blob is
/// the exact `Map<String, dynamic>` that `TicketsPageDto.fromJson`
/// already knows how to consume — no new (de)serialisation surface to
/// keep in sync with the wire contract.
///
/// **Versioning.** Every write is wrapped in
/// `{ "v": <int>, "p": <payload>, "ts": <epochMs> }`. On read we discard
/// entries whose `v` does not match [_currentVersion]. Bump the version
/// whenever the DTO `fromJson` semantics change in a backwards-incompatible
/// way (e.g. a renamed required field) and existing entries will silently
/// roll over to a fresh network fetch.
///
/// **Scoping.** Cache keys include the hotel id so a user who switches
/// hotels never sees the previous hotel's tickets bleed through.
class TicketsCacheStore {
  TicketsCacheStore();

  /// Schema version baked into each cache entry. Bump when DTO shape changes.
  static const int _currentVersion = 1;

  static const _ticketsPagePrefix = 'tickets_cache.page_v1.';
  static const _countsPrefix = 'tickets_cache.counts_v1.';

  /// Cache key for a paged tickets snapshot. Combines tab + hotel so two
  /// tabs / two hotels never collide on disk.
  static String pageKey({required String tab, required String hotelId}) =>
      '$_ticketsPagePrefix$tab.$hotelId';

  /// Cache key for the dashboard-counts snapshot.
  static String countsKey({required String hotelId}) =>
      '$_countsPrefix$hotelId';

  /// Read a previously-persisted JSON payload. Returns null on cache miss,
  /// version mismatch, or any decode error — callers are expected to fall
  /// through to a live fetch in every "null" case.
  Future<Map<String, dynamic>?> readJsonMap(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final v = decoded['v'];
      if (v != _currentVersion) {
        // Schema mismatch — drop the stale entry so we don't waste a read
        // next launch.
        await prefs.remove(key);
        return null;
      }
      final payload = decoded['p'];
      if (payload is! Map<String, dynamic>) return null;
      return payload;
    } catch (e) {
      if (kDebugMode) debugPrint('[TicketsCacheStore] read failed ($key): $e');
      return null;
    }
  }

  /// Persist a payload. Wraps with the schema version + write timestamp.
  /// Fire-and-forget from the caller's point of view — failures are logged
  /// in debug and swallowed so a busted disk never crashes the request
  /// path.
  Future<void> writeJsonMap(String key, Map<String, dynamic> payload) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final wrapper = <String, dynamic>{
        'v': _currentVersion,
        'ts': DateTime.now().millisecondsSinceEpoch,
        'p': payload,
      };
      await prefs.setString(key, jsonEncode(wrapper));
    } catch (e) {
      if (kDebugMode) debugPrint('[TicketsCacheStore] write failed ($key): $e');
    }
  }

  /// Drop one cache entry. Used by logout/hotel-switch paths.
  Future<void> invalidate(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (_) {
      // ignore — best-effort cleanup.
    }
  }

  /// Drop every entry this store owns. Called on full logout to avoid
  /// leaking tickets data across user sessions on the same device.
  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where(
            (k) => k.startsWith(_ticketsPagePrefix) || k.startsWith(_countsPrefix),
          );
      for (final k in keys) {
        await prefs.remove(k);
      }
    } catch (_) {
      // ignore — best-effort cleanup.
    }
  }
}

/// App-scoped cache store. Single instance, lives for the app lifetime
/// (SharedPreferences itself is a singleton so multiple stores would
/// share the same underlying disk anyway).
final ticketsCacheStoreProvider = Provider<TicketsCacheStore>((ref) {
  return TicketsCacheStore();
});
