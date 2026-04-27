import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted app-wide theme mode. Defaults to [ThemeMode.system] until the
/// user explicitly toggles. Stored in SharedPreferences so it survives a
/// cold start without depending on auth.
class ThemeModeController extends AsyncNotifier<ThemeMode> {
  static const _kKey = 'app.themeMode';

  @override
  Future<ThemeMode> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kKey);
    return _decode(raw);
  }

  Future<void> toggle() async {
    final current = state.valueOrNull ?? ThemeMode.system;
    final next = current == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await _persist(next);
    state = AsyncData(next);
  }

  Future<void> set(ThemeMode mode) async {
    await _persist(mode);
    state = AsyncData(mode);
  }

  Future<void> _persist(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kKey, _encode(mode));
  }

  static ThemeMode _decode(String? raw) {
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static String _encode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}

final themeModeControllerProvider =
    AsyncNotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);
