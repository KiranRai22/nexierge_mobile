import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_session_controller.dart';
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
    // Watch — not read — so build() re-fires when auth hydrates after cold-start.
    final session = ref.watch(authSessionControllerProvider).valueOrNull;
    final hotelUserId = session?.user?.id;
    if (hotelUserId == null || hotelUserId.isEmpty) {
      // Auth not ready yet. Return empty placeholder; build() will re-run
      // automatically once the session resolves.
      return DashboardCounts.empty;
    }
    return _repo.fetchCounts(hotelUserId: hotelUserId);
  }

  Future<DashboardCounts> _fetch() {
    final session = ref.read(authSessionControllerProvider).valueOrNull;
    final hotelUserId = session?.user?.id;
    if (hotelUserId == null || hotelUserId.isEmpty) {
      return Future.value(
        DashboardCounts.empty,
      );
    }
    return _repo.fetchCounts(hotelUserId: hotelUserId);
  }

  /// Pull-to-refresh hook. Keeps previous data visible while reloading
  /// (state stays `AsyncData` until the new fetch resolves) so the UI
  /// doesn't flash empty during a manual refresh.
  Future<void> refresh() async {
    state = const AsyncLoading<DashboardCounts>().copyWithPrevious(state);
    state = await AsyncValue.guard(_fetch);
  }
}

final dashboardCountsControllerProvider =
    AsyncNotifierProvider<DashboardCountsController, DashboardCounts>(
      DashboardCountsController.new,
    );
