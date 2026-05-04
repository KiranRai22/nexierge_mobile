import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dashboard/presentation/providers/dashboard_bootstrap_controller.dart';
import '../../data/repositories/ticket_repository.dart';
import '../../domain/entities/ticket_form_options.dart';

/// Shared async fetch of department options.
///
/// Backed by `/tickets/add/get_departnents_and_rooms` API; the `rooms`
/// half of the response is intentionally ignored — rooms are sourced from
/// `checkedInGuestStaysProvider` instead. Uses keepAlive so data persists
/// across screens (create flow, tickets filter, etc). Auto-refreshes when
/// hotel changes (via bootstrap watch). Call invalidate() to force refresh.
final ticketFormOptionsProvider = FutureProvider<TicketFormOptions>((
  ref,
) async {
  final bootstrap = ref.watch(dashboardBootstrapControllerProvider).valueOrNull;
  final hotelId = bootstrap?.userProfile?.hotelDetails.hotel.id;
  if (hotelId == null || hotelId.isEmpty) {
    debugPrint('[ticketFormOptionsProvider] No hotelId, returning empty');
    return TicketFormOptions.empty;
  }
  debugPrint('[ticketFormOptionsProvider] Fetching for hotel: $hotelId');
  final repo = ref.read(ticketRepositoryProvider);
  final result = await repo.fetchTicketFormOptions(hotelId: hotelId);
  debugPrint(
    '[ticketFormOptionsProvider] Loaded ${result.departments.length} depts',
  );
  return result;
});

/// Convenience: just the departments slice.
/// Keeps provider alive via ticketFormOptionsProvider cache.
/// Use this in filters, create forms, etc.
final apiDepartmentsProvider = Provider<List<HotelDepartment>>((ref) {
  return ref
      .watch(ticketFormOptionsProvider)
      .maybeWhen(data: (o) => o.departments, orElse: () => const []);
});

/// Async version for loading states.
final apiDepartmentsAsyncProvider = Provider<AsyncValue<List<HotelDepartment>>>(
  (ref) {
    return ref
        .watch(ticketFormOptionsProvider)
        .when(
          data: (o) => AsyncData(o.departments),
          loading: () => const AsyncLoading(),
          error: (e, st) => AsyncError(e, st),
        );
  },
);
