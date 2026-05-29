// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'department.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

// fromJson is implemented directly in AuthDepartment (custom multi-key logic).
// This stub is kept so the part directive compiles; it is never called.
AuthDepartment _$AuthDepartmentFromJson(Map<String, dynamic> json) =>
    AuthDepartment.fromJson(json);

Map<String, dynamic> _$AuthDepartmentToJson(AuthDepartment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'is_primary': instance.isPrimary,
      'code': instance.code,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
      'active': instance.active,
    };
