import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_toast.dart';

/// Severity for the toast banner shown above the login button.
enum LoginAlertSeverity { error, info, success }

/// Themed toast for the login screen. Uses generic [AppToast] under the hood.
/// Used for transient errors (validation, network, generic auth failure).
/// State-based account errors use [LoginStateDialog] instead — they need
/// acknowledgement, not an auto-dismissing chip.
abstract class LoginAlert {
  static void show(
    BuildContext context, {
    required LoginAlertSeverity severity,
    required String message,
  }) {
    final type = _mapSeverity(severity);
    AppToast.show(
      context,
      title: message,
      type: type,
      position: ToastPosition.top,
      duration: const Duration(seconds: 4),
    );
  }
}

ToastType _mapSeverity(LoginAlertSeverity severity) {
  switch (severity) {
    case LoginAlertSeverity.error:
      return ToastType.failure;
    case LoginAlertSeverity.info:
      return ToastType.info;
    case LoginAlertSeverity.success:
      return ToastType.success;
  }
}
