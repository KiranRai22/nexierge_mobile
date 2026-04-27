/// Domain entity for the profile screen. Aggregates everything the UI
/// renders so the widget tree stays declarative and free of conditionals
/// against the auth/session shape.
class UserProfile {
  final String id;
  final String fullName;
  final String email;
  final String? employeeCode;
  final String role;
  final List<String> departments;
  final UserStatus status;

  const UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.departments,
    required this.status,
    this.employeeCode,
  });

  /// Two-letter initials for the avatar — uses first + last name when
  /// possible, falls back to a single letter for one-word names, and a
  /// `?` when the name is empty (defensive: a profile should always have
  /// a name, but the UI must never render empty).
  String get initials {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

/// Lifecycle state of an account. Kept as an enum so the UI can switch on
/// it for colour without parsing strings.
enum UserStatus { active, inactive }
