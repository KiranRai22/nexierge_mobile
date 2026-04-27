/// Minimal user identity returned by the login response. Optional today —
/// the spec's MIN response (§6) only requires `authToken`. We model the
/// optional fields so callers can light up role-aware UI when present.
class AuthUser {
  final String id;
  final String? role;
  final String? hotelId;

  const AuthUser({
    required this.id,
    this.role,
    this.hotelId,
  });
}
