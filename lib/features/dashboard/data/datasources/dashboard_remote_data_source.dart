import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_client.dart';

/// Remote data source for dashboard endpoints.
abstract class DashboardRemoteDataSource {
  Future<HotelDetailsDto> getHotelDetails({String? hotelUserId});
  Future<DashboardNumbersDto> getNumbers({String? hotelId, bool today});
  Future<List<NeedsAttentionDto>> getNeedsAttention({required String hotelId});
}

class _DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final Dio _dio;
  _DashboardRemoteDataSourceImpl(this._dio);

  @override
  Future<HotelDetailsDto> getHotelDetails({String? hotelUserId}) async {
    try {
      final res = await _dio.get(
        APIEndpoints.dashboardHotelDetails,
        queryParameters: {'hotel_user_id': hotelUserId ?? ''},
      );

      final Map<String, dynamic> data;
      if (res.data is Map<String, dynamic>) {
        data = res.data as Map<String, dynamic>;
      } else if (res.data is String && (res.data as String).isNotEmpty) {
        try {
          data = jsonDecode(res.data as String) as Map<String, dynamic>;
        } catch (_) {
          throw Exception('Failed to parse hotel details response');
        }
      } else {
        // Backend can return null/empty when the user has no hotel context.
        // Treat as an empty payload rather than crashing the bootstrap.
        debugPrint(
          '[DashboardRemoteDataSource] Hotel details: empty/null response '
          '(${res.data?.runtimeType}); returning empty DTO',
        );
        return HotelDetailsDto();
      }

      return HotelDetailsDto.fromJson(data);
    } catch (e) {
      debugPrint('[DashboardRemoteDataSource] Hotel details API failed: $e');
      rethrow;
    }
  }

  @override
  Future<DashboardNumbersDto> getNumbers({String? hotelId, bool today = false}) async {
    try {
      final queryParams = {'hotel_id': hotelId ?? ''};
      if (today) {
        queryParams['today'] = 'true';
      }
      final res = await _dio.get(
        APIEndpoints.dashboardNumbers,
        queryParameters: queryParams,
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

      final List rawList;
      if (res.data is List) {
        rawList = res.data as List;
      } else if (res.data is Map<String, dynamic>) {
        final map = res.data as Map<String, dynamic>;
        debugPrint('[DashboardRemoteDataSource] Needs attention wrapped response keys: ${map.keys.toList()}');
        // Try common wrapper keys
        final candidate = map['items'] ?? map['data'] ?? map['result'] ?? map['tickets'];
        if (candidate is List) {
          rawList = candidate;
        } else {
          throw Exception('Expected list, got Map with keys: ${map.keys.toList()}');
        }
      } else {
        throw Exception('Expected list, got ${res.data.runtimeType}');
      }

      return rawList
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
  final String? inprogress;
  final String? overdue;
  final String? notStarted;
  final String? done;

  DashboardNumbersDto({
    this.inprogress,
    this.overdue,
    this.notStarted,
    this.done,
  });

  factory DashboardNumbersDto.fromJson(Map<String, dynamic> json) {
    // Debug: log all keys in the response
    debugPrint(
      '[DashboardNumbersDto] Parsing JSON keys: ${json.keys.toList()}',
    );

    return DashboardNumbersDto(
      inprogress: json['in_progress']?.toString(),
      overdue: json['overdue']?.toString(),
      notStarted: json['not_started']?.toString(),
      done: json['done']?.toString(),
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
    String s(String k) => (json[k] as String?) ?? '';
    int i(String k) => (json[k] as num?)?.toInt() ?? 0;
    // API v2: department is a direct object under 'department' key.
    final dept = json['department'] ?? json['_department'];
    // Room number lives inside the nested 'room_data' object.
    final roomData = json['room_data'];
    final onbRoomNumber = roomData is Map<String, dynamic>
        ? (roomData['onb_room_number'] as String?) ?? ''
        : s('onb_room_number');
    return NeedsAttentionDto(
      id: s('id'),
      createdAt: i('created_at'),
      departmentId: s('department_id'),
      status: s('status'),
      dueAt: i('due_at'),
      room: s('room'),
      guestName: s('guest_name'),
      acknowledgedAt: i('acknowledged_at'),
      department: dept is Map<String, dynamic>
          ? DepartmentInfoDto.fromJson(dept)
          : DepartmentInfoDto.empty(),
      onbRoomNumber: onbRoomNumber,
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

  factory DepartmentInfoDto.empty() => DepartmentInfoDto(
        name: '',
        mobileIcon: '',
        icon: IconInfoDto.empty(),
      );

  factory DepartmentInfoDto.fromJson(Map<String, dynamic> json) {
    final icon = json['icon'];
    return DepartmentInfoDto(
      name: (json['name'] as String?) ?? '',
      mobileIcon: (json['mobile_icon'] as String?) ?? '',
      icon: icon is Map<String, dynamic>
          ? IconInfoDto.fromJson(icon)
          : IconInfoDto.empty(),
    );
  }
}

class IconInfoDto {
  final String url;

  IconInfoDto({required this.url});

  factory IconInfoDto.empty() => IconInfoDto(url: '');

  factory IconInfoDto.fromJson(Map<String, dynamic> json) {
    return IconInfoDto(url: (json['url'] as String?) ?? '');
  }
}
