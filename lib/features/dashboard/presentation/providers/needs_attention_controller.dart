import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/dashboard_bootstrap_controller.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../domain/entities/needs_attention_item.dart';

/// Async controller for needs attention items. Single source of truth
/// for the needs attention list on DashboardScreen.
///
/// Lifecycle: not autoDispose — data is session-wide state, kept alive
/// while the user is on the dashboard. Refresh = ref.invalidate(provider)
/// or call refresh() from pull-to-refresh.
///
/// Watches [dashboardBootstrapControllerProvider] so the fetch re-runs automatically
/// once the bootstrap completes.
class NeedsAttentionController extends AsyncNotifier<List<NeedsAttentionItem>> {
  late DashboardRepository _repo;

  @override
  Future<List<NeedsAttentionItem>> build() async {
    _repo = ref.read(dashboardRepositoryProvider);
    // Watch bootstrap for hotelId from full user profile
    final bootstrap = ref
        .watch(dashboardBootstrapControllerProvider)
        .valueOrNull;
    final hotelId = bootstrap?.userProfile?.hotelDetails.hotel.id;
    if (hotelId == null || hotelId.isEmpty) {
      // Bootstrap not ready yet. Return empty placeholder; build() will re-run
      // automatically once bootstrap resolves.
      return const [];
    }
    return _repo.fetchNeedsAttention(hotelId: hotelId);
  }

  Future<List<NeedsAttentionItem>> _fetch() {
    final bootstrap = ref
        .read(dashboardBootstrapControllerProvider)
        .valueOrNull;
    final hotelId = bootstrap?.userProfile?.hotelDetails.hotel.id;
    if (hotelId == null || hotelId.isEmpty) {
      return Future.value(const []);
    }
    return _repo.fetchNeedsAttention(hotelId: hotelId);
  }

  /// Manual refresh — drops previous data to show the shimmer skeleton,
  /// then re-fetches from the API.
  Future<void> refresh() async {
    state = const AsyncLoading<List<NeedsAttentionItem>>();
    state = await AsyncValue.guard(_fetch);
  }
}

final needsAttentionControllerProvider =
    AsyncNotifierProvider<NeedsAttentionController, List<NeedsAttentionItem>>(
      NeedsAttentionController.new,
    );
