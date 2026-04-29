import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/entities/user_profile.dart' as auth_entity;
import '../../../auth/presentation/providers/auth_session_controller.dart';
import '../../../auth/presentation/providers/user_profile_controller.dart'
    as auth_ctrl;
import '../../domain/entities/user_profile.dart';

// ---------------------------------------------------------------------------
// Mapping
// ---------------------------------------------------------------------------

/// Extract readable department names from the raw `List<dynamic>` that the
/// API returns. Items may be plain `String`s or `Map<String,dynamic>` objects
/// whose `name` / `department_name` key carries the label.
List<String> _extractDepartments(List<dynamic> raw) => raw
    .map((d) {
      if (d is String) return d;
      if (d is Map) {
        return (d['name'] ?? d['department_name'] ?? d.values.firstOrNull ?? '')
            .toString();
      }
      return d.toString();
    })
    .where((s) => s.trim().isNotEmpty)
    .toList();

/// Maps the full auth-domain [auth_entity.UserProfile] (returned by the
/// `me_user` API) to the leaner [UserProfile] used exclusively by the
/// profile screen widgets.
UserProfile _mapToProfileEntity(auth_entity.UserProfile p) {
  return UserProfile(
    id: p.id,
    fullName: '${p.firstName} ${p.lastName}'.trim(),
    email: p.email,
    employeeCode: p.employeeCode.trim().isEmpty ? null : p.employeeCode,
    role: p.userHotelStatus.hierarchyRole,
    departments: _extractDepartments(p.accessControl.departments),
    status: p.userHotelStatus.status.toLowerCase() == 'active'
        ? UserStatus.active
        : UserStatus.inactive,
    avatarUrl: p.pictureProfile?.url,
    lang: p.userSettings.lang,
    theme: p.userSettings.theme,
    phone: p.phoneNumber,
    hotelName: p.hotelDetails.hotel.name,
  );
}

// ---------------------------------------------------------------------------
// Controller
// ---------------------------------------------------------------------------

/// Profile-screen controller. Delegates all fetching, caching, and
/// persistence to the auth-layer [auth_ctrl.userProfileControllerProvider]
/// which owns the `me_user` API call and the SharedPreferences store — this
/// controller is purely a mapping / projection layer on top.
///
/// Lifecycle:
/// - On `build()`: loads from cache (instant on warm starts) then falls back
///   to a network fetch if the cache is empty.
/// - Watches [authSessionControllerProvider] so that when the user logs out
///   (session → null) this notifier is automatically invalidated and any
///   stale data is discarded.
/// - `refreshProfile()`: re-fetches from the API, updates the
///   SharedPreferences cache, and emits the new data without a loading flash.
class UserProfileController extends AutoDisposeAsyncNotifier<UserProfile> {
  @override
  Future<UserProfile> build() async {
    // Re-run when auth session changes (null = logged out → invalidates this).
    ref.watch(authSessionControllerProvider);

    final authNotifier =
        ref.read(auth_ctrl.userProfileControllerProvider.notifier);

    // Load from SharedPreferences cache first (no network on warm start).
    await authNotifier.loadCachedProfile();

    final authState = ref.read(auth_ctrl.userProfileControllerProvider);
    if (authState.profile != null) {
      return _mapToProfileEntity(authState.profile!);
    }

    // Cache miss — fall back to live API fetch.
    await authNotifier.loadProfile();
    final freshState = ref.read(auth_ctrl.userProfileControllerProvider);
    if (freshState.profile != null) {
      return _mapToProfileEntity(freshState.profile!);
    }

    if (freshState.error != null) {
      throw Exception(freshState.error);
    }
    throw Exception('Profile unavailable');
  }

  /// Upload a new avatar image. Returns true on success.
  Future<bool> updateAvatar(File imageFile) async {
    final authNotifier =
        ref.read(auth_ctrl.userProfileControllerProvider.notifier);
    final success = await authNotifier.updateProfilePicture(imageFile);
    if (success) {
      final authState = ref.read(auth_ctrl.userProfileControllerProvider);
      if (authState.profile != null) {
        state = AsyncData(_mapToProfileEntity(authState.profile!));
      }
    }
    return success;
  }

  /// Update the user's first and last name. Returns true on success.
  Future<bool> updateName(String firstName, String lastName) async {
    final authNotifier =
        ref.read(auth_ctrl.userProfileControllerProvider.notifier);
    final success = await authNotifier.updateName(
      firstName: firstName,
      lastName: lastName,
    );
    if (success) {
      final authState = ref.read(auth_ctrl.userProfileControllerProvider);
      if (authState.profile != null) {
        state = AsyncData(_mapToProfileEntity(authState.profile!));
      }
    }
    return success;
  }

  /// Pull-to-refresh: re-fetches from the API, persists, and emits new data
  /// without a full loading flash (keeps previous data visible during fetch).
  Future<void> refreshProfile() async {
    state = const AsyncLoading<UserProfile>().copyWithPrevious(state);
    try {
      final authNotifier =
          ref.read(auth_ctrl.userProfileControllerProvider.notifier);
      await authNotifier.refreshProfile();
      final authState = ref.read(auth_ctrl.userProfileControllerProvider);
      if (authState.profile != null) {
        state = AsyncData(_mapToProfileEntity(authState.profile!));
        return;
      }
      if (authState.error != null) throw Exception(authState.error);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final userProfileControllerProvider =
    AsyncNotifierProvider.autoDispose<UserProfileController, UserProfile>(
      UserProfileController.new,
    );
