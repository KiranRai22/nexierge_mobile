import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'department.g.dart';

/// Department entity from auth/me_user API response
@JsonSerializable()
class AuthDepartment {
  // The auth/me API returns department objects with key 'id'.
  // Fallback keys 'hotel_department_id' and 'department_id' are tried
  // via the custom fromJson below.
  @JsonKey(defaultValue: '')
  final String id;
  @JsonKey(defaultValue: '')
  final String name;
  @JsonKey(name: 'is_primary', defaultValue: false)
  final bool isPrimary;
  final String? code;
  @JsonKey(name: 'created_at')
  final int? createdAt;
  @JsonKey(name: 'updated_at')
  final int? updatedAt;
  final bool? active;

  const AuthDepartment({
    required this.id,
    required this.name,
    this.isPrimary = false,
    this.code,
    this.createdAt,
    this.updatedAt,
    this.active,
  });

  /// Custom fromJson that handles multiple possible API key names.
  factory AuthDepartment.fromJson(Map<String, dynamic> json) {
    //debugPrint('[AuthDepartment.fromJson] raw keys=${json.keys.toList()} '
        // 'id=${json['id']} name=${json['name']} '
        // 'hotel_department_id=${json['hotel_department_id']} '
        // 'department_name=${json['department_name']}');
    final id = (json['id'] as String?)
        ?? (json['hotel_department_id'] as String?)
        ?? (json['department_id'] as String?)
        ?? '';
    final name = (json['name'] as String?)
        ?? (json['department_name'] as String?)
        ?? '';
    final isPrimary = (json['is_primary'] as bool?) ?? false;
    //debugPrint('[AuthDepartment.fromJson] resolved → id=$id name=$name isPrimary=$isPrimary');
    return AuthDepartment(
      id: id,
      name: name,
      isPrimary: isPrimary,
      code: json['code'] as String?,
      createdAt: (json['created_at'] as num?)?.toInt(),
      updatedAt: (json['updated_at'] as num?)?.toInt(),
      active: json['active'] as bool?,
    );
  }

  Map<String, dynamic> toJson() => _$AuthDepartmentToJson(this);

  AuthDepartment copyWith({
    String? id,
    String? name,
    bool? isPrimary,
    String? code,
    int? createdAt,
    int? updatedAt,
    bool? active,
  }) {
    return AuthDepartment(
      id: id ?? this.id,
      name: name ?? this.name,
      isPrimary: isPrimary ?? this.isPrimary,
      code: code ?? this.code,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      active: active ?? this.active,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthDepartment && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'AuthDepartment(id: $id, name: $name)';
}
