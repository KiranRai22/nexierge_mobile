import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_session_controller.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/user_profile_repository.dart';

/// Phase-7 mock: returns a fixture that mirrors the design screenshot,
/// optionally enriched with the live `authToken`'s user id when available.
/// Swap the provider override in main.dart once the backend `/me` endpoint
/// is wired — the rest of the app reads through `userProfileControllerProvider`
/// so no UI change is needed at that point.
class MockUserProfileRepository implements UserProfileRepository {
  final String? _authUserId;
  const MockUserProfileRepository({String? authUserId}) : _authUserId = authUserId;

  @override
  Future<UserProfile> getProfile() async {
    return UserProfile(
      id: _authUserId ?? 'u-001',
      fullName: 'Fola Adeyemi',
      email: 'xcvxc@employee.local',
      employeeCode: null,
      role: 'Manager',
      departments: const ['Housekeeping', 'Frontdesk', 'Maintenance'],
      status: UserStatus.active,
      lang: 'en',
      theme: 'light',
    );
  }
}

/// Provider for the repository. Reads the live auth session so the mock
/// can pretend to be the logged-in user (id only — name/email stay fixed
/// until real `/me` lands).
final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  final session = ref.watch(authSessionControllerProvider).valueOrNull;
  return MockUserProfileRepository(authUserId: session?.user?.id);
});
