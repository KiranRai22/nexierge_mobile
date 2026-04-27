import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_client.dart';

/// Remote data source for dashboard endpoints.
abstract class DashboardRemoteDataSource {
  Future<HotelDetailsDto> getHotelDetails({String? hotelUserId});
  Future<DashboardNumbersDto> getNumbers({String? hotelUserId});
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
    final res = await _dio.get(
      APIEndpoints.dashboardNumbers,
      queryParameters: {'hotel_user_id': hotelUserId ?? ''},
    );
    final data = res.data as Map<String, dynamic>;
    return DashboardNumbersDto.fromJson(data);
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
  final String? tickets;
  final String? dueToday;
  final String? pending;

  DashboardNumbersDto({this.tickets, this.dueToday, this.pending});

  factory DashboardNumbersDto.fromJson(Map<String, dynamic> json) =>
      DashboardNumbersDto(
        tickets: json['tickets'] as String?,
        dueToday: json['due_today'] as String?,
        pending: json['pending'] as String?,
      );
}
