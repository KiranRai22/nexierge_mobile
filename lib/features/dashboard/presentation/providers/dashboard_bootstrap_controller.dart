import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexierge/features/dashboard/data/datasources/dashboard_remote_data_source.dart';

import 'package:flutter/foundation.dart';

import '../../../../core/services/realtime/xano_socket_service.dart';
import '../../../auth/data/dtos/user_profile_dto.dart';
import '../../../auth/data/services/auth_me_service.dart';
import '../../../auth/domain/entities/user_profile.dart' as auth;
import '../../../auth/presentation/providers/user_profile_controller.dart'
    as auth_ctrl;
import '../../../version_control/presentation/providers/version_check_notifier.dart';
import '../../data/datasources/dashboard_remote_data_source.dart'
    as dashboard_dto;
import '../../data/services/dashboard_data_service.dart';
import '../../domain/entities/dashboard_bootstrap_state.dart';

/// AsyncNotifier that manages the dashboard bootstrap process.
///
/// Loads 2 APIs in parallel on login:
/// 1. me_user → user profile
/// 2. dashboard/numbers → KPI counts
///
/// Uses Future.wait for non-blocking concurrency. Data is stored locally as it arrives.
class DashboardBootstrapController
    extends AsyncNotifier<DashboardBootstrapState> {
  late AuthMeService _authMeService;
  late DashboardRemoteDataSource _dashboardRemote;
  late DashboardDataService _dataService;

  late XanoSocketService _socketService;

  @override
  Future<DashboardBootstrapState> build() async {
    _authMeService = ref.read(authMeServiceProvider);
    _dashboardRemote = ref.read(dashboardRemoteDataSourceProvider);
    _dataService = DashboardDataService();
    _socketService = ref.read(xanoSocketServiceProvider);

    // Check if we have cached data that's still fresh
    final isComplete = await _dataService.isBootstrapComplete();
    if (isComplete) {
      final cached = await _loadFromCache();
      if (cached.hasAllData) {
        return cached.copyWith(isComplete: true);
      }
    }
    // Start with empty state - loading happens via runBootstrap()
    return DashboardBootstrapState.empty;
  }

  /// Run the bootstrap process - called after successful login
  /// Sequential API calls: me_user first (to get userId), then dashboard/numbers
  Future<void> runBootstrap({String? hotelUserId}) async {
    // Only prevent re-entrant calls: isLoading is only true when a previous
    // runBootstrap already set AsyncLoading. The initial build() AsyncLoading
    // state resolves before ref.listen fires, so checking hasPreviousValue
    // distinguishes "build still loading" (hasPreviousValue=false) from
    // "runBootstrap already in flight" (hasPreviousValue=true).
    if (state.isLoading && state.hasValue) return;

    state = const AsyncLoading<DashboardBootstrapState>().copyWithPrevious(
      state,
    );

    try {

      // Step 1: Call me_user FIRST to get user profile (includes userId)
      final userProfileDto = await _fetchUserProfile();
      final userProfile = userProfileDto.toEntity();
      final effectiveHotelId = userProfile.userHotelStatus.hotelId;

      if (effectiveHotelId.isEmpty) {
        throw Exception('User profile does not contain hotelId');
      }

      // After auth/me: join hub_notifications channel using the tickets hub entry.
      // hub_access[].id is the channel segment; hub_code identifies the hub type.
      _joinHubNotificationsChannel(
        hotelId: effectiveHotelId,
        hubAccess: userProfile.accessControl.hubAccess,
      );

      // Step 2: Now call dashboard/numbers with the hotelId
      final dashboardNumbersDto = await _fetchDashboardNumbers(
        effectiveHotelId,
      );

      final dashboardNumbers = dashboardNumbersDto != null
          ? DashboardNumbers(
              inprogress: dashboardNumbersDto.inprogress ?? '',
              overdue: dashboardNumbersDto.overdue ?? '',
              notStarted: dashboardNumbersDto.notStarted ?? '',
              done: dashboardNumbersDto.done ?? '',
            )
          : null;

      // Save to local storage
      await _saveToCache(
        hotelDetails: null,
        dashboardNumbers: dashboardNumbers,
      );

      state = AsyncData(
        DashboardBootstrapState(
          userProfile: userProfile,
          hotelDetails: null,
          dashboardNumbers: dashboardNumbers,
          isComplete: true,
        ),
      );

      // Trigger version check after successful authentication and bootstrap
      ref.read(versionCheckProvider.notifier).checkAfterAuth();
    } catch (e, st) {
      debugPrint('[DashboardBootstrap] runBootstrap failed: $e\n$st');
      state = AsyncError(e, st);
    }
  }

  /// Fetch user profile from me_user API
  Future<UserProfileDto> _fetchUserProfile() => _authMeService.fetchMe();

  /// Fetch dashboard numbers from dashboard/numbers API
  Future<dashboard_dto.DashboardNumbersDto?> _fetchDashboardNumbers(
    String hotelId,
  ) async {
    try {
      return await _dashboardRemote.getNumbers(hotelId: hotelId);
    } catch (_) {
      return null;
    }
  }

  /// Load cached data from local storage
  Future<DashboardBootstrapState> _loadFromCache() async {
    final hotelDetails = await _dataService.getHotelDetails();
    final dashboardNumbers = await _dataService.getDashboardNumbers();

    return DashboardBootstrapState(
      hotelDetails: hotelDetails,
      dashboardNumbers: dashboardNumbers,
      isComplete: hotelDetails != null && dashboardNumbers != null,
    );
  }

  /// Save data to local storage
  Future<void> _saveToCache({
    HotelDetails? hotelDetails,
    DashboardNumbers? dashboardNumbers,
  }) async {
    try {
      if (hotelDetails != null) {
        await _dataService.saveHotelDetails(hotelDetails);
      }
      if (dashboardNumbers != null) {
        await _dataService.saveDashboardNumbers(dashboardNumbers);
      }
      await _dataService.markBootstrapComplete();
    } catch (_) {}
  }

  /// Clear all cached bootstrap data (called on logout)
  Future<void> clearCache() async {
    await _dataService.clearAllData();
    state = const AsyncData(DashboardBootstrapState.empty);
  }

  /// Refresh bootstrap data manually
  Future<void> refresh() async {
    await _dataService.clearAllData();
    await runBootstrap();
  }

  /// Joins hub_notifications/{hotelId}/{ticketHubTicketId} via the WebSocket.
  /// Called immediately after auth/me so the channel is subscribed before
  /// any hub events can be missed. The ticketHubTicketId is the `hub_preset_id`
  /// of the hub_access entry where hub_code == 'tickets'.
  void _joinHubNotificationsChannel({
    required String hotelId,
    required List<auth.HubAccess> hubAccess,
  }) {
    final ticketsHub = hubAccess
        .where((h) => h.hubCode == 'tickets' && h.hubPresetId.isNotEmpty)
        .firstOrNull;

    if (ticketsHub == null) {
      debugPrint(
        '[DashboardBootstrap] Cannot join hub_notifications: no hub_access entry with a valid id',
      );
      return;
    }

    debugPrint(
      '[DashboardBootstrap] Joining hub_notifications/$hotelId/${ticketsHub.hubPresetId} '
      '(hub_code: ${ticketsHub.hubCode})',
    );
    _socketService.joinHubNotificationsChannel(
      hotelId: hotelId,
      ticketHubTicketId: ticketsHub.hubPresetId,
    );
    debugPrint('[DashboardBootstrap] Connected to hub_notifications channel');
  }
}

/// Provider for the dashboard bootstrap controller
final dashboardBootstrapControllerProvider =
    AsyncNotifierProvider<
      DashboardBootstrapController,
      DashboardBootstrapState
    >(DashboardBootstrapController.new);

/// Provider to check if bootstrap is complete
final isDashboardBootstrapCompleteProvider = Provider<bool>((ref) {
  final bootstrap = ref.watch(dashboardBootstrapControllerProvider);
  return bootstrap.valueOrNull?.isComplete ?? false;
});

/// Provider to get user profile from bootstrap state
/// Use this in dashboard screens to display user info (name, profile pic, theme)
///
/// Prefers the live auth controller state (which reflects profile edits like
/// name / avatar updates in real time) and falls back to the initial bootstrap
/// payload while the auth controller is still warming up.
final bootstrapUserProfileProvider = Provider<auth.UserProfile?>((ref) {
  final authProfile = ref
      .watch(auth_ctrl.userProfileControllerProvider)
      .profile;
  if (authProfile != null) return authProfile;
  final bootstrap = ref.watch(dashboardBootstrapControllerProvider);
  return bootstrap.valueOrNull?.userProfile;
});
