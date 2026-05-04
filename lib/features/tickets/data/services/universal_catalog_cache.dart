import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Thin SharedPreferences wrapper for the universal catalog response.
///
/// Stores the raw JSON string keyed by hotel id. The fetch timestamp is held
/// alongside it so the provider can decide whether to refetch.
class UniversalCatalogCache {
  static const _kPayloadPrefix = 'universal_catalog.payload.';
  static const _kFetchedAtPrefix = 'universal_catalog.fetched_at.';

  /// Default freshness window — 24h per product call.
  static const Duration defaultTtl = Duration(hours: 24);

  Future<CachedCatalogEntry?> read(String hotelId) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = prefs.getString('$_kPayloadPrefix$hotelId');
    final ts = prefs.getInt('$_kFetchedAtPrefix$hotelId');
    if (payload == null || ts == null) return null;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is! List) return null;
      return CachedCatalogEntry(
        json: decoded.cast<dynamic>(),
        fetchedAt: DateTime.fromMillisecondsSinceEpoch(ts),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> write(String hotelId, List<dynamic> json) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_kPayloadPrefix$hotelId', jsonEncode(json));
    await prefs.setInt(
      '$_kFetchedAtPrefix$hotelId',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> invalidate(String hotelId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_kPayloadPrefix$hotelId');
    await prefs.remove('$_kFetchedAtPrefix$hotelId');
  }
}

class CachedCatalogEntry {
  final List<dynamic> json;
  final DateTime fetchedAt;
  CachedCatalogEntry({required this.json, required this.fetchedAt});

  bool isFresh(Duration ttl) => DateTime.now().difference(fetchedAt) < ttl;
}
