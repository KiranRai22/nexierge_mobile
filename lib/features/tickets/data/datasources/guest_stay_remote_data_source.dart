import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';

/// Network-facing layer for guest_stay endpoints.
abstract class GuestStayRemoteDataSource {
  Future<List<CheckedInGuestStayDto>> getCheckedIn({required String hotelId});
}

class _GuestStayRemoteDataSourceImpl implements GuestStayRemoteDataSource {
  final Dio _dio;
  _GuestStayRemoteDataSourceImpl(this._dio);

  @override
  Future<List<CheckedInGuestStayDto>> getCheckedIn({
    required String hotelId,
  }) async {
    debugPrint(
      '[GuestStayRemoteDataSource] GET ${APIEndpoints.guestStayCheckedIn} '
      'hotel_id=$hotelId',
    );
    final res = await _dio.get(
      APIEndpoints.guestStayCheckedIn,
      queryParameters: {'hotel_id': hotelId},
    );
    final list = (res.data as List?) ?? const [];
    debugPrint(
      '[GuestStayRemoteDataSource] status=${res.statusCode} '
      'count=${list.length}',
    );
    return list
        .map((e) => CheckedInGuestStayDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final guestStayRemoteDataSourceProvider = Provider<GuestStayRemoteDataSource>((
  ref,
) {
  final dio = ref.watch(authedDioProvider);
  return _GuestStayRemoteDataSourceImpl(dio);
});

/// Raw row DTO. Keeps the wire shape; mapping to the domain entity happens
/// in the repository.
class CheckedInGuestStayDto {
  final String id;
  final String? roomTypeId;
  final String? contactId;
  final List<dynamic>? secondaryContacts;
  final String status;
  final String checkinDate;
  final String checkoutDate;
  final RoomDetailsDto? roomDetails;
  final ContactDetailsDto? contactDetails;

  const CheckedInGuestStayDto({
    required this.id,
    required this.status,
    required this.checkinDate,
    required this.checkoutDate,
    this.roomTypeId,
    this.contactId,
    this.secondaryContacts,
    this.roomDetails,
    this.contactDetails,
  });

  factory CheckedInGuestStayDto.fromJson(Map<String, dynamic> json) {
    String s(String k) => (json[k] as String?) ?? '';
    return CheckedInGuestStayDto(
      id: s('id'),
      roomTypeId: json['room_type_id'] as String?,
      contactId: json['contact_id'] as String?,
      secondaryContacts: json['secondary_contacts'] as List<dynamic>?,
      status: s('status'),
      checkinDate: s('checkin_date'),
      checkoutDate: s('checkout_date'),
      roomDetails: json['room_details'] is Map<String, dynamic>
          ? RoomDetailsDto.fromJson(json['room_details'] as Map<String, dynamic>)
          : null,
      contactDetails: json['contact_details'] is Map<String, dynamic>
          ? ContactDetailsDto.fromJson(
              json['contact_details'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class RoomDetailsDto {
  final String id;
  final String onbRoomNumber;
  const RoomDetailsDto({required this.id, required this.onbRoomNumber});

  factory RoomDetailsDto.fromJson(Map<String, dynamic> json) => RoomDetailsDto(
    id: (json['id'] as String?) ?? '',
    onbRoomNumber: (json['onb_room_number'] as String?) ?? '',
  );
}

class ContactDetailsDto {
  final String id;
  final String fullName;
  final String? firstName;
  final String? lastName;
  final String? languageCode;
  final String? countryCode;

  const ContactDetailsDto({
    required this.id,
    required this.fullName,
    this.firstName,
    this.lastName,
    this.languageCode,
    this.countryCode,
  });

  factory ContactDetailsDto.fromJson(Map<String, dynamic> json) =>
      ContactDetailsDto(
        id: (json['id'] as String?) ?? '',
        fullName: (json['full_name'] as String?) ?? '',
        firstName: json['first_name'] as String?,
        lastName: json['last_name'] as String?,
        languageCode: json['language_code'] as String?,
        countryCode: json['country_code'] as String?,
      );
}
