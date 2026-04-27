import '../entities/auth_session.dart';

/// Abstract persistence for the bearer-token session. Mobile uses
/// `flutter_secure_storage`; tests substitute an in-memory fake.
abstract class AuthSessionStorage {
  Future<AuthSession?> read();
  Future<void> write(AuthSession session);
  Future<void> clear();
}
