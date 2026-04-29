import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_client.dart';

/// Remote data source for dashboard endpoints.
abstract class DashboardRemoteDataSource {
  Future<HotelDetailsDto> getHotelDetails({String? hotelUserId});
  Future<DashboardNumbersDto> getNumbers({String? hotelUserId});
  Future<List<NeedsAttentionDto>> getNeedsAttention({required String hotelId});
}

class _DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final Dio _dio;
  _DashboardRemoteDataSourceImpl(this._dio);

  @override
  Future<HotelDetailsDto> getHotelDetails({String? hotelUserId}) async {
    final res = await _dio.get(
      APIEndpoints.dashboardHotelDetails,
      queryParameters: {'hotel_user_id': hotelUserId ?? ''},
    );
    final data = res.data as Map<String, dynamic>;
    return HotelDetailsDto.fromJson(data);
  }

  @override
  Future<DashboardNumbersDto> getNumbers({String? hotelUserId}) async {
    try {
      final res = await _dio.get(
        APIEndpoints.dashboardNumbers,
        queryParameters: {'hotel_user_id': hotelUserId ?? ''},
      );

      final Map<String, dynamic> data;
      if (res.data is Map<String, dynamic>) {
        data = res.data as Map<String, dynamic>;
      } else if (res.data is String) {
        try {
          data = jsonDecode(res.data as String) as Map<String, dynamic>;
        } catch (e) {
          throw Exception('Failed to parse numbers response');
        }
      } else {
        throw Exception('Unexpected response type: ${res.data?.runtimeType}');
      }

      return DashboardNumbersDto.fromJson(data);
    } catch (e) {
      debugPrint('[DashboardRemoteDataSource] Numbers API failed: $e');
      rethrow;
    }
  }

  @override
  Future<List<NeedsAttentionDto>> getNeedsAttention({
    required String hotelId,
  }) async {
    try {
      final res = await _dio.get(
        APIEndpoints.dashboardNeedsAttention,
        queryParameters: {'hotel_id': hotelId},
      );

      if (res.data is! List) {
        throw Exception('Expected list, got ${res.data.runtimeType}');
      }

      final list = res.data as List;
      return list
          .map((e) => NeedsAttentionDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[DashboardRemoteDataSource] Needs attention API failed: $e');
      rethrow;
    }
  }
}

final dashboardRemoteDataSourceProvider = Provider<DashboardRemoteDataSource>((
  ref,
) {
  final dio = ref.watch(authedDioProvider);
  return _DashboardRemoteDataSourceImpl(dio);
});

/// DTOs
class HotelDetailsDto {
  final String? name;
  final String? city;
  final int? staff;
  final String? department;
  final int? staffInDepartment;
  final int? totalRooms;
  final int? occupiedRooms;
  final int? checkinsToday;
  final int? checkoutsToday;

  HotelDetailsDto({
    this.name,
    this.city,
    this.staff,
    this.department,
    this.staffInDepartment,
    this.totalRooms,
    this.occupiedRooms,
    this.checkinsToday,
    this.checkoutsToday,
  });

  factory HotelDetailsDto.fromJson(Map<String, dynamic> json) =>
      HotelDetailsDto(
        name: json['name'] as String?,
        city: json['city'] as String?,
        staff: json['staff'] as int?,
        department: json['department'] as String?,
        staffInDepartment: json['staff_in_department'] as int?,
        totalRooms: json['total_rooms'] as int?,
        occupiedRooms: json['occupied_rooms'] as int?,
        checkinsToday: json['checkins_today'] as int?,
        checkoutsToday: json['checkouts_today'] as int?,
      );
}

class DashboardNumbersDto {
  final String? needsAcknowledgement;
  final String? inprogress;
  final String? overdue;
  final String? notStarted;

  DashboardNumbersDto({
    this.needsAcknowledgement,
    this.inprogress,
    this.overdue,
    this.notStarted,
  });

  factory DashboardNumbersDto.fromJson(Map<String, dynamic> json) {
    // Debug: log all keys in the response
    debugPrint(
      '[DashboardNumbersDto] Parsing JSON keys: ${json.keys.toList()}',
    );

    return DashboardNumbersDto(
      needsAcknowledgement: json['needs_acknowledgement']?.toString(),
      inprogress: json['in_progress']?.toString(),
      overdue: json['overdue']?.toString(),
      notStarted: json['not_started']?.toString(),
    );
  }
}

class NeedsAttentionDto {
  final String id;
  final int createdAt;
  final String departmentId;
  final String status;
  final int dueAt;
  final String room;
  final String guestName;
  final int acknowledgedAt;
  final DepartmentInfoDto department;
  final String onbRoomNumber;

  NeedsAttentionDto({
    required this.id,
    required this.createdAt,
    required this.departmentId,
    required this.status,
    required this.dueAt,
    required this.room,
    required this.guestName,
    required this.acknowledgedAt,
    required this.department,
    required this.onbRoomNumber,
  });

  factory NeedsAttentionDto.fromJson(Map<String, dynamic> json) {
    return NeedsAttentionDto(
      id: json['id'] as String,
      createdAt: json['created_at'] as int,
      departmentId: json['department_id'] as String,
      status: json['status'] as String,
      dueAt: json['due_at'] as int,
      room: json['room'] as String,
      guestName: json['guest_name'] as String,
      acknowledgedAt: json['acknowledged_at'] as int,
      department: DepartmentInfoDto.fromJson(
        json['_department'] as Map<String, dynamic>,
      ),
      onbRoomNumber: json['onb_room_number'] as String,
    );
  }
}

class DepartmentInfoDto {
  final String name;
  final String mobileIcon;
  final IconInfoDto icon;

  DepartmentInfoDto({
    required this.name,
    required this.mobileIcon,
    required this.icon,
  });

  factory DepartmentInfoDto.fromJson(Map<String, dynamic> json) {
    return DepartmentInfoDto(
      name: json['name'] as String,
      mobileIcon: json['mobile_icon'] as String,
      icon: IconInfoDto.fromJson(json['icon'] as Map<String, dynamic>),
    );
  }
}

class IconInfoDto {
  final String url;

  IconInfoDto({required this.url});

  factory IconInfoDto.fromJson(Map<String, dynamic> json) {
    return IconInfoDto(url: json['url'] as String);
  }
}
