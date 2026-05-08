import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/entities/user_profile.dart' as auth_entity;
import '../../../auth/presentation/providers/auth_session_controller.dart';
import '../../../auth/presentation/providers/user_profile_controller.dart'
    as auth_ctrl;
import '../../domain/entities/user_profile.dart';
import '../../../tickets/domain/entities/ticket_form_options.dart';
import '../../../tickets/presentation/providers/ticket_form_options_provider.dart';

// ---------------------------------------------------------------------------
// Mapping
// ---------------------------------------------------------------------------

/// Extract readable department names from the department list.
/// For AuthDepartment objects, we'll use the existing HotelDepartment API data
/// for consistency with the rest of the application.
List<String> _extractDepartments(List<dynamic> raw, Ref ref) {
  // Get department IDs from AuthDepartment objects
  final departmentIds = raw
      .map((d) {
        // Handle AuthDepartment objects
        if (d.runtimeType.toString().contains('AuthDepartment')) {
          return (d as dynamic).id as String? ?? '';
        }
        // Handle plain strings (might be department IDs)
        if (d is String) return d;
        // Handle Map objects
        if (d is Map) {
          return (d['id'] ?? d['department_id'] ?? '').toString();
        }
        return '';
      })
      .where((id) => id.trim().isNotEmpty)
      .toList();

  // If no department IDs, return empty list
  if (departmentIds.isEmpty) return [];

  try {
    // Get the existing HotelDepartment data from the tickets API
    final hotelDepartments = ref.read(apiDepartmentsProvider);

    // Match department IDs with names from the existing HotelDepartment data
    final departmentNames = departmentIds
        .map((deptId) {
          final hotelDept = hotelDepartments.firstWhere(
            (hd) => hd.id == deptId,
            orElse: () => HotelDepartment.fromName(id: deptId, name: deptId),
          );
          return hotelDept.name;
        })
        .where((name) => name.trim().isNotEmpty)
        .toList();

    return departmentNames;
  } catch (e) {
    // Fallback: return the department IDs if we can't fetch the HotelDepartment data
    return departmentIds;
  }
}

/// Maps the full auth-domain [auth_entity.UserProfile] (returned by the
/// `me_user` API) to the leaner [UserProfile] used exclusively by the
/// profile screen widgets.
UserProfile _mapToProfileEntity(auth_entity.UserProfile p, Ref ref) {
  return UserProfile(
    id: p.id,
    fullName: p.fullName,
    email: p.email,
    employeeCode: p.employeeCode.trim().isEmpty ? null : p.employeeCode,
    role: p.userHotelStatus.hierarchyRole,
    departments: _extractDepartments(p.accessControl.departments, ref),
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

    final authNotifier = ref.read(
      auth_ctrl.userProfileControllerProvider.notifier,
    );

    // Load from SharedPreferences cache first (no network on warm start).
    await authNotifier.loadCachedProfile();

    final authState = ref.read(auth_ctrl.userProfileControllerProvider);
    if (authState.profile != null) {
      return _mapToProfileEntity(authState.profile!, ref);
    }

    // Cache miss — fall back to live API fetch.
    await authNotifier.loadProfile();
    final freshState = ref.read(auth_ctrl.userProfileControllerProvider);
    if (freshState.profile != null) {
      return _mapToProfileEntity(freshState.profile!, ref);
    }

    if (freshState.error != null) {
      throw Exception(freshState.error);
    }
    throw Exception('Profile unavailable');
  }

  /// Upload a new avatar image. Returns true on success.
  Future<bool> updateAvatar(File imageFile) async {
    final authNotifier = ref.read(
      auth_ctrl.userProfileControllerProvider.notifier,
    );
    final success = await authNotifier.updateProfilePicture(imageFile);
    if (success) {
      final authState = ref.read(auth_ctrl.userProfileControllerProvider);
      if (authState.profile != null) {
        state = AsyncData(_mapToProfileEntity(authState.profile!, ref));
      }
    }
    return success;
  }

  /// Update the user's first and last name. Returns true on success.
  Future<bool> updateName(String firstName, String lastName) async {
    final authNotifier = ref.read(
      auth_ctrl.userProfileControllerProvider.notifier,
    );
    final success = await authNotifier.updateName(
      firstName: firstName,
      lastName: lastName,
    );
    if (success) {
      final authState = ref.read(auth_ctrl.userProfileControllerProvider);
      if (authState.profile != null) {
        state = AsyncData(_mapToProfileEntity(authState.profile!, ref));
      }
    }
    return success;
  }

  /// Pull-to-refresh: re-fetches from the API, persists, and emits new data
  /// without a full loading flash (keeps previous data visible during fetch).
  Future<void> refreshProfile() async {
    state = const AsyncLoading<UserProfile>().copyWithPrevious(state);
    try {
      final authNotifier = ref.read(
        auth_ctrl.userProfileControllerProvider.notifier,
      );
      await authNotifier.refreshProfile();
      final authState = ref.read(auth_ctrl.userProfileControllerProvider);
      if (authState.profile != null) {
        state = AsyncData(_mapToProfileEntity(authState.profile!, ref));
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
