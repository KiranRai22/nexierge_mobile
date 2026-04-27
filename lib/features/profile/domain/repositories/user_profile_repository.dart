import '../entities/user_profile.dart';

/// Source of the signed-in user's profile data. Concrete implementations
/// either decode an `AuthSession` payload + cached fields (production) or
/// return a fixture (mock during phase 7).
abstract class UserProfileRepository {
  Future<UserProfile> getProfile();
}
