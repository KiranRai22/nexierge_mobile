import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/error_handler.dart';
import '../../../../core/network/api_client.dart';
import '../datasources/guest_stay_remote_data_source.dart';
import '../../domain/entities/checked_in_guest_stay.dart';

abstract class GuestStayRepository {
  Future<List<CheckedInGuestStay>> fetchCheckedIn({required String hotelId});
}

class _GuestStayRepositoryImpl implements GuestStayRepository {
  final GuestStayRemoteDataSource _remote;
  _GuestStayRepositoryImpl(this._remote);

  @override
  Future<List<CheckedInGuestStay>> fetchCheckedIn({
    required String hotelId,
  }) async {
    try {
      final dtos = await _remote.getCheckedIn(hotelId: hotelId);
      final mapped = <CheckedInGuestStay>[];
      for (final d in dtos) {
        // Skip rows missing the bits we need to be useful.
        final roomId = d.roomDetails?.id ?? '';
        final roomNumber = d.roomDetails?.onbRoomNumber ?? '';
        final contactId = d.contactId ?? d.contactDetails?.id ?? '';
        if (d.id.isEmpty || roomId.isEmpty || contactId.isEmpty) continue;
        mapped.add(
          CheckedInGuestStay(
            guestStayId: d.id,
            roomId: roomId,
            roomNumber: roomNumber,
            contactId: contactId,
            fullName: d.contactDetails?.fullName ?? '',
            firstName: d.contactDetails?.firstName,
            lastName: d.contactDetails?.lastName,
            languageCode: d.contactDetails?.languageCode,
            countryCode: d.contactDetails?.countryCode,
            status: d.status,
            checkinDate: d.checkinDate,
            checkoutDate: d.checkoutDate,
            roomTypeId: d.roomTypeId,
            secondaryContacts: d.secondaryContacts,
          ),
        );
      }
      // Sort by room number — numeric where parseable, alphabetical otherwise.
      // Same rule as fetchTicketFormOptions for picker consistency.
      mapped.sort((a, b) {
        final na = int.tryParse(a.roomNumber);
        final nb = int.tryParse(b.roomNumber);
        if (na != null && nb != null) return na.compareTo(nb);
        if (na != null) return -1;
        if (nb != null) return 1;
        return a.roomNumber.compareTo(b.roomNumber);
      });
      return mapped;
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}

final guestStayRepositoryProvider = Provider<GuestStayRepository>((ref) {
  final remote = ref.watch(guestStayRemoteDataSourceProvider);
  return _GuestStayRepositoryImpl(remote);
});
