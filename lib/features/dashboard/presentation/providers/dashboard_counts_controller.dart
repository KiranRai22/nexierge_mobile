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
class DashboardCountsController extends AsyncNotifier<DashboardCounts> {
  late DashboardRepository _repo;

  @override
  Future<DashboardCounts> build() async {
    _repo = ref.read(dashboardRepositoryProvider);
    return _fetch();
  }

  Future<DashboardCounts> _fetch() {
    final session = ref.read(authSessionControllerProvider).valueOrNull;
    final hotelUserId = session?.user?.id;
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
