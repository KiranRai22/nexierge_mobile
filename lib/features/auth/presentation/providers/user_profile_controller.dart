import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/user_profile_repository.dart';
import '../../domain/entities/user_profile.dart';
import '../../data/repositories/user_profile_repository.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/services/user_profile_service.dart';

/// UI state for user profile operations
class UserProfileState {
  final bool isLoading;
  final bool isRefreshing;
  final bool isUpdatingPicture;
  final UserProfile? profile;
  final String? error;

  const UserProfileState({
    this.isLoading = false,
    this.isRefreshing = false,
    this.isUpdatingPicture = false,
    this.profile,
    this.error,
  });

  UserProfileState copyWith({
    bool? isLoading,
    bool? isRefreshing,
    bool? isUpdatingPicture,
    UserProfile? profile,
    String? error,
  }) {
    return UserProfileState(
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isUpdatingPicture: isUpdatingPicture ?? this.isUpdatingPicture,
      profile: profile ?? this.profile,
      error: error ?? this.error,
    );
  }
}

/// Controller for user profile operations
class UserProfileController extends StateNotifier<UserProfileState> {
  UserProfileController(this._repository) : super(const UserProfileState());

  final UserProfileRepository _repository;

  /// Load user profile (first load with shimmer)
  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final profile = await _repository.fetchProfile();
      await _repository.saveProfile(profile);
      state = state.copyWith(profile: profile, isLoading: false);
    } catch (e) {
      print('[UserProfileController] Load profile error: $e');
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  /// Refresh profile (no shimmer, just loading indicator)
  Future<void> refreshProfile() async {
    state = state.copyWith(isRefreshing: true, error: null);
    try {
      final profile = await _repository.fetchProfile();
      await _repository.saveProfile(profile);
      state = state.copyWith(profile: profile, isRefreshing: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isRefreshing: false);
    }
  }

  /// Load cached profile on app start. Falls back to network fetch when
  /// cache is missing or corrupted, so the UI never lands on an empty
  /// state silently.
  Future<void> loadCachedProfile() async {
    try {
      final profile = await _repository.getCachedProfile();
      if (profile != null) {
        state = state.copyWith(profile: profile);
        return;
      }
    } catch (_) {
      // Cache corrupted — fall through to network fetch.
    }
    await loadProfile();
  }

  /// Upload a new profile picture and refresh state with the updated
  /// profile returned by the server. Surfaces failures via [state.error]
  /// so the UI can show a snackbar without throwing.
  Future<bool> updateProfilePicture(File imageFile) async {
    print('[UserProfileController] Starting updateProfilePicture');
    state = state.copyWith(isUpdatingPicture: true, error: null);
    try {
      final updated = await _repository.updateProfilePicture(imageFile);
      print('[UserProfileController] Update successful');
      state = state.copyWith(profile: updated, isUpdatingPicture: false);
      return true;
    } catch (e) {
      print('[UserProfileController] Update failed: $e');
      print('[UserProfileController] Error type: ${e.runtimeType}');
      final errorString = e.toString();
      state = state.copyWith(isUpdatingPicture: false, error: errorString);
      return false;
    }
  }

  /// Update first and last name. Returns true on success.
  Future<bool> updateName({
    required String firstName,
    required String lastName,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updated = await _repository.updateName(
        firstName: firstName,
        lastName: lastName,
      );
      state = state.copyWith(profile: updated, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  /// Clear profile and token (logout)
  Future<void> clearProfile() async {
    await _repository.clearProfile();
    await _repository.clearAuthToken();
    state = const UserProfileState();
  }

  /// Check if token is expired
  Future<bool> isTokenExpired() async {
    return _repository.isTokenExpired();
  }

  /// Get auth token
  Future<String?> getAuthToken() async {
    return _repository.getAuthToken();
  }

  /// Save auth token
  Future<void> saveAuthToken(String token) async {
    await _repository.saveAuthToken(token);
  }
}

// Providers
final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  final profileService = UserProfileService.instance;
  return UserProfileRepositoryImpl(
    dioClient: dioClient,
    profileService: profileService,
  );
});

final userProfileControllerProvider =
    StateNotifierProvider<UserProfileController, UserProfileState>((ref) {
      final repository = ref.watch(userProfileRepositoryProvider);
      return UserProfileController(repository);
    });

final userProfileProvider = Provider<UserProfile?>((ref) {
  return ref.watch(userProfileControllerProvider).profile;
});

final isProfileLoadingProvider = Provider<bool>((ref) {
  final state = ref.watch(userProfileControllerProvider);
  return state.isLoading || state.isRefreshing;
});
