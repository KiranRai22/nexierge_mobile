import '../../domain/entities/app_version.dart';

class AppVersionDto {
  final String id;
  final String iosVersion;
  final String iosBuild;
  final String androidVersion;
  final String androidBuild;
  final String type;
  final String title;
  final String description;
  final String iosLink;
  final String androidLink;

  const AppVersionDto({
    required this.id,
    required this.iosVersion,
    required this.iosBuild,
    required this.androidVersion,
    required this.androidBuild,
    required this.type,
    required this.title,
    required this.description,
    required this.iosLink,
    required this.androidLink,
  });

  factory AppVersionDto.fromJson(Map<String, dynamic> json) {
    return AppVersionDto(
      id: (json['id'] as String?) ?? '',
      iosVersion: (json['ios_version'] as String?) ?? '',
      iosBuild: (json['ios_build'] as String?) ?? '',
      androidVersion: (json['android_version'] as String?) ?? '',
      androidBuild: (json['android_build'] as String?) ?? '',
      type: (json['type'] as String?) ?? 'optional',
      title: (json['title'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      iosLink: (json['ios_link'] as String?) ?? '',
      androidLink: (json['android_link'] as String?) ?? '',
    );
  }

  AppVersion toEntity() {
    return AppVersion(
      id: id,
      iosVersion: iosVersion,
      iosBuild: iosBuild,
      androidVersion: androidVersion,
      androidBuild: androidBuild,
      updateType: type == 'force' ? UpdateType.force : UpdateType.optional,
      title: title,
      description: description,
      iosLink: iosLink,
      androidLink: androidLink,
    );
  }
}
