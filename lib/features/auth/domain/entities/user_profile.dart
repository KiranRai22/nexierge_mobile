import 'package:json_annotation/json_annotation.dart';

part 'user_profile.g.dart';

/// User profile entity from auth/me API
@JsonSerializable()
class UserProfile {
  final String id;
  @JsonKey(name: 'created_at')
  final int createdAt;
  @JsonKey(name: 'first_name')
  final String firstName;
  @JsonKey(name: 'last_name')
  final String lastName;
  @JsonKey(name: 'employee_code')
  final String employeeCode;
  final String email;
  final String? birthday;
  @JsonKey(name: 'phone_number')
  final String? phoneNumber;
  @JsonKey(name: 'picture_profile')
  final PictureProfile? pictureProfile;
  @JsonKey(name: 'user_settings')
  final UserSettings userSettings;
  @JsonKey(name: 'hotel_details')
  final HotelDetails hotelDetails;
  @JsonKey(name: 'user_hotel_status')
  final UserHotelStatus userHotelStatus;
  @JsonKey(name: 'access_control')
  final AccessControl accessControl;

  const UserProfile({
    required this.id,
    required this.createdAt,
    required this.firstName,
    required this.lastName,
    required this.employeeCode,
    required this.email,
    this.birthday,
    this.phoneNumber,
    this.pictureProfile,
    required this.userSettings,
    required this.hotelDetails,
    required this.userHotelStatus,
    required this.accessControl,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);

  Map<String, dynamic> toJson() => _$UserProfileToJson(this);

  UserProfile copyWith({
    String? id,
    int? createdAt,
    String? firstName,
    String? lastName,
    String? employeeCode,
    String? email,
    String? birthday,
    String? phoneNumber,
    PictureProfile? pictureProfile,
    UserSettings? userSettings,
    HotelDetails? hotelDetails,
    UserHotelStatus? userHotelStatus,
    AccessControl? accessControl,
  }) {
    return UserProfile(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      employeeCode: employeeCode ?? this.employeeCode,
      email: email ?? this.email,
      birthday: birthday ?? this.birthday,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      pictureProfile: pictureProfile ?? this.pictureProfile,
      userSettings: userSettings ?? this.userSettings,
      hotelDetails: hotelDetails ?? this.hotelDetails,
      userHotelStatus: userHotelStatus ?? this.userHotelStatus,
      accessControl: accessControl ?? this.accessControl,
    );
  }
}

@JsonSerializable()
class PictureProfile {
  final String url;

  const PictureProfile({required this.url});

  factory PictureProfile.fromJson(Map<String, dynamic> json) =>
      _$PictureProfileFromJson(json);

  Map<String, dynamic> toJson() => _$PictureProfileToJson(this);
}

@JsonSerializable()
class UserSettings {
  final String id;
  final String lang;
  final String theme;

  const UserSettings({
    required this.id,
    required this.lang,
    required this.theme,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) =>
      _$UserSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$UserSettingsToJson(this);
}

@JsonSerializable()
class HotelDetails {
  final Hotel hotel;
  @JsonKey(name: 'subscription_details')
  final SubscriptionDetails subscriptionDetails;

  const HotelDetails({required this.hotel, required this.subscriptionDetails});

  factory HotelDetails.fromJson(Map<String, dynamic> json) =>
      _$HotelDetailsFromJson(json);

  Map<String, dynamic> toJson() => _$HotelDetailsToJson(this);
}

@JsonSerializable()
class Hotel {
  final String id;
  @JsonKey(name: 'business_email')
  final String businessEmail;
  final String name;
  final String country;
  final String timezone;
  final String language;
  final String status;
  @JsonKey(name: 'created_by_user_id')
  final String createdByUserId;
  @JsonKey(name: 'created_at')
  final int createdAt;
  final String city;
  final String street;
  @JsonKey(name: 'website_url')
  final String? websiteUrl;
  @JsonKey(name: 'business_phone_number')
  final String? businessPhoneNumber;
  @JsonKey(name: 'onboarding_initiated')
  final bool onboardingInitiated;

  const Hotel({
    required this.id,
    required this.businessEmail,
    required this.name,
    required this.country,
    required this.timezone,
    required this.language,
    required this.status,
    required this.createdByUserId,
    required this.createdAt,
    required this.city,
    required this.street,
    this.websiteUrl,
    this.businessPhoneNumber,
    required this.onboardingInitiated,
  });

  factory Hotel.fromJson(Map<String, dynamic> json) => _$HotelFromJson(json);

