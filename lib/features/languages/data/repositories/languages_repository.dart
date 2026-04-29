import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/error_handler.dart';
import '../../../../core/network/api_client.dart';
import '../../data/datasources/languages_remote_data_source.dart';

abstract class LanguagesRepository {
  Future<List<LanguageDto>> getAll();
}

class _LanguagesRepositoryImpl implements LanguagesRepository {
  final LanguagesRemoteDataSource _remote;
  _LanguagesRepositoryImpl(this._remote);

  @override
  Future<List<LanguageDto>> getAll() async {
    try {
      return await _remote.getAll();
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}

final languagesRepositoryProvider = Provider<LanguagesRepository>((ref) {
  final remote = ref.watch(languagesRemoteDataSourceProvider);
  return _LanguagesRepositoryImpl(remote);
});
