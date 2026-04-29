import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../dtos/user_profile_dto.dart';

class AuthMeService {
  const AuthMeService(this._dio);

  final Dio _dio;

  static const String _endpoint = '${APIEndpoints.authBaseUrl}/auth/me_user';

  /// Fetch current user profile using Bearer token
  Future<UserProfileDto> fetchMe() async {
    try {
      print('[AuthMeService] Fetching profile from: $_endpoint');
      final response = await _dio.get(_endpoint);
      print('[AuthMeService] Response status: ${response.statusCode}');
      print('[AuthMeService] Response data type: ${response.data.runtimeType}');
      print('[AuthMeService] Response data: ${response.data}');

      final data = response.data;
      final status = response.statusCode ?? 0;

      // Reject non-2xx — Dio's validateStatus is permissive for <500, so
      // 401/403/4xx bodies (which are NOT UserProfile shape) reach here
      // and would crash fromJson. Surface a typed error instead.
      if (status < 200 || status >= 300) {
        final serverMessage = data is Map
            ? (data['message'] ?? data['error'])?.toString()
            : null;
        if (status == 401) {
          throw Exception('Unauthorized - token expired');
        }
        throw Exception(
          'Request failed: $status ${serverMessage ?? ''}'.trim(),
        );
      }

      // Handle null response
      if (data == null) {
        throw Exception(
          'API returned null response (status: ${response.statusCode})',
        );
      }

      // Handle different response formats
      Map<String, dynamic> jsonData;
      if (data is String) {
        // If response is a JSON string, parse it
        try {
          jsonData = jsonDecode(data) as Map<String, dynamic>;
        } catch (e) {
          throw Exception('Failed to parse JSON response: $e');
        }
      } else if (data is Map<String, dynamic>) {
        jsonData = data;
      } else {
        throw Exception('Unexpected response format: ${data.runtimeType}');
      }

      return UserProfileDto.fromJson(jsonData);
    } on DioException catch (e) {
      print('[AuthMeService] DioException: ${e.type}');
      print('[AuthMeService] DioException response: ${e.response}');
      print('[AuthMeService] DioException data: ${e.response?.data}');
      throw _mapDioError(e);
    }
  }

  Exception _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('Request timeout');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 401) {
          return Exception('Unauthorized - token expired');
        } else if (statusCode == 403) {
          return Exception('Forbidden - insufficient permissions');
        } else if (statusCode == 404) {
          return Exception('User not found');
        } else if (statusCode != null && statusCode >= 500) {
          return Exception('Server error');
        }
        return Exception('Request failed: ${statusCode ?? 'unknown'}');
      case DioExceptionType.cancel:
        return Exception('Request cancelled');
      case DioExceptionType.unknown:
        if (e.error?.toString().contains('SocketException') == true) {
          return Exception('No internet connection');
        }
        return Exception('Unknown error occurred');
      default:
        return Exception('Unexpected error');
    }
  }
}

/// Riverpod provider for AuthMeService
final authMeServiceProvider = Provider<AuthMeService>((ref) {
  final dio = ref.watch(authedDioProvider);
  return AuthMeService(dio);
});
