import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

import 'image_picker_service.dart';

/// Outcome of a permission check before launching the image picker.
enum MediaPermissionResult {
  /// Permission granted (or limited on iOS, which still allows picking).
  granted,

  /// User denied this time, but can be asked again.
  denied,

  /// User permanently denied / restricted by parental controls — only
  /// recoverable via system settings.
  permanentlyDenied,
}

/// Requests runtime permissions for the avatar picker on demand. The
/// picker must call [ensure] right before launching the gallery / camera
/// — never at app start — so the OS prompt appears in direct response to
/// the user's tap.
class MediaPermissionService {
  const MediaPermissionService();

  /// Requests the appropriate permission for [source]. On Android the
  /// system Photo Picker (used by `image_picker` on API 33+) does not
  /// require a runtime permission for gallery access, so the gallery
  /// path short-circuits to [MediaPermissionResult.granted].
  Future<MediaPermissionResult> ensure(ImageSource$ source) async {
    final permission = _permissionFor(source);
    if (permission == null) return MediaPermissionResult.granted;

    final status = await permission.request();
    return _map(status);
  }

  Permission? _permissionFor(ImageSource$ source) {
    switch (source) {
      case ImageSource$.camera:
        return Permission.camera;
      case ImageSource$.gallery:
        // iOS: NSPhotoLibraryUsageDescription gates UIImagePickerController.
        // Android: photo picker on API 33+ runs without runtime perm.
        return Platform.isIOS ? Permission.photos : null;
    }
  }

  MediaPermissionResult _map(PermissionStatus status) {
    if (status.isGranted || status.isLimited) {
      return MediaPermissionResult.granted;
    }
    if (status.isPermanentlyDenied || status.isRestricted) {
      return MediaPermissionResult.permanentlyDenied;
    }
    return MediaPermissionResult.denied;
  }

  Future<bool> openSettings() => openAppSettings();
}
