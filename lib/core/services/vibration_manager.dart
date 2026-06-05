import 'package:flutter/services.dart';

/// Singleton that gates `HapticFeedback` behind a runtime toggle.
/// Wire `setEnabled` from [vibrationPreferencesProvider] on app start;
/// call `trigger()` from `tapSound` to fire a light impact on every tap.
class VibrationManager {
  VibrationManager._();
  static final instance = VibrationManager._();

  bool _enabled = true;

  void setEnabled(bool value) => _enabled = value;

  void trigger() {
    if (_enabled) HapticFeedback.lightImpact();
  }

  /// Slightly heavier tap used for destructive / important actions.
  void triggerMedium() {
    if (_enabled) HapticFeedback.mediumImpact();
  }
}
