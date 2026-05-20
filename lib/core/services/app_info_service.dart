import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Wraps [PackageInfo] so the app version is fetched once at startup and
/// available synchronously throughout the widget tree via Riverpod.
///
/// In DEBUG builds the suffix " - DEV" is appended to [versionLabel].
class AppInfoService {
  final PackageInfo _info;

  AppInfoService._(this._info);

  static Future<AppInfoService> create() async {
    final info = await PackageInfo.fromPlatform();
    return AppInfoService._(info);
  }

  String get version => _info.version;
  String get buildNumber => _info.buildNumber;

  /// Formatted for display in the profile footer and login screen.
  ///
  /// - Release: `Version 1.0.0 (23)`
  /// - Debug:   `Version 1.0.0 (23) - DEV`
  String get versionLabel {
    final base = '$version ($buildNumber)';
    return kDebugMode ? '$base - DEV' : base;
  }

  /// Parses [version] into comparable segments `[major, minor, patch]`.
  List<int> get versionParts {
    final parts = version.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    while (parts.length < 3) {
      parts.add(0);
    }
    return parts;
  }

  /// Returns `true` when [serverVersion] is strictly newer than the installed
  /// version. Compares major → minor → patch; build number is ignored.
  bool isOutdated(String serverVersion) {
    final server =
        serverVersion.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    while (server.length < 3) {
      server.add(0);
    }
    for (var i = 0; i < 3; i++) {
      if (server[i] > versionParts[i]) return true;
      if (server[i] < versionParts[i]) return false;
    }
    return false;
  }
}

/// Seeded from [main] before [runApp] so the info is available synchronously.
final appInfoServiceProvider = Provider<AppInfoService>((ref) {
  throw UnimplementedError(
    'appInfoServiceProvider must be overridden in ProviderScope',
  );
});
