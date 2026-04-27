import 'auth_user.dart';

/// Authenticated session — the result of a successful login. Stored
/// behind [AuthSessionStorage] so the chosen secure layer can change
/// without touching the rest of the app.
class AuthSession {
  /// Bearer token. Required — see §6 / §9.1 of the login spec.
  final String authToken;

  /// Optional refresh token (§6 — recommended).
  final String? refreshToken;

  /// Optional user record (§6 — recommended).
  final AuthUser? user;

  const AuthSession({
    required this.authToken,
    this.refreshToken,
    this.user,
  });
}
