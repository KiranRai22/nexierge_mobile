/// Reasons a login attempt can fail. Includes the credential rejection
/// (`invalidCredentials`) plus the state-based rejections from §10 of
/// the spec — these MUST surface as distinct, accurate copy and not be
/// collapsed into a generic "wrong password" error.
enum AuthFailureReason {
  /// 401 / "Invalid email or password" / "Invalid employee code or login code".
  invalidCredentials,

  /// Login code TTL expired (spec §11.2, §15.3).
  codeExpired,

  /// Account exists but admin hasn't approved yet (spec §10).
  pendingReview,

  /// Account access request rejected by admin (spec §10).
  rejected,

  /// Account disabled by admin (spec §10).
  disabled,

  /// Hotel account itself isn't active (spec §10).
  inactiveHotel,

  /// Catch-all for the spec's "Something went wrong. Please try again".
  generic,
}

/// Domain exception for login failures. Lives in the auth feature (not
/// `core/error`) because the failure reasons are auth-specific.
class AuthException implements Exception {
  final AuthFailureReason reason;

  /// Optional server-supplied message. When present and the reason is
  /// generic, the UI surfaces this verbatim instead of the localised
  /// fallback (spec §11 — "API-provided error message").
  final String? serverMessage;

  const AuthException({
    required this.reason,
    this.serverMessage,
  });

  @override
  String toString() => 'AuthException(reason: $reason)';
}
