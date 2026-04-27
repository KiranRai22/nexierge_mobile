import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';

abstract class RoomsRemoteDataSource {
  Future<RoomDetailsDto> getRoomDetails({required String roomId});
  Future<List<RoomDto>> getAll({required String hotelId, String? status});
  Future<RoomDto> updateStatus({
    required String roomId,
    required String status,
  });
  Future<void> approveStatusChange({required int roomEventId});
}

class _RoomsRemoteDataSourceImpl implements RoomsRemoteDataSource {
  final Dio _dio;
  _RoomsRemoteDataSourceImpl(this._dio);

  @override
  Future<RoomDetailsDto> getRoomDetails({required String roomId}) async {
    final res = await _dio.post(
      APIEndpoints.roomsDetails,
      data: {'room_id': roomId},
    );
    final data = res.data as Map<String, dynamic>;
    return RoomDetailsDto.fromJson(data['room'] as Map<String, dynamic>);
  }

  @override
  Future<List<RoomDto>> getAll({
    required String hotelId,
    String? status,
  }) async {
    final res = await _dio.post(
      APIEndpoints.roomsGetAll,
      data: {'hotel_id': hotelId, 'status': status},
    );
    final data = res.data as List<dynamic>;
    return data
        .map((e) => RoomDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<RoomDto> updateStatus({
    required String roomId,
    required String status,
  }) async {
    final res = await _dio.post(
      APIEndpoints.roomsUpdateStatus,
      data: {'room_id': roomId, 'status': status},
    );
    final data = res.data as Map<String, dynamic>;
    return RoomDto.fromJson(data);
  }

  @override
  Future<void> approveStatusChange({required int roomEventId}) async {
    await _dio.post(
      APIEndpoints.roomsApproveStatusChange,
      data: {'room_event_id': roomEventId},
    );
  }
}

final roomsRemoteDataSourceProvider = Provider<RoomsRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return _RoomsRemoteDataSourceImpl(dio);
});

class RoomDto {
  final String id;
  final String? status;
  final String? onbRoomNumber;

  RoomDto({required this.id, this.status, this.onbRoomNumber});

  factory RoomDto.fromJson(Map<String, dynamic> json) => RoomDto(
    id: json['id'] as String,
    status: json['status'] as String?,
    onbRoomNumber: json['onb_room_number'] as String?,
  );
}

class RoomDetailsDto {
  final RoomDto room;
  // sessions omitted for brevity
  RoomDetailsDto({required this.room});

  factory RoomDetailsDto.fromJson(Map<String, dynamic> json) => RoomDetailsDto(
    room: RoomDto.fromJson(json['room'] as Map<String, dynamic>),
  );
}
