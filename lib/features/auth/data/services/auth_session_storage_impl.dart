import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/secure_storage_service.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/services/auth_session_storage.dart';

/// Concrete [AuthSessionStorage] backed by `flutter_secure_storage` via
/// the [SecureStorageService] abstraction. Stores the whole session as a
/// single JSON blob under one key.
class _AuthSessionStorageImpl implements AuthSessionStorage {
  static const _kKey = 'auth.session.v1';
  final SecureStorageService _storage;

  _AuthSessionStorageImpl(this._storage);

  @override
  Future<AuthSession?> read() async {
    final raw = await _storage.read(_kKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final token = map['authToken'] as String?;
      if (token == null || token.isEmpty) return null;
      final userJson = map['user'];
      final user = userJson is Map<String, dynamic>
          ? AuthUser(
              id: (userJson['id'] ?? '').toString(),
              role: userJson['role'] as String?,
              hotelId: userJson['hotel_id'] as String?,
            )
          : null;
      return AuthSession(
        authToken: token,
        refreshToken: map['refresh_token'] as String?,
        user: user,
      );
    } catch (_) {
      // Storage corruption — treat as no session.
      await _storage.delete(_kKey);
      return null;
    }
  }

  @override
  Future<void> write(AuthSession session) {
    final user = session.user;
    final payload = <String, dynamic>{
      'authToken': session.authToken,
      if (session.refreshToken != null)
        'refresh_token': session.refreshToken,
      if (user != null)
        'user': {
          'id': user.id,
          if (user.role != null) 'role': user.role,
          if (user.hotelId != null) 'hotel_id': user.hotelId,
        },
    };
    return _storage.write(_kKey, jsonEncode(payload));
  }

  @override
  Future<void> clear() => _storage.delete(_kKey);
}

final authSessionStorageProvider = Provider<AuthSessionStorage>((ref) {
  final storage = ref.watch(secureStorageServiceProvider);
  return _AuthSessionStorageImpl(storage);
});
