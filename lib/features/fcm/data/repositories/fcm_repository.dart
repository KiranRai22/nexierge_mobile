import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/error_handler.dart';
import '../../../../core/network/api_client.dart';
import '../../data/datasources/fcm_remote_data_source.dart';

abstract class FcmRepository {
  Future<void> update({required String deviceType, required String fcmToken});
}

class _FcmRepositoryImpl implements FcmRepository {
  final FcmRemoteDataSource _remote;
  _FcmRepositoryImpl(this._remote);

  @override
  Future<void> update({
    required String deviceType,
    required String fcmToken,
  }) async {
    try {
      return await _remote.update(deviceType: deviceType, fcmToken: fcmToken);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}

final fcmRepositoryProvider = Provider<FcmRepository>((ref) {
  final remote = ref.watch(fcmRemoteDataSourceProvider);
  return _FcmRepositoryImpl(remote);
});
