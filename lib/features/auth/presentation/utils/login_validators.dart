import '../../../../l10n/generated/app_localizations.dart';

/// Field-level validators for the login form.
///
/// Validation rules:
/// - Email: Standard RFC 5322 regex, trimmed, lowercase
/// - Employee Code: Uppercase only, alphanumeric + hyphen only, format: XX-XXXX
/// - Login Code: Uppercase only, alphanumeric only
abstract class LoginValidators {
  // Standard email regex (RFC 5322 compliant simplified)
  static final RegExp _emailRegex = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$",
  );

  // Employee code format: 2-3 uppercase letters, hyphen, 3-4 digits (e.g., AB-1234 or ABC-123)
  static final RegExp _employeeCodeRegex = RegExp(r'^[A-Z]{2,3}-[0-9]{3,4}$');

  // Alphanumeric + hyphen only for employee code input validation
  static final RegExp _employeeCodeCharsRegex = RegExp(r'^[A-Z0-9-]*$');

  // Alphanumeric only for login code
  static final RegExp _loginCodeCharsRegex = RegExp(r'^[A-Z0-9]*$');

  /// Hard cap so the network layer never sees absurd payloads
  static const int maxFieldLength = 256;

  static bool _hasControlChars(String s) {
    for (final unit in s.codeUnits) {
      if (unit < 0x20 || unit == 0x7F) return true;
    }
    return false;
  }

  /// Validates email with standard RFC 5322 regex
  /// Returns null when valid, otherwise the localised error string
  static String? email(String input, AppLocalizations s) {
    final v = input.trim();
    if (v.isEmpty) return s.requiredField;
    if (v.length > maxFieldLength) return s.invalidEmail;
    if (_hasControlChars(v)) return s.invalidEmail;
    if (!_emailRegex.hasMatch(v)) return s.invalidEmail;
    return null;
  }

  static String? password(String input, AppLocalizations s) {
    if (input.isEmpty) return s.requiredField;
    if (input.length > maxFieldLength) return s.passwordTooShort;
    if (_hasControlChars(input)) return s.requiredField;
    return null;
  }

  /// Validates employee code:
  /// - Must be uppercase
  /// - Only alphanumeric and hyphen allowed
  /// - Format: XX-XXXX or XXX-XXX (2-3 letters, hyphen, 3-4 digits)
  static String? employeeCode(String input, AppLocalizations s) {
    final v = input.trim().toUpperCase();
    if (v.isEmpty) return s.requiredField;
    if (v.length > maxFieldLength) return s.requiredField;
    if (_hasControlChars(v)) return s.requiredField;
    if (!_employeeCodeCharsRegex.hasMatch(v)) {
      return 'Only uppercase letters, numbers, and hyphen allowed';
    }
    if (!_employeeCodeRegex.hasMatch(v)) {
      return 'Format: XX-XXXX (e.g., AB-1234)';
    }
    return null;
  }

  /// Validates login code:
  /// - Must be uppercase
  /// - Only alphanumeric allowed
  static String? loginCode(String input, AppLocalizations s) {
    final v = input.trim().toUpperCase();
    if (v.isEmpty) return s.requiredField;
    if (v.length > maxFieldLength) return s.requiredField;
    if (_hasControlChars(v)) return s.requiredField;
    if (!_loginCodeCharsRegex.hasMatch(v)) {
      return 'Only uppercase letters and numbers allowed';
    }
    return null;
  }

  /// Normalises an email: trim + lowercase
  static String normaliseEmail(String input) => input.trim().toLowerCase();

  /// Normalises a code: trim + uppercase
  static String normaliseCode(String input) => input.trim().toUpperCase();
}
