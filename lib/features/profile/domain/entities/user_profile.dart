/// Domain entity for the profile screen. Aggregates everything the UI
/// renders so the widget tree stays declarative and free of conditionals
/// against the auth/session shape.
class UserProfile {
  final String id;
  final String fullName;
  final String email;
  final String? employeeCode;
  final String role;
  final List<String> departments;
  final UserStatus status;

  /// URL of the user's profile picture returned by the API.
  /// `null` when no picture has been uploaded — avatar falls back to [initials].
  final String? avatarUrl;

  /// BCP-47 language code stored in user_settings (e.g. `"en"`, `"es"`).
  /// Used to seed the locale controller on first login when the user has no
  /// explicit local preference set.
  final String lang;

  /// Theme preference stored in user_settings (e.g. `"light"`, `"dark"`).
  final String theme;

  /// Optional phone number.
  final String? phone;

  /// Name of the property (hotel) the user belongs to.
  final String? hotelName;

  /// Hotel business email from hotel_details.hotel.business_email
  final String? hotelBusinessEmail;

  /// Hotel business phone from hotel_details.hotel.business_phone_number
  final String? hotelBusinessPhone;

  /// Hotel website from hotel_details.hotel.website_url
  final String? hotelWebsite;

  /// Hotel address (combined city, street, country)
  final String? hotelAddress;

  /// Hotel timezone from hotel_details.hotel.timezone
  final String? hotelTimezone;

  /// Subscription plan from subscription_details.plan
  final String? subscriptionPlan;

  /// Subscription active status from subscription_details.subscription_active
  final bool? subscriptionActive;

  /// Subscription start date from subscription_details.subscription_start_date
  final int? subscriptionStartDate;

  /// Subscription end date from subscription_details.subscription_end_date
  final int? subscriptionEndDate;

  /// Authentication method from access_control.login.auth_method
  final String? authMethod;

  /// Interface access from access_control.login.interface_access
  final String? interfaceAccess;

  /// Hub access codes from access_control.hub_access
  final List<String> hubAccess;

  /// Last login timestamp from user_hotel_status.last_login_at
  final int? lastLoginAt;

  const UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.departments,
    required this.status,
    required this.lang,
    required this.theme,
    this.employeeCode,
    this.avatarUrl,
    this.phone,
    this.hotelName,
    this.hotelBusinessEmail,
    this.hotelBusinessPhone,
    this.hotelWebsite,
    this.hotelAddress,
    this.hotelTimezone,
    this.subscriptionPlan,
    this.subscriptionActive,
    this.subscriptionStartDate,
    this.subscriptionEndDate,
    this.authMethod,
    this.interfaceAccess,
    this.hubAccess = const [],
    this.lastLoginAt,
  });

  /// Two-letter initials for the avatar — uses first + last name when
  /// possible, falls back to a single letter for one-word names, and a
  /// `?` when the name is empty (defensive: a profile should always have
  /// a name, but the UI must never render empty).
  String get initials {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

/// Lifecycle state of an account. Kept as an enum so the UI can switch on
/// it for colour without parsing strings.
enum UserStatus { active, inactive }
