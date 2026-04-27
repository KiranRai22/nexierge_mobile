/// All backend endpoints in one place.
///
/// Base URL is supplied at build time via `--dart-define=API_BASE_URL=...`
/// so production / staging / dev keep distinct hosts without code changes.
/// The auth path segment is the Xano-style branch path the login spec
/// publishes — also overridable via `--dart-define=API_AUTH_PATH=...`.
abstract class APIEndpoints {
  // ---------------------------------------------------------------------------
  // Base URL & path
  // ---------------------------------------------------------------------------

  static const String _host = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.nexierge.io',
  );

  static const String _authPath = String.fromEnvironment(
    'API_AUTH_PATH',
    defaultValue: '/api:3jzbUS4I',
  );

  /// Generic base used by every non-auth call.
  static const String baseUrl = _host;

  /// Auth-specific base. Login endpoints live under this prefix.
  static const String authBaseUrl = '$_host$_authPath';

  // ---------------------------------------------------------------------------
  // Auth endpoints
  //
  // The spec contains two contradicting endpoint paths for login:
  //   - Section 5.1 / 5.2:         /auth/login/password    /auth/login/code
  //   - Section 17 (LOCKED Rules): /auth/login/password_login
  //                                /auth/login/code_login
  //
  // We use the LOCKED Rules paths as the authoritative contract because
  // section 17 is explicitly marked as the locked product rule set.
  // If the backend actually ships the shorter paths, swap the two
  // constants below to the alternative on lines 50-51.
  // ---------------------------------------------------------------------------

  static const String loginEmail = '$authBaseUrl/auth/login/password_login';
  static const String loginCode = '$authBaseUrl/auth/login/code_login';

  // Alternative (Section 5) paths — keep here for quick swap if backend differs.
  // static const String loginEmail = '$authBaseUrl/auth/login/password';
  // static const String loginCode = '$authBaseUrl/auth/login/code';

  static const String logout = '$authBaseUrl/auth/logout';
  static const String refreshToken = '$authBaseUrl/auth/refresh';
  static const String forgotPassword = '$authBaseUrl/auth/forgot-password';

  // ---------------------------------------------------------------------------
  // User endpoints (preserved from the previous shape).
  // ---------------------------------------------------------------------------

  static const String profile = '$baseUrl/v1/user/profile';
  static const String updateProfile = '$baseUrl/v1/user/profile';

  // ---------------------------------------------------------------------------
  // Timeouts & headers
  // ---------------------------------------------------------------------------

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  static const String contentTypeJson = 'application/json';
  static const String authorizationHeader = 'Authorization';
  static const String bearerPrefix = 'Bearer ';
}