  Map<String, dynamic> toJson() => _$HotelToJson(this);
}

@JsonSerializable()
class SubscriptionDetails {
  @JsonKey(name: 'subscription_active')
  final bool subscriptionActive;
  final String plan;
  @JsonKey(name: 'subscription_start_date')
  final int subscriptionStartDate;
  @JsonKey(name: 'subscription_end_date')
  final int subscriptionEndDate;

  const SubscriptionDetails({
    required this.subscriptionActive,
    required this.plan,
    required this.subscriptionStartDate,
    required this.subscriptionEndDate,
  });

  factory SubscriptionDetails.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionDetailsFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionDetailsToJson(this);
}

@JsonSerializable()
class UserHotelStatus {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'hotel_id')
  final String hotelId;
  @JsonKey(name: 'hierarchy_role')
  final String hierarchyRole;
  final String status;
  @JsonKey(name: 'schedule_type')
  final String scheduleType;
  @JsonKey(name: 'weekly_hours')
  final int weeklyHours;
  @JsonKey(name: 'invited_by_user_id')
  final String? invitedByUserId;
  @JsonKey(name: 'created_at')
  final int createdAt;
  @JsonKey(name: 'schedule_active')
  final bool scheduleActive;
  @JsonKey(name: 'schedule_updated_at')
  final int scheduleUpdatedAt;
  @JsonKey(name: 'schedule_updated_by')
  final String scheduleUpdatedBy;
  @JsonKey(name: 'last_login_at')
  final int? lastLoginAt;
  @JsonKey(name: 'verified_business_email')
  final String? verifiedBusinessEmail;
  @JsonKey(name: 'verified_business_email_status')
  final String? verifiedBusinessEmailStatus;
  @JsonKey(name: 'verified_business_email_at')
  final int? verifiedBusinessEmailAt;
  @JsonKey(name: 'security_group_eligible')
  final bool securityGroupEligible;
  @JsonKey(name: 'notes_internal')
  final String notesInternal;
  @JsonKey(name: 'is_primary_contact')
  final bool isPrimaryContact;

  const UserHotelStatus({
    required this.id,
    required this.userId,
    required this.hotelId,
    required this.hierarchyRole,
    required this.status,
    required this.scheduleType,
    required this.weeklyHours,
    this.invitedByUserId,
    required this.createdAt,
    required this.scheduleActive,
    required this.scheduleUpdatedAt,
    required this.scheduleUpdatedBy,
    this.lastLoginAt,
    this.verifiedBusinessEmail,
    this.verifiedBusinessEmailStatus,
    this.verifiedBusinessEmailAt,
    required this.securityGroupEligible,
    required this.notesInternal,
    required this.isPrimaryContact,
  });

  factory UserHotelStatus.fromJson(Map<String, dynamic> json) =>
      _$UserHotelStatusFromJson(json);

  Map<String, dynamic> toJson() => _$UserHotelStatusToJson(this);
}

@JsonSerializable()
class AccessControl {
  @JsonKey(name: 'hotel_user_id')
  final String hotelUserId;
  @JsonKey(name: 'hotel_id')
  final String hotelId;
  @JsonKey(name: 'hierarchy_role')
  final String hierarchyRole;
  @JsonKey(name: 'user_status')
  final String userStatus;
  final Login login;
  @JsonKey(name: 'hub_access')
  final List<HubAccess> hubAccess;
  final List<dynamic> departments;

  const AccessControl({
    required this.hotelUserId,
    required this.hotelId,
    required this.hierarchyRole,
    required this.userStatus,
    required this.login,
    required this.hubAccess,
    required this.departments,
  });

  factory AccessControl.fromJson(Map<String, dynamic> json) =>
      _$AccessControlFromJson(json);

  Map<String, dynamic> toJson() => _$AccessControlToJson(this);
}

@JsonSerializable()
class Login {
  @JsonKey(name: 'interface_access')
  final String interfaceAccess;
  @JsonKey(name: 'login_identifier_type')
  final String loginIdentifierType;
  @JsonKey(name: 'auth_method')
  final String authMethod;
  final String status;

  const Login({
    required this.interfaceAccess,
    required this.loginIdentifierType,
    required this.authMethod,
    required this.status,
  });

  factory Login.fromJson(Map<String, dynamic> json) => _$LoginFromJson(json);

  Map<String, dynamic> toJson() => _$LoginToJson(this);
}

@JsonSerializable()
class HubAccess {
  @JsonKey(name: 'hub_code')
  final String hubCode;
  final String? hubRole;

  const HubAccess({required this.hubCode, this.hubRole});

  factory HubAccess.fromJson(Map<String, dynamic> json) =>
      _$HubAccessFromJson(json);

  Map<String, dynamic> toJson() => _$HubAccessToJson(this);
}
