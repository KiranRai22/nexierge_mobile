import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexierge/features/auth/data/services/auth_session_storage_impl.dart';
import 'package:nexierge/features/auth/domain/entities/auth_session.dart';
import 'package:nexierge/features/auth/domain/entities/auth_user.dart';
import 'package:nexierge/features/auth/domain/services/auth_session_storage.dart';
import 'package:nexierge/features/auth/presentation/providers/auth_session_controller.dart';

class _FakeAuthSessionStorage implements AuthSessionStorage {
  AuthSession? _stored;
  int writeCount = 0;
  int clearCount = 0;
  int readCount = 0;

  _FakeAuthSessionStorage([this._stored]);

  @override
  Future<AuthSession?> read() async {
    readCount++;
    return _stored;
  }

  @override
  Future<void> write(AuthSession session) async {
    writeCount++;
    _stored = session;
  }

  @override
  Future<void> clear() async {
    clearCount++;
    _stored = null;
  }
}

ProviderContainer _makeContainer(AuthSessionStorage storage) {
  return ProviderContainer(
    overrides: [
      authSessionStorageProvider.overrideWithValue(storage),
    ],
  );
}

void main() {
  group('AuthSessionController.build', () {
    test('hydrates null when storage empty', () async {
      final fake = _FakeAuthSessionStorage();
      final c = _makeContainer(fake);
      addTearDown(c.dispose);

      final session = await c.read(authSessionControllerProvider.future);

      expect(session, isNull);
      expect(fake.readCount, 1);
    });

    test('hydrates existing session from storage', () async {
      final stored = const AuthSession(
        authToken: 'tkn-abc',
        refreshToken: 'r-1',
        user: AuthUser(id: 'u1', role: 'staff'),
      );
      final fake = _FakeAuthSessionStorage(stored);
      final c = _makeContainer(fake);
      addTearDown(c.dispose);

      final session = await c.read(authSessionControllerProvider.future);

      expect(session, isNotNull);
      expect(session!.authToken, 'tkn-abc');
      expect(session.refreshToken, 'r-1');
      expect(session.user?.id, 'u1');
    });
  });

  group('AuthSessionController.setSession', () {
    test('writes through storage and exposes session as AsyncData', () async {
      final fake = _FakeAuthSessionStorage();
      final c = _makeContainer(fake);
      addTearDown(c.dispose);

      await c.read(authSessionControllerProvider.future);
      final controller = c.read(authSessionControllerProvider.notifier);

      const next = AuthSession(authToken: 'tkn-new');
      await controller.setSession(next);

      expect(fake.writeCount, 1);
      final state = c.read(authSessionControllerProvider);
      expect(state.value?.authToken, 'tkn-new');
    });

    test('overwrites previous session', () async {
      final fake = _FakeAuthSessionStorage(
        const AuthSession(authToken: 'old'),
      );
      final c = _makeContainer(fake);
      addTearDown(c.dispose);

      await c.read(authSessionControllerProvider.future);
      final controller = c.read(authSessionControllerProvider.notifier);

      await controller.setSession(const AuthSession(authToken: 'new'));

      final state = c.read(authSessionControllerProvider);
      expect(state.value?.authToken, 'new');
      expect(fake.writeCount, 1);
    });
  });

  group('AuthSessionController.clear', () {
    test('clears storage and emits null', () async {
      final fake = _FakeAuthSessionStorage(
        const AuthSession(authToken: 'tkn'),
      );
      final c = _makeContainer(fake);
      addTearDown(c.dispose);

      await c.read(authSessionControllerProvider.future);
      final controller = c.read(authSessionControllerProvider.notifier);

      await controller.clear();

      expect(fake.clearCount, 1);
      final state = c.read(authSessionControllerProvider);
      expect(state.value, isNull);
    });
  });

  group('AuthSession entity', () {
    test('requires authToken; refreshToken and user optional', () {
      const s1 = AuthSession(authToken: 'a');
      expect(s1.authToken, 'a');
      expect(s1.refreshToken, isNull);
      expect(s1.user, isNull);

      const s2 = AuthSession(
        authToken: 'b',
        refreshToken: 'r',
        user: AuthUser(id: 'x', role: 'admin', hotelId: 'h-1'),
      );
      expect(s2.refreshToken, 'r');
      expect(s2.user?.id, 'x');
      expect(s2.user?.role, 'admin');
      expect(s2.user?.hotelId, 'h-1');
    });
  });
}
