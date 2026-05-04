import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dashboard/presentation/providers/dashboard_bootstrap_controller.dart';
import '../../data/repositories/guest_stay_repository.dart';
import '../../domain/entities/checked_in_guest_stay.dart';

/// Currently-staying guests for the active hotel.
///
/// Backs the room picker in the ticket-create flow: each row maps a
/// display room number to a `guest_stay_id` + `contact_id` so submit
/// can stamp the payload without an extra round-trip.
///
/// Auto-rebuilds when the dashboard's hotel context changes. Call
/// `ref.invalidate(checkedInGuestStaysProvider)` to force refresh.
final checkedInGuestStaysProvider =
    FutureProvider<List<CheckedInGuestStay>>((ref) async {
  final bootstrap = ref.watch(dashboardBootstrapControllerProvider).valueOrNull;
  final hotelId = bootstrap?.userProfile?.hotelDetails.hotel.id;
  if (hotelId == null || hotelId.isEmpty) {
    debugPrint('[checkedInGuestStaysProvider] No hotelId, returning empty');
    return const [];
  }
  debugPrint('[checkedInGuestStaysProvider] Fetching for hotel: $hotelId');
  final repo = ref.read(guestStayRepositoryProvider);
  final result = await repo.fetchCheckedIn(hotelId: hotelId);
  debugPrint('[checkedInGuestStaysProvider] Loaded ${result.length} stays');
  return result;
});

/// Lookup helper: O(1) by guestStayId. Returns null if not found.
final checkedInStayByIdProvider =
    Provider.family<CheckedInGuestStay?, String>((ref, guestStayId) {
  final list = ref
      .watch(checkedInGuestStaysProvider)
      .maybeWhen(data: (l) => l, orElse: () => const <CheckedInGuestStay>[]);
  for (final s in list) {
    if (s.guestStayId == guestStayId) return s;
  }
  return null;
});
