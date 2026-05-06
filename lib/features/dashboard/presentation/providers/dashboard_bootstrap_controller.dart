import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexierge/features/dashboard/data/datasources/dashboard_remote_data_source.dart';

import '../../../auth/data/dtos/user_profile_dto.dart';
import '../../../auth/data/services/auth_me_service.dart';
import '../../../auth/domain/entities/user_profile.dart' as auth;
import '../../../auth/presentation/providers/user_profile_controller.dart'
    as auth_ctrl;
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

  @override
  Future<DashboardBootstrapState> build() async {
    _authMeService = ref.read(authMeServiceProvider);
    _dashboardRemote = ref.read(dashboardRemoteDataSourceProvider);
    _dataService = DashboardDataService();

    // Check if we have cached data that's still fresh
    final isComplete = await _dataService.isBootstrapComplete();
    if (isComplete) {
      debugPrint('[DashboardBootstrapController] Using cached bootstrap data');
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
    if (state.isLoading) return; // Prevent concurrent runs

    state = const AsyncLoading<DashboardBootstrapState>().copyWithPrevious(
      state,
    );

    try {
      debugPrint(
        '[DashboardBootstrapController] Step 1: Fetching user profile from me_user...',
      );
      final userStopwatch = Stopwatch()..start();

      // Step 1: Call me_user FIRST to get user profile (includes userId)
      final userProfileDto = await _fetchUserProfile();

      userStopwatch.stop();
      if (userProfileDto == null) {
        throw Exception('Failed to fetch user profile from me_user API');
      }

      final userProfile = userProfileDto.toEntity();
      final effectiveHotelUserId = hotelUserId ?? userProfile.id;

      debugPrint(
        '[DashboardBootstrapController] User profile fetched in ${userStopwatch.elapsedMilliseconds}ms'
        '\n  - userId: $effectiveHotelUserId'
        '\n  - email: ${userProfile.email}',
      );

      if (effectiveHotelUserId.isEmpty) {
        throw Exception('User profile does not contain userId');
      }

      // Step 2: Now call dashboard/numbers with the userId
      debugPrint(
        '[DashboardBootstrapController] Step 2: Fetching dashboard numbers...',
      );
      final numbersStopwatch = Stopwatch()..start();

      final dashboardNumbersDto = await _fetchDashboardNumbers(
        effectiveHotelUserId,
      );

      numbersStopwatch.stop();

      final dashboardNumbers = dashboardNumbersDto != null
          ? DashboardNumbers(
              needsAcknowledgement:
                  dashboardNumbersDto.needsAcknowledgement ?? '',
              inprogress: dashboardNumbersDto.inprogress ?? '',
              overdue: dashboardNumbersDto.overdue ?? '',
              notStarted: dashboardNumbersDto.notStarted ?? '',
            )
          : null;

      debugPrint(
        '[DashboardBootstrapController] Dashboard numbers fetched in ${numbersStopwatch.elapsedMilliseconds}ms'
        '\n  - needsAcknowledgement: ${dashboardNumbers?.needsAcknowledgement}'
        '\n  - inprogress: ${dashboardNumbers?.inprogress}'
        '\n  - overdue: ${dashboardNumbers?.overdue}'
        '\n  - notStarted: ${dashboardNumbers?.notStarted}',
      );

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

      debugPrint('[DashboardBootstrapController] Bootstrap complete');
    } catch (e, st) {
      debugPrint('[DashboardBootstrapController] Bootstrap failed: $e');
      state = AsyncError(e, st);
    }
  }

  /// Fetch user profile from me_user API
  Future<UserProfileDto?> _fetchUserProfile() async {
    try {
      return await _authMeService.fetchMe();
    } catch (e) {
      debugPrint('[DashboardBootstrapController] Me user API failed: $e');
      return null;
    }
  }

  /// Fetch dashboard numbers from dashboard/numbers API
  Future<dashboard_dto.DashboardNumbersDto?> _fetchDashboardNumbers(
    String hotelUserId,
  ) async {
    try {
      return await _dashboardRemote.getNumbers(hotelUserId: hotelUserId);
    } catch (e) {
      debugPrint('[DashboardBootstrapController] Numbers API failed: $e');
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
      debugPrint('[DashboardBootstrapController] Data cached successfully');
    } catch (e) {
      debugPrint('[DashboardBootstrapController] Failed to cache data: $e');
    }
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
