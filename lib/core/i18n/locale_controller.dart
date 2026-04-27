import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/notification_service.dart';
import 'app_locale.dart';
import 'locale_aware_strings.dart';

/// Persistent app-wide locale.
///
/// Stored in SharedPreferences under [_kKey] so the choice survives a cold
/// start and a logout. Defaults to [AppLocale.system] (follow device locale)
/// until the user explicitly picks a language.
///
/// Persistence is the only async work here, hence `AsyncNotifier<AppLocale>`
/// per `docs/02_RIVERPOD_GUIDELINES.md` ("AsyncNotifier is DEFAULT for any
/// I/O-backed state").
class LocaleController extends AsyncNotifier<AppLocale> {
  static const _kKey = 'app.locale';

  @override
  Future<AppLocale> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kKey);
    final loaded = AppLocale.fromStorage(raw);
    // Push the loaded locale to the no-context accessor so services /
    // notification handlers can format messages even before the first frame.
    LocaleAwareStrings.instance.set(loaded);
    // Subscribe FCM to the locale-scoped topic. Fire-and-forget — token
    // refresh is a network call we don't want blocking app boot.
    unawaited(NotificationService.instance.syncLocaleTopic(loaded));
    return loaded;
  }

  /// Replaces the current locale and persists it. Safe to call from any
  /// widget; the optimistic update keeps the picker UI snappy.
  Future<void> set(AppLocale locale) async {
    final current = state.valueOrNull;
    if (current == locale) return;

    state = AsyncData(locale);
    LocaleAwareStrings.instance.set(locale);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kKey, locale.storageKey);

    // Re-target FCM topic so subsequent push notifications arrive in the
    // newly selected language. Best-effort — failure here is non-fatal.
    unawaited(NotificationService.instance.syncLocaleTopic(locale));
  }
}

final localeControllerProvider =
    AsyncNotifierProvider<LocaleController, AppLocale>(LocaleController.new);
