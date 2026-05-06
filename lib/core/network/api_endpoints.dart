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
  static const String meUser = '$authBaseUrl/auth/me_user';

  // ---------------------------------------------------------------------------
  // User endpoints (preserved from the previous shape).
  // ---------------------------------------------------------------------------

  static const String profile = '$authBaseUrl/auth/me_user';
  static const String updateProfile = '$_host/api:bAt3sLZU/user/edit';

  // Dashboard
  static const String dashboardHotelDetails =
      '$_host/api:bAt3sLZU/dashboard/hotel_details';
  static const String dashboardNumbers =
      '$_host/api:bAt3sLZU/dashboard/numbers';
  static const String dashboardNeedsAttention =
      '$_host/api:bAt3sLZU/dashboard/needs_attention';

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

  // Tickets
  static const String ticketsDetails = '$_host/api:bAt3sLZU/tickets/details';
  static const String ticketsGetMyTickets =
      '$_host/api:bAt3sLZU/tickets/get_my_tickets';
  static const String ticketsGetAll = '$_host/api:t_TeioyT/tickets/get/all';
  static const String ticketsAddGetDepartmentsAndRooms =
      '$_host/api:bAt3sLZU/tickets/add/get_departnents_and_rooms';
  static const String ticketsManual = '$_host/api:t_TeioyT/tickets/manual';
  static const String ticketsUpdateStatus =
      '$_host/api:bAt3sLZU/tickets/update_status';
  static const String ticketsCancel = '$_host/api:bAt3sLZU/tickets/cancel';
  static const String ticketsReset = '$_host/api:bAt3sLZU/tickets/reset';
  static const String ticketsChangeDue =
      '$_host/api:bAt3sLZU/tickets/change_due';

  // Service Catalogs
  static const String serviceCatalogsAll =
      '$_host/api:u0I0pXR9/service_catalogs/catalogs/all';
  static const String serviceCatalogItems =
      '$_host/api:u0I0pXR9/service_catalogs/items';
  static const String serviceCatalogsCreateOrder =
      '$_host/api:u0I0pXR9/service_catalogs/user_app/order/create';

  // Guest stay
  static const String guestStayCheckedIn =
      '$_host/api:bAt3sLZU/guest_stay/checked_in';

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
