import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/vibration_manager.dart';

final vibrationPreferencesProvider =
    StateNotifierProvider<VibrationPreferencesNotifier, bool>(
      (ref) => VibrationPreferencesNotifier(),
    );

class VibrationPreferencesNotifier extends StateNotifier<bool> {
  static const _key = 'app.vibration';

  VibrationPreferencesNotifier() : super(true) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_key) ?? true;
    state = enabled;
    VibrationManager.instance.setEnabled(enabled);
  }

  Future<void> toggle() async {
    final next = !state;
    state = next;
    VibrationManager.instance.setEnabled(next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, next);
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    VibrationManager.instance.setEnabled(enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, enabled);
  }
}
