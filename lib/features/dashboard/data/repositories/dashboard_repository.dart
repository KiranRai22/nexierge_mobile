import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/error_handler.dart';
import '../../../../core/network/api_client.dart';
import '../../data/datasources/dashboard_remote_data_source.dart';

abstract class DashboardRepository {
  Future<HotelDetailsDto> fetchHotelDetails({String? hotelUserId});
  Future<DashboardNumbersDto> fetchNumbers({String? hotelUserId});
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
}

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final remote = ref.watch(dashboardRemoteDataSourceProvider);
  return _DashboardRepositoryImpl(remote);
});
