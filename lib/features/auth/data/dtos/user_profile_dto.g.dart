// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserProfileDto _$UserProfileDtoFromJson(Map<String, dynamic> json) =>
    UserProfileDto(
      id: json['id'] as String,
      createdAt: (json['created_at'] as num).toInt(),
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      employeeCode: json['employee_code'] as String,
      email: json['email'] as String,
      birthday: json['birthday'] as String?,
      phoneNumber: json['phone_number'] as String?,
      pictureProfile: json['picture_profile'] == null
          ? null
          : PictureProfileDto.fromJson(
              json['picture_profile'] as Map<String, dynamic>,
            ),
      userSettings: UserSettingsDto.fromJson(
        json['user_settings'] as Map<String, dynamic>,
      ),
      hotelDetails: HotelDetailsDto.fromJson(
        json['hotel_details'] as Map<String, dynamic>,
      ),
      userHotelStatus: UserHotelStatusDto.fromJson(
        json['user_hotel_status'] as Map<String, dynamic>,
      ),
      accessControl: AccessControlDto.fromJson(
        json['access_control'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$UserProfileDtoToJson(UserProfileDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'created_at': instance.createdAt,
      'first_name': instance.firstName,
      'last_name': instance.lastName,
      'employee_code': instance.employeeCode,
      'email': instance.email,
      'birthday': instance.birthday,
      'phone_number': instance.phoneNumber,
      'picture_profile': instance.pictureProfile,
      'user_settings': instance.userSettings,
      'hotel_details': instance.hotelDetails,
      'user_hotel_status': instance.userHotelStatus,
      'access_control': instance.accessControl,
    };

PictureProfileDto _$PictureProfileDtoFromJson(Map<String, dynamic> json) =>
    PictureProfileDto(url: json['url'] as String);

Map<String, dynamic> _$PictureProfileDtoToJson(PictureProfileDto instance) =>
    <String, dynamic>{'url': instance.url};

UserSettingsDto _$UserSettingsDtoFromJson(Map<String, dynamic> json) =>
    UserSettingsDto(
      id: json['id'] as String,
      lang: json['lang'] as String,
      theme: json['theme'] as String,
    );

Map<String, dynamic> _$UserSettingsDtoToJson(UserSettingsDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'lang': instance.lang,
      'theme': instance.theme,
    };

HotelDetailsDto _$HotelDetailsDtoFromJson(Map<String, dynamic> json) =>
    HotelDetailsDto(
      hotel: HotelDto.fromJson(json['hotel'] as Map<String, dynamic>),
      subscriptionDetails: SubscriptionDetailsDto.fromJson(
        json['subscription_details'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$HotelDetailsDtoToJson(HotelDetailsDto instance) =>
    <String, dynamic>{
      'hotel': instance.hotel,
      'subscription_details': instance.subscriptionDetails,
    };

HotelDto _$HotelDtoFromJson(Map<String, dynamic> json) => HotelDto(
  id: json['id'] as String,
  businessEmail: json['business_email'] as String,
  name: json['name'] as String,
  country: json['country'] as String,
  timezone: json['timezone'] as String,
  language: json['language'] as String,
  status: json['status'] as String,
  createdByUserId: json['created_by_user_id'] as String,
  createdAt: (json['created_at'] as num).toInt(),
  city: json['city'] as String,
  street: json['street'] as String,
  websiteUrl: json['website_url'] as String?,
  businessPhoneNumber: json['business_phone_number'] as String?,
  onboardingInitiated: json['onboarding_initiated'] as bool,
);

Map<String, dynamic> _$HotelDtoToJson(HotelDto instance) => <String, dynamic>{
  'id': instance.id,
  'business_email': instance.businessEmail,
  'name': instance.name,
  'country': instance.country,
  'timezone': instance.timezone,
  'language': instance.language,
  'status': instance.status,
  'created_by_user_id': instance.createdByUserId,
  'created_at': instance.createdAt,
  'city': instance.city,
  'street': instance.street,
  'website_url': instance.websiteUrl,
  'business_phone_number': instance.businessPhoneNumber,
  'onboarding_initiated': instance.onboardingInitiated,
};

SubscriptionDetailsDto _$SubscriptionDetailsDtoFromJson(
  Map<String, dynamic> json,
) => SubscriptionDetailsDto(
  subscriptionActive: json['subscription_active'] as bool,
  plan: json['plan'] as String,
  subscriptionStartDate: (json['subscription_start_date'] as num).toInt(),
  subscriptionEndDate: (json['subscription_end_date'] as num).toInt(),
);

Map<String, dynamic> _$SubscriptionDetailsDtoToJson(
  SubscriptionDetailsDto instance,
) => <String, dynamic>{
  'subscription_active': instance.subscriptionActive,
  'plan': instance.plan,
  'subscription_start_date': instance.subscriptionStartDate,
  'subscription_end_date': instance.subscriptionEndDate,
};

UserHotelStatusDto _$UserHotelStatusDtoFromJson(Map<String, dynamic> json) =>
    UserHotelStatusDto(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      hotelId: json['hotel_id'] as String,
      hierarchyRole: json['hierarchy_role'] as String,
      status: json['status'] as String,
      scheduleType: json['schedule_type'] as String,
      weeklyHours: (json['weekly_hours'] as num).toInt(),
      invitedByUserId: json['invited_by_user_id'] as String?,
      createdAt: (json['created_at'] as num).toInt(),
      scheduleActive: json['schedule_active'] as bool,
      scheduleUpdatedAt: (json['schedule_updated_at'] as num).toInt(),
      scheduleUpdatedBy: json['schedule_updated_by'] as String,
      lastLoginAt: (json['last_login_at'] as num?)?.toInt(),
      verifiedBusinessEmail: json['verified_business_email'] as String?,
      verifiedBusinessEmailStatus:
          json['verified_business_email_status'] as String?,
      verifiedBusinessEmailAt: (json['verified_business_email_at'] as num?)
          ?.toInt(),
      securityGroupEligible: json['security_group_eligible'] as bool,
      notesInternal: json['notes_internal'] as String,
      isPrimaryContact: json['is_primary_contact'] as bool,
    );

Map<String, dynamic> _$UserHotelStatusDtoToJson(UserHotelStatusDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'hotel_id': instance.hotelId,
      'hierarchy_role': instance.hierarchyRole,
      'status': instance.status,
      'schedule_type': instance.scheduleType,
      'weekly_hours': instance.weeklyHours,
      'invited_by_user_id': instance.invitedByUserId,
      'created_at': instance.createdAt,
      'schedule_active': instance.scheduleActive,
      'schedule_updated_at': instance.scheduleUpdatedAt,
      'schedule_updated_by': instance.scheduleUpdatedBy,
      'last_login_at': instance.lastLoginAt,
      'verified_business_email': instance.verifiedBusinessEmail,
      'verified_business_email_status': instance.verifiedBusinessEmailStatus,
      'verified_business_email_at': instance.verifiedBusinessEmailAt,
      'security_group_eligible': instance.securityGroupEligible,
      'notes_internal': instance.notesInternal,
      'is_primary_contact': instance.isPrimaryContact,
    };

AccessControlDto _$AccessControlDtoFromJson(Map<String, dynamic> json) =>
    AccessControlDto(
      hotelUserId: json['hotel_user_id'] as String,
      hotelId: json['hotel_id'] as String,
      hierarchyRole: json['hierarchy_role'] as String,
      userStatus: json['user_status'] as String,
      login: LoginDto.fromJson(json['login'] as Map<String, dynamic>),
      hubAccess: (json['hub_access'] as List<dynamic>)
          .map((e) => HubAccessDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      departments: json['departments'] as List<dynamic>,
    );

Map<String, dynamic> _$AccessControlDtoToJson(AccessControlDto instance) =>
    <String, dynamic>{
      'hotel_user_id': instance.hotelUserId,
      'hotel_id': instance.hotelId,
      'hierarchy_role': instance.hierarchyRole,
      'user_status': instance.userStatus,
      'login': instance.login,
      'hub_access': instance.hubAccess,
      'departments': instance.departments,
    };

LoginDto _$LoginDtoFromJson(Map<String, dynamic> json) => LoginDto(
  interfaceAccess: json['interface_access'] as String,
  loginIdentifierType: json['login_identifier_type'] as String,
  authMethod: json['auth_method'] as String,
  status: json['status'] as String,
);

Map<String, dynamic> _$LoginDtoToJson(LoginDto instance) => <String, dynamic>{
  'interface_access': instance.interfaceAccess,
  'login_identifier_type': instance.loginIdentifierType,
  'auth_method': instance.authMethod,
  'status': instance.status,
};

HubAccessDto _$HubAccessDtoFromJson(Map<String, dynamic> json) => HubAccessDto(
  hubCode: json['hub_code'] as String,
  hubRole: json['hubRole'] as String?,
);

Map<String, dynamic> _$HubAccessDtoToJson(HubAccessDto instance) =>
    <String, dynamic>{
      'hub_code': instance.hubCode,
      'hubRole': instance.hubRole,
    };
