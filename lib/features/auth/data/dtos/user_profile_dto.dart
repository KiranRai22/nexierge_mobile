import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/user_profile.dart';

part 'user_profile_dto.g.dart';

/// DTO for UserProfile - maps directly to domain entity since we removed freezed
@JsonSerializable()
class UserProfileDto {
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
  final PictureProfileDto? pictureProfile;
  @JsonKey(name: 'user_settings')
  final UserSettingsDto userSettings;
  @JsonKey(name: 'hotel_details')
  final HotelDetailsDto hotelDetails;
  @JsonKey(name: 'user_hotel_status')
  final UserHotelStatusDto userHotelStatus;
  @JsonKey(name: 'access_control')
  final AccessControlDto accessControl;

  UserProfileDto({
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

  factory UserProfileDto.fromJson(Map<String, dynamic> json) =>
      _$UserProfileDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UserProfileDtoToJson(this);

  /// Convert to domain entity
  UserProfile toEntity() => UserProfile(
    id: id,
    createdAt: createdAt,
    firstName: firstName,
    lastName: lastName,
    employeeCode: employeeCode,
    email: email,
    birthday: birthday,
    phoneNumber: phoneNumber,
    pictureProfile: pictureProfile?.toEntity(),
    userSettings: userSettings.toEntity(),
    hotelDetails: hotelDetails.toEntity(),
    userHotelStatus: userHotelStatus.toEntity(),
    accessControl: accessControl.toEntity(),
  );
}

@JsonSerializable()
class PictureProfileDto {
  final String url;

  PictureProfileDto({required this.url});

  factory PictureProfileDto.fromJson(Map<String, dynamic> json) =>
      _$PictureProfileDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PictureProfileDtoToJson(this);

  PictureProfile toEntity() => PictureProfile(url: url);
}

@JsonSerializable()
class UserSettingsDto {
  final String id;
  final String lang;
  final String theme;

  UserSettingsDto({required this.id, required this.lang, required this.theme});

  factory UserSettingsDto.fromJson(Map<String, dynamic> json) =>
      _$UserSettingsDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UserSettingsDtoToJson(this);

  UserSettings toEntity() => UserSettings(id: id, lang: lang, theme: theme);
}

@JsonSerializable()
class HotelDetailsDto {
  final HotelDto hotel;
  @JsonKey(name: 'subscription_details')
  final SubscriptionDetailsDto subscriptionDetails;

  HotelDetailsDto({required this.hotel, required this.subscriptionDetails});

  factory HotelDetailsDto.fromJson(Map<String, dynamic> json) =>
      _$HotelDetailsDtoFromJson(json);

  Map<String, dynamic> toJson() => _$HotelDetailsDtoToJson(this);

  HotelDetails toEntity() => HotelDetails(
    hotel: hotel.toEntity(),
    subscriptionDetails: subscriptionDetails.toEntity(),
  );
}

@JsonSerializable()
class HotelDto {
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

  HotelDto({
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

  factory HotelDto.fromJson(Map<String, dynamic> json) =>
      _$HotelDtoFromJson(json);

  Map<String, dynamic> toJson() => _$HotelDtoToJson(this);

  Hotel toEntity() => Hotel(
    id: id,
    businessEmail: businessEmail,
    name: name,
    country: country,
    timezone: timezone,
    language: language,
    status: status,
    createdByUserId: createdByUserId,
    createdAt: createdAt,
    city: city,
    street: street,
    websiteUrl: websiteUrl,
    businessPhoneNumber: businessPhoneNumber,
    onboardingInitiated: onboardingInitiated,
  );
}

@JsonSerializable()
class SubscriptionDetailsDto {
  @JsonKey(name: 'subscription_active')
  final bool subscriptionActive;
  final String plan;
  @JsonKey(name: 'subscription_start_date')
  final int subscriptionStartDate;
  @JsonKey(name: 'subscription_end_date')
  final int subscriptionEndDate;

  SubscriptionDetailsDto({
    required this.subscriptionActive,
    required this.plan,
    required this.subscriptionStartDate,
    required this.subscriptionEndDate,
  });

  factory SubscriptionDetailsDto.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionDetailsDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionDetailsDtoToJson(this);

  SubscriptionDetails toEntity() => SubscriptionDetails(
    subscriptionActive: subscriptionActive,
    plan: plan,
    subscriptionStartDate: subscriptionStartDate,
    subscriptionEndDate: subscriptionEndDate,
  );
}

@JsonSerializable()
class UserHotelStatusDto {
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

  UserHotelStatusDto({
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

  factory UserHotelStatusDto.fromJson(Map<String, dynamic> json) =>
      _$UserHotelStatusDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UserHotelStatusDtoToJson(this);

  UserHotelStatus toEntity() => UserHotelStatus(
    id: id,
    userId: userId,
    hotelId: hotelId,
    hierarchyRole: hierarchyRole,
    status: status,
    scheduleType: scheduleType,
    weeklyHours: weeklyHours,
    invitedByUserId: invitedByUserId,
    createdAt: createdAt,
    scheduleActive: scheduleActive,
    scheduleUpdatedAt: scheduleUpdatedAt,
    scheduleUpdatedBy: scheduleUpdatedBy,
    lastLoginAt: lastLoginAt,
    verifiedBusinessEmail: verifiedBusinessEmail,
    verifiedBusinessEmailStatus: verifiedBusinessEmailStatus,
    verifiedBusinessEmailAt: verifiedBusinessEmailAt,
    securityGroupEligible: securityGroupEligible,
    notesInternal: notesInternal,
    isPrimaryContact: isPrimaryContact,
  );
}

@JsonSerializable()
class AccessControlDto {
  @JsonKey(name: 'hotel_user_id')
  final String hotelUserId;
  @JsonKey(name: 'hotel_id')
  final String hotelId;
  @JsonKey(name: 'hierarchy_role')
  final String hierarchyRole;
  @JsonKey(name: 'user_status')
  final String userStatus;
  final LoginDto login;
  @JsonKey(name: 'hub_access')
  final List<HubAccessDto> hubAccess;
  final List<dynamic> departments;

  AccessControlDto({
    required this.hotelUserId,
    required this.hotelId,
    required this.hierarchyRole,
    required this.userStatus,
    required this.login,
    required this.hubAccess,
    required this.departments,
  });

  factory AccessControlDto.fromJson(Map<String, dynamic> json) =>
      _$AccessControlDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AccessControlDtoToJson(this);

  AccessControl toEntity() => AccessControl(
    hotelUserId: hotelUserId,
    hotelId: hotelId,
    hierarchyRole: hierarchyRole,
    userStatus: userStatus,
    login: login.toEntity(),
    hubAccess: hubAccess.map((e) => e.toEntity()).toList(),
    departments: departments,
  );
}

@JsonSerializable()
class LoginDto {
  @JsonKey(name: 'interface_access')
  final String interfaceAccess;
  @JsonKey(name: 'login_identifier_type')
  final String loginIdentifierType;
  @JsonKey(name: 'auth_method')
  final String authMethod;
  final String status;

  LoginDto({
    required this.interfaceAccess,
    required this.loginIdentifierType,
    required this.authMethod,
    required this.status,
  });

  factory LoginDto.fromJson(Map<String, dynamic> json) =>
      _$LoginDtoFromJson(json);

  Map<String, dynamic> toJson() => _$LoginDtoToJson(this);

  Login toEntity() => Login(
    interfaceAccess: interfaceAccess,
    loginIdentifierType: loginIdentifierType,
    authMethod: authMethod,
    status: status,
  );
}

@JsonSerializable()
class HubAccessDto {
  @JsonKey(name: 'hub_code')
  final String hubCode;
  final String? hubRole;

  HubAccessDto({required this.hubCode, this.hubRole});

  factory HubAccessDto.fromJson(Map<String, dynamic> json) =>
      _$HubAccessDtoFromJson(json);

  Map<String, dynamic> toJson() => _$HubAccessDtoToJson(this);

  HubAccess toEntity() => HubAccess(hubCode: hubCode, hubRole: hubRole);
}
