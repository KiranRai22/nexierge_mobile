import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// Provider for DioClient. Token is read via [authTokenProviderOverride]
/// which is overridden in main.dart to return the live session token from
/// [AuthSessionController] (secure storage). This is the single source of
/// truth and avoids the stale-token bug caused by [UserProfileService]'s
/// SharedPreferences cache never being populated after login.
final dioClientProvider = Provider<DioClient>((ref) {
  final dio = buildDio(
    tokenProvider: () => ref.read(authTokenProviderOverride),
  );
  return DioClient(dio);
});
