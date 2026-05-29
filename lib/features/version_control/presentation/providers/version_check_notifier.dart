import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/app_info_service.dart';
import '../../../auth/presentation/providers/auth_session_controller.dart';
import '../../data/repositories/version_control_repository_impl.dart';
import '../../domain/entities/app_version.dart';

/// Result of comparing the installed version against the server's latest.
sealed class VersionCheckResult {
  const VersionCheckResult();
}

/// App is up to date — no action required.
class VersionUpToDate extends VersionCheckResult {
  const VersionUpToDate();
}

/// A newer version is available but the user can choose to update later.
class VersionUpdateOptional extends VersionCheckResult {
  final AppVersion version;
  const VersionUpdateOptional(this.version);
}

/// A newer version is required — the user cannot proceed without updating.
class VersionUpdateForced extends VersionCheckResult {
  final AppVersion version;
  const VersionUpdateForced(this.version);
}

/// Checks the backend version-control API once per session and exposes the
/// result as [AsyncValue<VersionCheckResult>]. The notifier is persistent
/// (no autoDispose) because it gates app usage for force updates.
class VersionCheckNotifier
    extends AsyncNotifier<VersionCheckResult> {
  /// Guards against showing the update dialog more than once per check cycle.
  /// Reset to false on every [recheck] call; set to true once the listener
  /// in main.dart actually shows the dialog.
  bool _dialogShown = false;

  bool get dialogShown => _dialogShown;
  void markDialogShown() => _dialogShown = true;

  @override
  Future<VersionCheckResult> build() async {
    return _check();
  }

  Future<VersionCheckResult> _check() async {
    try {
      // Wait for authentication to be available
      final authSession = ref.read(authSessionControllerProvider);
      final authSessionValue = authSession.valueOrNull;
      final authUser = authSessionValue?.user;

      if (authUser == null && authSessionValue?.authToken.isNotEmpty != true) {
        return const VersionUpToDate();
      }

      final repo = ref.read(versionControlRepositoryProvider);
      final appInfo = ref.read(appInfoServiceProvider);
      final latest = await repo.fetchLatestVersion();
      
      // Pick the version string for the running platform.
      final serverVersion =
          Platform.isIOS ? latest.iosVersion : latest.androidVersion;

      if (serverVersion.isEmpty) {
        return const VersionUpToDate();
      }

      final isOutdated = appInfo.isOutdated(serverVersion);
      if (!isOutdated) {
        return const VersionUpToDate();
      }

      return latest.updateType == UpdateType.force
          ? VersionUpdateForced(latest)
          : VersionUpdateOptional(latest);
    } catch (_) {
      // On any error (network, server, etc.) treat as up-to-date so the
      // operator is never blocked by a transient failure.
      return const VersionUpToDate();
    }
  }

  Future<void> recheck() async {
    // Reset the dialog guard so the next result can trigger the dialog once.
    _dialogShown = false;
    // Use a bare AsyncLoading (no copyWithPrevious) so that valueOrNull
    // returns null during the check — prevents stale values from firing the
    // listener prematurely.
    state = const AsyncLoading<VersionCheckResult>();
    state = AsyncData(await _check());
  }

  /// Trigger version check after authentication completes
  Future<void> checkAfterAuth() async {
    await recheck();
  }

  /// Store URL for the running platform, falling back to an empty string.
  String storeUrl(AppVersion version) =>
      Platform.isIOS ? version.iosLink : version.androidLink;
}

final versionCheckProvider =
    AsyncNotifierProvider<VersionCheckNotifier, VersionCheckResult>(
      VersionCheckNotifier.new,
    );
