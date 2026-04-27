import '../entities/auth_session.dart';
import '../entities/login_credentials.dart';

/// Repository contract for authentication. UI never depends on the
/// concrete implementation — it goes through this interface only.
abstract class AuthRepository {
  /// Submits credentials. Returns the [AuthSession] on success.
  /// Throws [AuthException] for credential / state failures, or
  /// [AppException] for transport-level failures.
  Future<AuthSession> signIn(LoginCredentials credentials);
}
