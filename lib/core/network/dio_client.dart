import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/user_profile_service.dart';
import 'api_client.dart';

/// Dio client wrapper for authenticated requests
class DioClient {
  final Dio _dio;

  DioClient(this._dio);

  /// Authenticated Dio instance with bearer token
  Dio get authenticatedDio => _dio;

  /// Public Dio instance without auth token
  Dio get publicDio => _buildPublicDio();

  Dio _buildPublicDio() {
    return buildDio(authToken: null);
  }
}

/// Provider for DioClient. Builds a single Dio instance whose
/// interceptor pulls the latest bearer token from [UserProfileService]
/// (SharedPreferences) on every request. This avoids a riverpod cycle
/// between auth session, profile controller, and dio.
final dioClientProvider = Provider<DioClient>((ref) {
  final dio = buildDio(
    tokenProvider: () => UserProfileService.instance.getCachedAuthToken(),
  );
  return DioClient(dio);
});
