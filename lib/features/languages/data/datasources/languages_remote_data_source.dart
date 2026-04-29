import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';

abstract class LanguagesRemoteDataSource {
  Future<List<LanguageDto>> getAll();
}

class _LanguagesRemoteDataSourceImpl implements LanguagesRemoteDataSource {
  final Dio _dio;
  _LanguagesRemoteDataSourceImpl(this._dio);

  @override
  Future<List<LanguageDto>> getAll() async {
    final res = await _dio.get(APIEndpoints.languagesAll);
    final data = res.data as List<dynamic>;
    return data
        .map((e) => LanguageDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final languagesRemoteDataSourceProvider = Provider<LanguagesRemoteDataSource>((
  ref,
) {
  final dio = ref.watch(dioProvider);
  return _LanguagesRemoteDataSourceImpl(dio);
});

class LanguageDto {
  final String id;
  final String name;

  LanguageDto({required this.id, required this.name});

  factory LanguageDto.fromJson(Map<String, dynamic> json) => LanguageDto(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
  );
}
