import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../dtos/app_version_dto.dart';

abstract class VersionControlRemoteDataSource {
  Future<AppVersionDto> fetchLatestVersion();
}

class _VersionControlRemoteDataSourceImpl
    implements VersionControlRemoteDataSource {
  final Dio _dio;

  _VersionControlRemoteDataSourceImpl(this._dio);

  @override
  Future<AppVersionDto> fetchLatestVersion() async {
    final response = await _dio.get(APIEndpoints.versionControl);
    if (response.statusCode != 200) {
      throw Exception(
        '[VersionControl] Unexpected status ${response.statusCode}',
      );
    }
    final data = response.data as Map<String, dynamic>;
    return AppVersionDto.fromJson(data);
  }
}

final versionControlRemoteDataSourceProvider =
    Provider<VersionControlRemoteDataSource>((ref) {
      final dio = ref.watch(authedDioProvider);
      return _VersionControlRemoteDataSourceImpl(dio);
    });
