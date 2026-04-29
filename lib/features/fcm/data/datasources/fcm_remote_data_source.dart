import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';

abstract class FcmRemoteDataSource {
  Future<void> update({required String deviceType, required String fcmToken});
}

class _FcmRemoteDataSourceImpl implements FcmRemoteDataSource {
  final Dio _dio;
  _FcmRemoteDataSourceImpl(this._dio);

  @override
  Future<void> update({
    required String deviceType,
    required String fcmToken,
  }) async {
    await _dio.post(
      APIEndpoints.fcmUpdate,
      data: {'device_type': deviceType, 'fcm_token': fcmToken},
    );
  }
}

final fcmRemoteDataSourceProvider = Provider<FcmRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return _FcmRemoteDataSourceImpl(dio);
});
