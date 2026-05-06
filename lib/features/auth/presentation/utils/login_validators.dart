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

  // Employee code format: 3 uppercase letters, hyphen, 5-6 digits (e.g., ABC-12345)
  static final RegExp _employeeCodeRegex = RegExp(r'^[A-Z]{3}-[0-9]{5,6}$');

  // Alphanumeric + hyphen only for employee code input validation
  static final RegExp _employeeCodeCharsRegex = RegExp(r'^[A-Z0-9-]*$');

  // Digits only for login code
  static final RegExp _loginCodeCharsRegex = RegExp(r'^[0-9]*$');

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
  /// - Format: XXX-XXXXX or XXX-XXXXXX (3 letters, hyphen, 5-6 digits)
  /// - Must contain exactly one hyphen
  /// - Letters must come before hyphen, digits after
  static String? employeeCode(String input, AppLocalizations s) {
    final v = input.trim().toUpperCase();
    if (v.isEmpty) return s.requiredField;
    if (v.length > maxFieldLength) return s.requiredField;
    if (_hasControlChars(v)) return s.requiredField;

    // Check length constraints (9-10 characters: XXX-XXXXX or XXX-XXXXXX)
    if (v.length < 9 || v.length > 10) {
      return 'Employee code must be 9-10 characters (e.g., ABC-12345)';
    }

    // Check character restrictions
    if (!_employeeCodeCharsRegex.hasMatch(v)) {
      return 'Only uppercase letters, numbers, and hyphen allowed';
    }

    // Check hyphen count and position
    final hyphenCount = v.codeUnits
        .where((c) => c == 45)
        .length; // ASCII 45 = '-'
    if (hyphenCount != 1) {
      return 'Employee code must contain exactly one hyphen';
    }

    final hyphenIndex = v.indexOf('-');
    if (hyphenIndex != 3) {
      return 'Format: XXX-XXXXX (3 letters-hyphen-5-6 digits)';
    }

    // Check format with regex
    if (!_employeeCodeRegex.hasMatch(v)) {
      return 'Invalid format. Use: ABC-12345 or ABC-123456';
    }

    return null;
  }

  /// Validates login code:
  /// - Only digits allowed
  /// - 4-6 digits required
  static String? loginCode(String input, AppLocalizations s) {
    final v = input.trim();
    if (v.isEmpty) return s.requiredField;
    if (v.length > maxFieldLength) return s.requiredField;
    if (_hasControlChars(v)) return s.requiredField;

    // Check length constraints (4-6 digits)
    if (v.length < 4) {
      return 'Login code must be at least 4 digits';
    }
    if (v.length > 6) {
      return 'Login code cannot exceed 6 digits';
    }

    // Check character restrictions (digits only)
    if (!_loginCodeCharsRegex.hasMatch(v)) {
      return 'Only numbers allowed';
    }

    // Ensure all characters are digits
    if (!RegExp(r'^[0-9]+$').hasMatch(v)) {
      return 'Login code must contain only numbers';
    }

    return null;
  }

  /// Normalises an email: trim + lowercase
  static String normaliseEmail(String input) => input.trim().toLowerCase();

  /// Normalises a code: trim + uppercase
  static String normaliseCode(String input) => input.trim().toUpperCase();
}
