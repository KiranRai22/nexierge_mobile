import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/auth_session_storage_impl.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/services/auth_session_storage.dart';

/// Global auth session — single source of truth for "is the user logged in".
///
/// `build()` hydrates from secure storage so the root widget can route to
/// `HomeShell` on cold start when a previous session exists (auto-login).
/// `setSession` is the only writer the login flow needs; `clear` is the
/// logout hook. Default (non-autoDispose) provider keeps the session
/// across widget-tree rebuilds — required by §07 (persistent state).
class AuthSessionController extends AsyncNotifier<AuthSession?> {
  late AuthSessionStorage _storage;

  @override
  Future<AuthSession?> build() async {
    _storage = ref.read(authSessionStorageProvider);
    return _storage.read();
  }

  Future<void> setSession(AuthSession session) async {
    await _storage.write(session);
    state = AsyncData(session);
  }

  Future<void> clear() async {
    await _storage.clear();
    state = const AsyncData(null);
  }
}

final authSessionControllerProvider =
    AsyncNotifierProvider<AuthSessionController, AuthSession?>(
      AuthSessionController.new,
    );
