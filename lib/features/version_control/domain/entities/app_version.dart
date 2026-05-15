/// Domain entity for the version-control API response.
///
/// [updateType] is either `'optional'` or `'force'`. Any unrecognised value
/// is treated as optional so the app degrades gracefully.
class AppVersion {
  final String id;
  final String iosVersion;
  final String iosBuild;
  final String androidVersion;
  final String androidBuild;
  final UpdateType updateType;
  final String title;
  final String description;
  final String iosLink;
  final String androidLink;

  const AppVersion({
    required this.id,
    required this.iosVersion,
    required this.iosBuild,
    required this.androidVersion,
    required this.androidBuild,
    required this.updateType,
    required this.title,
    required this.description,
    required this.iosLink,
    required this.androidLink,
  });
}

enum UpdateType { optional, force }
