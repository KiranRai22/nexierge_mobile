import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/exceptions/auth_exception.dart';
import '../dtos/login_request_dto.dart';
import '../dtos/login_response_dto.dart';

/// Network-level entry point. The repository is the only caller; nothing
/// in the UI imports this.
abstract class AuthRemoteDataSource {
  Future<LoginResponseDto> loginWithEmail(EmailLoginRequestDto body);
  Future<LoginResponseDto> loginWithCode(CodeLoginRequestDto body);
}

class _AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio _dio;

  _AuthRemoteDataSourceImpl(this._dio);

  @override
  Future<LoginResponseDto> loginWithEmail(EmailLoginRequestDto body) =>
      _post(APIEndpoints.loginEmail, body.toJson());

  @override
  Future<LoginResponseDto> loginWithCode(CodeLoginRequestDto body) =>
      _post(APIEndpoints.loginCode, body.toJson());

  Future<LoginResponseDto> _post(String url, Map<String, dynamic> body) async {
    try {
      final res = await _dio.post<dynamic>(url, data: body);
      final data = res.data;
      if (res.statusCode == 200 && data is Map<String, dynamic>) {
        return LoginResponseDto.fromJson(data);
      }
      throw _mapHttpFailure(res.statusCode, data);
    } on DioException catch (e) {
      // Surface bad-status responses (4xx) as auth failures when possible
      // before they hit the generic transport mapper.
      final res = e.response;
      if (res != null && (res.statusCode ?? 0) >= 400) {
        throw _mapHttpFailure(res.statusCode, res.data);
      }
      rethrow;
    }
  }

  AuthException _mapHttpFailure(int? status, dynamic data) {
    final message = _readMessage(data);
    final code = _readCode(data);
    final reason = _reasonFromCode(code) ??
        _reasonFromStatus(status) ??
        AuthFailureReason.generic;
    return AuthException(reason: reason, serverMessage: message);
  }

  String? _readMessage(dynamic data) {
    if (data is Map) {
      final m = data['message'] ?? data['error'] ?? data['detail'];
      if (m is String && m.trim().isNotEmpty) return m.trim();
    }
    return null;
  }

  String? _readCode(dynamic data) {
    if (data is Map) {
      final c = data['code'] ?? data['error_code'] ?? data['reason'];
      if (c is String) return c.toLowerCase();
    }
    return null;
  }

  AuthFailureReason? _reasonFromCode(String? code) {
    if (code == null) return null;
    if (code.contains('expired')) return AuthFailureReason.codeExpired;
    if (code.contains('pending')) return AuthFailureReason.pendingReview;
    if (code.contains('rejected')) return AuthFailureReason.rejected;
    if (code.contains('disabled')) return AuthFailureReason.disabled;
    if (code.contains('hotel') && code.contains('inactive')) {
      return AuthFailureReason.inactiveHotel;
    }
    if (code.contains('invalid')) return AuthFailureReason.invalidCredentials;
    return null;
  }

  AuthFailureReason? _reasonFromStatus(int? status) {
    if (status == 401 || status == 422) {
      return AuthFailureReason.invalidCredentials;
    }
    if (status == 403) return AuthFailureReason.disabled;
    return null;
  }
}

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return _AuthRemoteDataSourceImpl(dio);
});
