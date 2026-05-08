import 'package:json_annotation/json_annotation.dart';

part 'department.g.dart';

/// Department entity from auth/me_user API response
@JsonSerializable()
class AuthDepartment {
  @JsonKey(defaultValue: '')
  final String id;
  @JsonKey(defaultValue: '')
  final String name;
  final String? code;
  @JsonKey(name: 'created_at')
  final int? createdAt;
  @JsonKey(name: 'updated_at')
  final int? updatedAt;
  final bool? active;

  const AuthDepartment({
    required this.id,
    required this.name,
    this.code,
    this.createdAt,
    this.updatedAt,
    this.active,
  });

  factory AuthDepartment.fromJson(Map<String, dynamic> json) =>
      _$AuthDepartmentFromJson(json);

  Map<String, dynamic> toJson() => _$AuthDepartmentToJson(this);

  AuthDepartment copyWith({
    String? id,
    String? name,
    String? code,
    int? createdAt,
    int? updatedAt,
    bool? active,
  }) {
    return AuthDepartment(
      id: id ?? this.id,
      name: name ?? this.name,
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
