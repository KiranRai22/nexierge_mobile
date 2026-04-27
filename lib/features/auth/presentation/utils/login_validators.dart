import '../../../../l10n/generated/app_localizations.dart';

/// Field-level validators for the login form.
///
/// Notes on the SQL-injection concern from the brief: the only real
/// defence is *server-side* parameterised queries — a client-side string
/// filter is not a security boundary. What we DO take care of here is
/// the set of client-side hygiene rules the spec asks for: trim,
/// lowercase email, preserve code casing, reject empty / over-long
/// values, reject control characters that have no business in a
/// credential field.
abstract class LoginValidators {
  // RFC 5322 lite — covers the realistic 99% without Hadoop-tier regex.
  static final RegExp _emailRegex =
      RegExp(r'^[\w.+\-]+@[\w\-]+(\.[\w\-]+)+$');

  /// Hard cap so the network layer never sees absurd payloads. Server
  /// is the source of truth on max length; this is a pre-flight guard.
  static const int maxFieldLength = 256;

  static bool _hasControlChars(String s) {
    for (final unit in s.codeUnits) {
      if (unit < 0x20 || unit == 0x7F) return true;
    }
    return false;
  }

  /// Returns null when valid, otherwise the localised error string.
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

  static String? employeeCode(String input, AppLocalizations s) {
    final v = input.trim();
    if (v.isEmpty) return s.requiredField;
    if (v.length > maxFieldLength) return s.requiredField;
    if (_hasControlChars(v)) return s.requiredField;
    return null;
  }

  static String? loginCode(String input, AppLocalizations s) {
    final v = input.trim();
    if (v.isEmpty) return s.requiredField;
    if (v.length > maxFieldLength) return s.requiredField;
    if (_hasControlChars(v)) return s.requiredField;
    return null;
  }

  /// Normalises an email before submit per spec §5.1: trim + lowercase.
  static String normaliseEmail(String input) => input.trim().toLowerCase();

  /// Trims a credential without touching its case (§5.2 / §7.2).
  static String normaliseCode(String input) => input.trim();
}
