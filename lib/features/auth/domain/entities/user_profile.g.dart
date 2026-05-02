// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserProfile _$UserProfileFromJson(Map<String, dynamic> json) => UserProfile(
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
      : PictureProfile.fromJson(
          json['picture_profile'] as Map<String, dynamic>,
        ),
  userSettings: UserSettings.fromJson(
    json['user_settings'] as Map<String, dynamic>,
  ),
  hotelDetails: HotelDetails.fromJson(
    json['hotel_details'] as Map<String, dynamic>,
  ),
  userHotelStatus: UserHotelStatus.fromJson(
    json['user_hotel_status'] as Map<String, dynamic>,
  ),
  accessControl: AccessControl.fromJson(
    json['access_control'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$UserProfileToJson(UserProfile instance) =>
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

PictureProfile _$PictureProfileFromJson(Map<String, dynamic> json) =>
    PictureProfile(url: json['url'] as String);

Map<String, dynamic> _$PictureProfileToJson(PictureProfile instance) =>
    <String, dynamic>{'url': instance.url};

UserSettings _$UserSettingsFromJson(Map<String, dynamic> json) => UserSettings(
  id: json['id'] as String,
  lang: json['lang'] as String,
  theme: json['theme'] as String,
);

Map<String, dynamic> _$UserSettingsToJson(UserSettings instance) =>
    <String, dynamic>{
      'id': instance.id,
      'lang': instance.lang,
      'theme': instance.theme,
    };

HotelDetails _$HotelDetailsFromJson(Map<String, dynamic> json) => HotelDetails(
  hotel: Hotel.fromJson(json['hotel'] as Map<String, dynamic>),
  subscriptionDetails: SubscriptionDetails.fromJson(
    json['subscription_details'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$HotelDetailsToJson(HotelDetails instance) =>
    <String, dynamic>{
      'hotel': instance.hotel,
      'subscription_details': instance.subscriptionDetails,
    };

Hotel _$HotelFromJson(Map<String, dynamic> json) => Hotel(
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

Map<String, dynamic> _$HotelToJson(Hotel instance) => <String, dynamic>{
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

SubscriptionDetails _$SubscriptionDetailsFromJson(Map<String, dynamic> json) =>
    SubscriptionDetails(
      subscriptionActive: json['subscription_active'] as bool,
      plan: json['plan'] as String,
      subscriptionStartDate: (json['subscription_start_date'] as num).toInt(),
      subscriptionEndDate: (json['subscription_end_date'] as num).toInt(),
    );

Map<String, dynamic> _$SubscriptionDetailsToJson(
  SubscriptionDetails instance,
) => <String, dynamic>{
  'subscription_active': instance.subscriptionActive,
  'plan': instance.plan,
  'subscription_start_date': instance.subscriptionStartDate,
  'subscription_end_date': instance.subscriptionEndDate,
};

UserHotelStatus _$UserHotelStatusFromJson(Map<String, dynamic> json) =>
    UserHotelStatus(
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

Map<String, dynamic> _$UserHotelStatusToJson(UserHotelStatus instance) =>
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

AccessControl _$AccessControlFromJson(Map<String, dynamic> json) =>
    AccessControl(
      hotelUserId: json['hotel_user_id'] as String,
      hotelId: json['hotel_id'] as String,
      hierarchyRole: json['hierarchy_role'] as String,
      userStatus: json['user_status'] as String,
      login: Login.fromJson(json['login'] as Map<String, dynamic>),
      hubAccess: (json['hub_access'] as List<dynamic>)
          .map((e) => HubAccess.fromJson(e as Map<String, dynamic>))
          .toList(),
      departments: json['departments'] as List<dynamic>,
    );

Map<String, dynamic> _$AccessControlToJson(AccessControl instance) =>
    <String, dynamic>{
      'hotel_user_id': instance.hotelUserId,
      'hotel_id': instance.hotelId,
      'hierarchy_role': instance.hierarchyRole,
      'user_status': instance.userStatus,
      'login': instance.login,
      'hub_access': instance.hubAccess,
      'departments': instance.departments,
    };

Login _$LoginFromJson(Map<String, dynamic> json) => Login(
  interfaceAccess: json['interface_access'] as String,
  loginIdentifierType: json['login_identifier_type'] as String,
  authMethod: json['auth_method'] as String,
  status: json['status'] as String,
);

Map<String, dynamic> _$LoginToJson(Login instance) => <String, dynamic>{
  'interface_access': instance.interfaceAccess,
  'login_identifier_type': instance.loginIdentifierType,
  'auth_method': instance.authMethod,
  'status': instance.status,
};

HubAccess _$HubAccessFromJson(Map<String, dynamic> json) => HubAccess(
  hubCode: json['hub_code'] as String,
  hubRole: json['hubRole'] as String?,
);

Map<String, dynamic> _$HubAccessToJson(HubAccess instance) => <String, dynamic>{
  'hub_code': instance.hubCode,
  'hubRole': instance.hubRole,
};
