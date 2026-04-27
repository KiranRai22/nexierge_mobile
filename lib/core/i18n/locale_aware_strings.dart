import 'dart:ui';

import '../../l10n/generated/app_localizations.dart';
import 'app_locale.dart';

/// Singleton accessor that exposes [AppLocalizations] outside of a
/// `BuildContext`. Used by:
///   - `NotificationService` (foreground-display payloads)
///   - background isolate FCM handlers
///   - repositories / interceptors that surface user-facing error messages
///   - any other call-site without access to a widget tree
///
/// The active locale is pushed in by [LocaleController] on build & on every
/// user change. Until the controller resolves, falls back to the device
/// locale (or `en` if the device locale isn't supported), so push messages
/// arriving before the first frame still localize correctly.
class LocaleAwareStrings {
  LocaleAwareStrings._();

  static final LocaleAwareStrings instance = LocaleAwareStrings._();

  AppLocalizations? _cached;
  AppLocale _active = AppLocale.system;

  /// Switch the active locale. Invalidates the cached delegate so the next
  /// [strings] read rebuilds against the new language.
  void set(AppLocale locale) {
    if (_active == locale && _cached != null) return;
    _active = locale;
    _cached = null;
  }

  /// Force-resolve and cache the localizations for the active locale.
  /// Returns the synchronous lookup result (`lookupAppLocalizations` ships
  /// with `gen-l10n`'s output and is itself synchronous).
  AppLocalizations get strings {
    final cached = _cached;
    if (cached != null) return cached;

    final resolved = _resolveLocale(_active);
    final s = lookupAppLocalizations(resolved);
    _cached = s;
    return s;
  }

  /// Returns the [Locale] the singleton is currently using. `null` would mean
  /// "system" — we resolve that into a real locale on the way out so callers
  /// always get a concrete value.
  Locale get activeLocale => _resolveLocale(_active);

  Locale _resolveLocale(AppLocale choice) {
    final explicit = choice.toLocale();
    if (explicit != null) return explicit;

    // `system` → use device locale if supported; otherwise fall back to
    // English. We don't have access to MaterialApp.supportedLocales here;
    // instead we hard-code the two we ship and keep this list in lockstep
    // with `lib/l10n/*.arb`.
    final device = PlatformDispatcher.instance.locale;
    if (device.languageCode == 'es') return const Locale('es');
    return const Locale('en');
  }
}
