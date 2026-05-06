import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/error_handler.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/login_credentials.dart';
import '../../domain/exceptions/auth_exception.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../dtos/login_request_dto.dart';

class _AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remote;

  _AuthRepositoryImpl(this._remote);

  @override
  Future<AuthSession> signIn(LoginCredentials credentials) async {
    try {
      final dto = switch (credentials) {
        EmailPasswordCredentials c => await _remote.loginWithEmail(
          EmailLoginRequestDto(
            email: c.email,
            password: c.password,
            fcm_token: c.fcm_token,
          ),
        ),
        EmployeeCodeCredentials c => await _remote.loginWithCode(
          CodeLoginRequestDto(
            employee_code: c.employeeCode,
            code: c.loginCode,
            fcm_token: c.fcm_token,
          ),
        ),
      };
      return dto.toDomain();
    } on AuthException {
      rethrow;
    } on DioException catch (e) {
      throw mapDioError(e);
    } on FormatException catch (e) {
      throw AppException(type: AppErrorType.serverError, originalError: e);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remote = ref.watch(authRemoteDataSourceProvider);
  return _AuthRepositoryImpl(remote);
});
