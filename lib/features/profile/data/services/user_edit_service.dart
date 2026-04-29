import 'dart:io';

import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../auth/data/dtos/user_profile_dto.dart';

/// POST `/v1/user/profile` — multipart endpoint that updates user profile
/// fields (image, first_name, last_name). Auth handled by the shared
/// authenticated [Dio] (bearer token attached at request time).
class UserEditService {
  const UserEditService(this._dio);

  final Dio _dio;

  /// Upload a new profile picture. [imageFile] is sent under the
  /// `image` multipart field. Optional [firstName] / [lastName] are
  /// included only when supplied so existing values are preserved.
  ///
  /// Returns the parsed [UserProfileDto] from the response when the
  /// server returns the full profile. If the server returns a partial
  /// payload, callers should refetch via `/auth/me_user`.
  Future<UserProfileDto?> uploadProfilePicture({
    required File imageFile,
    String? firstName,
    String? lastName,
  }) async {
    final filename = imageFile.uri.pathSegments.isNotEmpty
        ? imageFile.uri.pathSegments.last
        : 'avatar.jpg';

    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(imageFile.path, filename: filename),
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
    });

    try {
      final response = await _dio.post(
        APIEndpoints.updateProfile,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      final status = response.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        final data = response.data;
        String? message;
        if (data is Map) {
          message = (data['message'] ?? data['error'] ?? data['detail'])
              ?.toString();
        } else if (data is String) {
          message = data;
        }
        throw Exception(
          'Profile update failed: $status ${message ?? 'Unknown error'}',
        );
      }

      final data = response.data;
      if (data is Map<String, dynamic> && data.containsKey('id')) {
        try {
          return UserProfileDto.fromJson(data);
        } catch (_) {
          // Server returned a partial shape — let the caller refetch.
          return null;
        }
      }
      return null;
    } catch (_) {
      rethrow;
    }
  }

  /// Update first_name / last_name without touching the profile image.
  Future<UserProfileDto?> updateName({
    required String firstName,
    required String lastName,
  }) async {
    final formData = FormData.fromMap({
      'first_name': firstName,
      'last_name': lastName,
    });
    try {
      final response = await _dio.post(
        APIEndpoints.updateProfile,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      final status = response.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        throw Exception('Name update failed ($status)');
      }
      final data = response.data;
      if (data is Map<String, dynamic> && data.containsKey('id')) {
        try {
          return UserProfileDto.fromJson(data);
        } catch (_) {
          return null;
        }
      }
      return null;
    } catch (_) {
      rethrow;
    }
  }
}
