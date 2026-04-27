/// Login mode chosen on the screen. Exposed by the controller so the
/// UI can preserve per-mode state across toggles (spec §4.1, §15.1).
enum LoginMode { email, employeeCode }

/// Parsed, post-validation credentials handed to the repository. The
/// repository never sees raw form input — all trimming and case
/// normalisation happens upstream so the contract stays unambiguous.
sealed class LoginCredentials {
  const LoginCredentials();
}

class EmailPasswordCredentials extends LoginCredentials {
  final String email;
  final String password;
  final String deviceToken; // Optional FCM token for push notifications

  const EmailPasswordCredentials({
    required this.email,
    required this.password,
    required this.deviceToken,
  });
}

class EmployeeCodeCredentials extends LoginCredentials {
  /// Trimmed only — must NOT be lowercased (spec §5.2 / §7.2).
  final String employeeCode;

  /// Trimmed only.
  final String loginCode;

  final String deviceToken; // Optional FCM token for push notifications

  const EmployeeCodeCredentials({
    required this.employeeCode,
    required this.loginCode,
    required this.deviceToken,
  });
}
