import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/mock_user_profile_repository.dart';
import '../../domain/entities/user_profile.dart';

/// Profile data for the currently signed-in user. AsyncNotifier per
/// `docs/02_RIVERPOD_GUIDELINES.md` — the load is async, the screen
/// renders loading/error/data states off `AsyncValue`.
class UserProfileController extends AutoDisposeAsyncNotifier<UserProfile> {
  @override
  Future<UserProfile> build() async {
    final repo = ref.watch(userProfileRepositoryProvider);
    return repo.getProfile();
  }
}

final userProfileControllerProvider =
    AsyncNotifierProvider.autoDispose<UserProfileController, UserProfile>(
      UserProfileController.new,
    );
