// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'department.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthDepartment _$AuthDepartmentFromJson(Map<String, dynamic> json) =>
    AuthDepartment(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      code: json['code'] as String?,
      createdAt: (json['created_at'] as num?)?.toInt(),
      updatedAt: (json['updated_at'] as num?)?.toInt(),
      active: json['active'] as bool?,
    );

Map<String, dynamic> _$AuthDepartmentToJson(AuthDepartment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'code': instance.code,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
      'active': instance.active,
    };
