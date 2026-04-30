import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for sound preferences state
/// Manages the sound enabled/disabled toggle with persistent storage
final soundPreferencesProvider =
    StateNotifierProvider<SoundPreferencesNotifier, bool>(
      (ref) => SoundPreferencesNotifier(),
    );

class SoundPreferencesNotifier extends StateNotifier<bool> {
  static const String _soundEnabledKey = 'sound_enabled';

  SoundPreferencesNotifier() : super(true) {
    _loadSoundPreference();
  }

  /// Load sound preference from persistent storage
  Future<void> _loadSoundPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isEnabled = prefs.getBool(_soundEnabledKey) ?? true;
      state = isEnabled;
      debugPrint('SoundPreferences: Loaded preference: $isEnabled');
    } catch (e) {
      // Default to enabled if loading fails
      state = true;
      debugPrint(
        'SoundPreferences: Error loading preference, defaulting to enabled: $e',
      );
    }
  }

  /// Toggle sound preference and persist to storage
  Future<void> toggle() async {
    final newValue = !state;
    state = newValue;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_soundEnabledKey, newValue);
    } catch (e) {
      // Revert if saving fails
      state = !newValue;
    }
  }

  /// Set sound preference directly
  Future<void> setEnabled(bool enabled) async {
    state = enabled;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_soundEnabledKey, enabled);
    } catch (e) {
      // Revert if saving fails
      state = !enabled;
    }
  }
}
