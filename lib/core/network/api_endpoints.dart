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

  // ─── LEGACY-V1 (2026-05-14) ─────────────────────────────────────────────
  // `get_my_tickets` replaced by per-status ticketsv2 endpoints below.
  // Kept active for rollback safety until v2 is stable. Do not remove.
  static const String ticketsGetMyTickets =
      '$_host/api:bAt3sLZU/tickets/get_my_tickets';
  // ────────────────────────────────────────────────────────────────────────

  static const String ticketsAddGetDepartmentsAndRooms =
      '$_host/api:bAt3sLZU/tickets/add/get_departnents_and_rooms';
  static const String ticketsManual = '$_host/api:t_TeioyT/tickets/manual';

  // ---------------------------------------------------------------------------
  // Tickets V2 — per-status list endpoints + start/done actions.
  // Common query params: page, per_page, hotel_id (mandatory); optional
  // source, department, ticket_type, created_at_start_date, created_at_end_date.
  // Response shape identical to v1 paginated list.
  // ---------------------------------------------------------------------------

  static const String _ticketsV2Base = '$_host/api:t_TeioyT/ticketsv2';

  static const String ticketsV2New = '$_ticketsV2Base/new';
  static const String ticketsV2Backlog = '$_ticketsV2Base/backlog';
  static const String ticketsV2InProgress = '$_ticketsV2Base/in_progress';
  static const String ticketsV2DoneToday = '$_ticketsV2Base/done';
  static const String ticketsV2DoneHistory = '$_ticketsV2Base/done/history';

  /// POST `/ticketsv2/start/{id}` — body `{tickets_v2_id: <uuid>, due_at: null}`.
  /// Moves NEW → IN_PROGRESS, assigns current user.
  static String ticketsV2Start(String ticketId) =>
      '$_ticketsV2Base/start/$ticketId';
  /// POST `/ticketsv2/done/{id}` — body carries existing resolution payload
  /// `{resolution_notes, resolution_code?, ...}`. Moves IN_PROGRESS → DONE.
  static String ticketsV2Done(String ticketId) =>
      '$_ticketsV2Base/done/$ticketId';

  /// POST `/ticketsv2/backlog` — body `{tickets_v2_id: <uuid>, reason: <string>}`. Moves to backlog.
  static const String ticketsV2BacklogMove = '$_ticketsV2Base/backlog';

  /// POST `/ticketsv2/add_time/{id}` — adds additional time to ticket SLA.
  /// Body: `{tickets_v2_id, reason, extension_minutes?}`
  static String ticketsV2AddTime(String ticketId) =>
      '$_ticketsV2Base/add_time/$ticketId';

  /// POST `/ticketsv2/reset_acknowledge/{id}` — body `{reason: <string>}`.
  /// Resets ticket acknowledgement.
  static String ticketsV2ResetAcknowledge(String ticketId) =>
      '$_ticketsV2Base/reset_acknowledge/$ticketId';

  /// POST `/ticketsv2/cancel` — body `{tickets_v2_id, reason}`. Moves to CANCELED.
  static const String ticketsV2Cancel = '$_ticketsV2Base/cancel';

  /// Base path for `/tickets/change_status/{id}` — append the ticket id
  /// to form the full URL. Body carries `{tickets_v2_id, new_status}`.
  static const String ticketsChangeStatusBase =
      '$_host/api:t_TeioyT/tickets/change_status';
  static String ticketsChangeStatus(String ticketId) =>
      '$ticketsChangeStatusBase/$ticketId';

  static const String ticketsCancel = '$_host/api:bAt3sLZU/tickets/cancel';

  /// @Deprecated('Use ticketsV2AddTime instead')
  /// Legacy PATCH endpoint for changing due time.
  @Deprecated('Use ticketsV2AddTime instead')
  static const String ticketsChangeDueTimeBase =
      '$_host/api:t_TeioyT/tickets/change_due_time';
  @Deprecated('Use ticketsV2AddTime instead')
  static String ticketsChangeDueTime(String ticketId) =>
      '$ticketsChangeDueTimeBase/$ticketId';

  // ─── DEPRECATED V1 (2026-05-20) ───────────────────────────────────────────
  // These endpoints are deprecated. Use V2 equivalents:
  // - `acknowledge` / `acknowledge_and_start` → `ticketsV2Start`
  // Scheduled for removal after 30 days of V2 stability.
  // ────────────────────────────────────────────────────────────────────────

  /// @Deprecated('Use ticketsV2Start instead')
  @Deprecated('Use ticketsV2Start instead')
  static const String ticketsAcknowledgeBase =
      '$_host/api:t_TeioyT/tickets/acknowledge';
  @Deprecated('Use ticketsV2Start instead')
  static String ticketsAcknowledge(String ticketId) =>
      '$ticketsAcknowledgeBase/$ticketId';

  /// @Deprecated('Use ticketsV2Start instead')
  @Deprecated('Use ticketsV2Start instead')
  static const String ticketsAcknowledgeAndStartBase =
      '$_host/api:t_TeioyT/tickets/acknowledge_and_start';
  @Deprecated('Use ticketsV2Start instead')
  static String ticketsAcknowledgeAndStart(String ticketId) =>
      '$ticketsAcknowledgeAndStartBase/$ticketId';

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

  // Version control — GET, requires auth token
  static const String versionControl = '$_host/api:bAt3sLZU/version_control';

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
