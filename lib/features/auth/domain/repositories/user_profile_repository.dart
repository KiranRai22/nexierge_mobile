import 'dart:io';

import '../entities/user_profile.dart';

abstract class UserProfileRepository {
  /// Fetch current user profile from API
  Future<UserProfile> fetchProfile();

  /// Upload a new profile picture for the current user. Returns the
  /// freshly fetched [UserProfile] so callers can update local state
  /// and cache atomically.
  Future<UserProfile> updateProfilePicture(File imageFile);

  /// Get cached profile from local storage
  Future<UserProfile?> getCachedProfile();

  /// Save profile to local storage
  Future<void> saveProfile(UserProfile profile);

  /// Clear cached profile
  Future<void> clearProfile();

  /// Get saved auth token
  Future<String?> getAuthToken();

  /// Check if token is expired
  Future<bool> isTokenExpired();

  /// Save auth token with optional expiry
  Future<void> saveAuthToken(String token, {DateTime? expiry});

  /// Clear auth token
  Future<void> clearAuthToken();
}
