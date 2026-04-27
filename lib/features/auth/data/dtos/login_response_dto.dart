import '../../domain/entities/auth_session.dart';
import '../../domain/entities/auth_user.dart';

/// JSON shape returned by both login endpoints. `authToken` is the only
/// mandatory field per spec §6; everything else is opportunistic.
class LoginResponseDto {
  final String authToken;
  final String? refreshToken;
  final AuthUserDto? user;

  const LoginResponseDto({
    required this.authToken,
    this.refreshToken,
    this.user,
  });

  factory LoginResponseDto.fromJson(Map<String, dynamic> json) {
    final token = json['authToken'] ?? json['auth_token'] ?? json['token'];
    if (token is! String || token.isEmpty) {
      throw const FormatException('login response missing authToken');
    }

    // Accept either nested `user` object or opportunistic top-level fields
    Map<String, dynamic>? rawUser = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : null;

    if (rawUser == null) {
      // Some backends return user fields at top-level (e.g. Xano). Normalize.
      final hasTopLevelUser =
          json['hotel_user_id'] != null ||
          json['hotel_id'] != null ||
          json['hierarchy_role'] != null ||
          json['id'] != null;
      if (hasTopLevelUser) {
        rawUser = <String, dynamic>{
          'id': json['hotel_user_id'] ?? json['id'],
          'role': json['hierarchy_role'] ?? json['role'],
          'hotel_id': json['hotel_id'] ?? json['hotelId'],
        };
      }
    }

    return LoginResponseDto(
      authToken: token,
      refreshToken: json['refresh_token'] as String?,
      user: rawUser != null ? AuthUserDto.fromJson(rawUser) : null,
    );
  }

  AuthSession toDomain() => AuthSession(
    authToken: authToken,
    refreshToken: refreshToken,
    user: user?.toDomain(),
  );
}

class AuthUserDto {
  final String id;
  final String? role;
  final String? hotelId;

  const AuthUserDto({required this.id, this.role, this.hotelId});

  factory AuthUserDto.fromJson(Map<String, dynamic> json) {
    return AuthUserDto(
      id: (json['id'] ?? json['hotel_user_id'] ?? json['hotelUserId'] ?? '').toString(),
      role: (json['role'] ?? json['hierarchy_role']) as String?,
      hotelId: (json['hotel_id'] ?? json['hotelId']) as String?,
    );
  }

  AuthUser toDomain() => AuthUser(id: id, role: role, hotelId: hotelId);
}
