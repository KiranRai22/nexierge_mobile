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
    defaultValue: 'https://xvmf-wx0g-xvlj.b2.xano.io',
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
  // ---------------------------------------------------------------------------

  static const String loginEmail = '$authBaseUrl/auth/login/password';
  static const String loginCode = '$authBaseUrl/auth/login/code';

  static const String logout = '$authBaseUrl/auth/logout';
  static const String refreshToken = '$authBaseUrl/auth/refresh';
  static const String forgotPassword = '$authBaseUrl/auth/forgot-password';

  // ---------------------------------------------------------------------------
  // User endpoints (preserved from the previous shape).
  // ---------------------------------------------------------------------------

  static const String profile = '$baseUrl/v1/user/profile';
  static const String updateProfile = '$baseUrl/v1/user/profile';

  // Dashboard
  static const String dashboardHotelDetails =
      '$baseUrl/dashboard/hotel_details';
  static const String dashboardNumbers = '$baseUrl/dashboard/numbers';

  // FCM
  static const String fcmUpdate = '$baseUrl/fcm_update';

  // Firebase helper
  static const String firebaseSignUp = '$baseUrl/firebase/sign_up';

  // Rooms
  static const String roomsDetails = '$baseUrl/rooms/details';
  static const String roomsGetAll = '$baseUrl/rooms/get/all';
  static const String roomsUpdateStatus = '$baseUrl/rooms/update_status';
  static const String roomsApproveStatusChange =
      '$baseUrl/rooms/approve_status_change';

  // Staff
  static const String staffGetAllHousekeeping =
      '$baseUrl/staff/get_all_housekeeping';

  // Languages
  static const String languagesAll = '$baseUrl/languages/all';

  // ---------------------------------------------------------------------------
  // Timeouts & headers
  // ---------------------------------------------------------------------------

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  static const String contentTypeJson = 'application/json';
  static const String authorizationHeader = 'Authorization';
  static const String bearerPrefix = 'Bearer ';

  static const String clientHeader = 'client';
  static const String clientHeaderValue = 'mobile';
}
