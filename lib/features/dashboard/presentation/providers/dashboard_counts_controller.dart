import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/user_profile_controller.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../domain/entities/dashboard_counts.dart';

/// Async controller for the dashboard KPI counts. Single source of truth
/// for the four-card strip on `DashboardScreen`.
///
/// Lifecycle: not autoDispose — counts are session-wide state, kept alive
/// while the user is on the dashboard. Refresh = `ref.invalidate(provider)`
/// or call `refresh()` from pull-to-refresh.
///
/// Watches [authSessionControllerProvider] so the fetch re-runs automatically
/// once the stored session hydrates from secure storage on cold-start.
class DashboardCountsController extends AsyncNotifier<DashboardCounts> {
  late DashboardRepository _repo;

  @override
  Future<DashboardCounts> build() async {
    _repo = ref.read(dashboardRepositoryProvider);
    // Watch user profile to get hotelId
    final userProfile = ref.watch(userProfileControllerProvider).profile;
    final hotelId = userProfile?.userHotelStatus.hotelId;
    if (hotelId == null || hotelId.isEmpty) {
      // Profile not ready yet. Return empty placeholder; build() will re-run
      // automatically once the profile resolves.
      return DashboardCounts.empty;
    }
    return _repo.fetchCounts(hotelId: hotelId, today: true);
  }

  Future<DashboardCounts> _fetch() {
    final userProfile = ref.read(userProfileControllerProvider).profile;
    final hotelId = userProfile?.userHotelStatus.hotelId;
    if (hotelId == null || hotelId.isEmpty) {
      return Future.value(
        DashboardCounts.empty,
      );
    }
    return _repo.fetchCounts(hotelId: hotelId, today: true);
  }

  /// Manual refresh — drops previous data to show shimmer, then re-fetches.
  Future<void> refresh() async {
    state = const AsyncLoading<DashboardCounts>();
    state = await AsyncValue.guard(_fetch);
  }
}

final dashboardCountsControllerProvider =
    AsyncNotifierProvider<DashboardCountsController, DashboardCounts>(
      DashboardCountsController.new,
    );
