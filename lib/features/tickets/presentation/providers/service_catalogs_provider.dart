import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dashboard/presentation/providers/dashboard_bootstrap_controller.dart';
import '../../data/repositories/ticket_repository.dart';
import '../../domain/entities/service_catalog.dart';

/// State for service catalogs
class ServiceCatalogsState {
  final List<ServiceCatalog> catalogs;
  final bool isLoading;
  final String? error;

  ServiceCatalogsState({
    this.catalogs = const [],
    this.isLoading = false,
    this.error,
  });

  ServiceCatalogsState copyWith({
    List<ServiceCatalog>? catalogs,
    bool? isLoading,
    String? error,
  }) {
    return ServiceCatalogsState(
      catalogs: catalogs ?? this.catalogs,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for fetching service catalogs
class ServiceCatalogsNotifier extends AutoDisposeAsyncNotifier<ServiceCatalogsState> {
  @override
  Future<ServiceCatalogsState> build() async {
    // Get hotelId from dashboard bootstrap
    final bootstrap = ref
        .watch(dashboardBootstrapControllerProvider)
        .valueOrNull;
    final hotelId = bootstrap?.userProfile?.hotelDetails.hotel.id;

    if (hotelId == null || hotelId.isEmpty) {
      debugPrint('[ServiceCatalogsNotifier] No hotelId from bootstrap');
      return ServiceCatalogsState();
    }

    return _fetchCatalogs(hotelId);
  }

  Future<ServiceCatalogsState> _fetchCatalogs(String hotelId) async {
    try {
      debugPrint('[ServiceCatalogsNotifier] Fetching catalogs for hotel: $hotelId');
      final repo = ref.read(ticketRepositoryProvider);
      final catalogs = await repo.fetchServiceCatalogs(hotelId: hotelId);
      debugPrint('[ServiceCatalogsNotifier] Fetched ${catalogs.length} catalogs');
      return ServiceCatalogsState(catalogs: catalogs);
    } catch (e, st) {
      debugPrint('[ServiceCatalogsNotifier] Error fetching catalogs: $e');
      debugPrint('[ServiceCatalogsNotifier] Stack trace: $st');
      return ServiceCatalogsState(error: e.toString());
    }
  }

  /// Refresh catalogs from API
  Future<void> refresh() async {
    state = const AsyncLoading<ServiceCatalogsState>().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      final bootstrap = ref
          .read(dashboardBootstrapControllerProvider)
          .valueOrNull;
      final hotelId = bootstrap?.userProfile?.hotelDetails.hotel.id;
      if (hotelId == null || hotelId.isEmpty) {
        return ServiceCatalogsState(error: 'No hotel selected');
      }
      return _fetchCatalogs(hotelId);
    });
  }
}

/// Provider for service catalogs
final serviceCatalogsNotifierProvider =
    AsyncNotifierProvider.autoDispose<ServiceCatalogsNotifier, ServiceCatalogsState>(
  ServiceCatalogsNotifier.new,
);

/// Provider for just the list of catalogs (simplified access)
final serviceCatalogsListProvider = Provider<List<ServiceCatalog>>((ref) {
  final asyncState = ref.watch(serviceCatalogsNotifierProvider);
  return asyncState.when(
    data: (state) => state.catalogs,
    loading: () => [],
    error: (_, __) => [],
  );
});
