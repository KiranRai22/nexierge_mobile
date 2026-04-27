import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/error_handler.dart';
import '../../../../core/network/api_client.dart';
import '../../data/datasources/dashboard_remote_data_source.dart';
import '../../domain/entities/dashboard_counts.dart';

abstract class DashboardRepository {
  Future<HotelDetailsDto> fetchHotelDetails({String? hotelUserId});
  Future<DashboardNumbersDto> fetchNumbers({String? hotelUserId});

  /// Fetch + map dashboard KPI counts. UI / providers consume this domain
  /// model; the raw DTO never leaves the data layer.
  Future<DashboardCounts> fetchCounts({String? hotelUserId});
}

class _DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource _remote;
  _DashboardRepositoryImpl(this._remote);

  @override
  Future<HotelDetailsDto> fetchHotelDetails({String? hotelUserId}) async {
    try {
      return await _remote.getHotelDetails(hotelUserId: hotelUserId);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<DashboardNumbersDto> fetchNumbers({String? hotelUserId}) async {
    try {
      return await _remote.getNumbers(hotelUserId: hotelUserId);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<DashboardCounts> fetchCounts({String? hotelUserId}) async {
    final dto = await fetchNumbers(hotelUserId: hotelUserId);
    return DashboardCounts(
      incomingCount: _toInt(dto.pending),
      inProgressCount: _toInt(dto.tickets),
      overdueCount: _toInt(dto.dueToday),
      notStartedCount: 0,
    );
  }

  /// Defensive parse — backend ships numeric counts as strings. Null /
  /// non-numeric falls back to 0 so the UI never breaks on a stray payload.
  int _toInt(String? raw) {
    if (raw == null || raw.isEmpty) return 0;
    return int.tryParse(raw.trim()) ?? 0;
  }
}

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final remote = ref.watch(dashboardRemoteDataSourceProvider);
  return _DashboardRepositoryImpl(remote);
});
