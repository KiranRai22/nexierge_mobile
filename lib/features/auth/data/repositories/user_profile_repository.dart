import 'dart:io';

import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/user_profile_repository.dart';
import '../services/auth_me_service.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/services/user_profile_service.dart';
import '../../../profile/data/services/user_edit_service.dart';

class UserProfileRepositoryImpl implements UserProfileRepository {
  const UserProfileRepositoryImpl({
    required DioClient dioClient,
    required UserProfileService profileService,
  }) : _dioClient = dioClient,
       _profileService = profileService;

  final DioClient _dioClient;
  final UserProfileService _profileService;

  @override
  Future<UserProfile> fetchProfile() async {
    try {
      final service = AuthMeService(_dioClient.authenticatedDio);
      final dto = await service.fetchMe();
      return dto.toEntity();
    } catch (e) {
      print('[UserProfileRepository] Fetch profile error: $e');
      print('[UserProfileRepository] Error type: ${e.runtimeType}');
      rethrow;
    }
  }

  @override
  Future<UserProfile> updateProfilePicture(File imageFile) async {
    print('[UserProfileRepository] Starting updateProfilePicture');
    try {
      final editService = UserEditService(_dioClient.authenticatedDio);
      final dto = await editService.uploadProfilePicture(imageFile: imageFile);
      print(
        '[UserProfileRepository] Upload service returned: ${dto != null ? 'success' : 'null dto'}',
      );

      // Server may return a partial response; in that case, refetch the
      // canonical profile so all nested fields stay in sync.
      final UserProfile updated = dto != null
          ? dto.toEntity()
          : await fetchProfile();
      print(
        '[UserProfileRepository] Updated profile picture URL: ${updated.pictureProfile?.url}',
      );

      // Persist immediately so cold-start reflects the new avatar.
      await _profileService.saveProfile(updated);
      print('[UserProfileRepository] Profile saved successfully');
      return updated;
    } catch (e) {
      print('[UserProfileRepository] updateProfilePicture error: $e');
      print('[UserProfileRepository] Error type: ${e.runtimeType}');
      rethrow;
    }
  }

  @override
  Future<UserProfile?> getCachedProfile() async {
    return _profileService.getProfile();
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    await _profileService.saveProfile(profile);
  }

  @override
  Future<void> clearProfile() async {
    await _profileService.clearProfile();
  }

  @override
  Future<String?> getAuthToken() async {
    return _profileService.getAuthToken();
  }

  @override
  Future<bool> isTokenExpired() async {
    return _profileService.isTokenExpired();
  }

  @override
  Future<void> saveAuthToken(String token, {DateTime? expiry}) async {
    await _profileService.saveAuthToken(token, expiry: expiry);
  }

  @override
  Future<void> clearAuthToken() async {
    await _profileService.clearAuthToken();
  }
}
