import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';

/// Enumerates the locales we ship explicitly. Every new language goes here
/// AND in `lib/l10n/app_<code>.arb` AND in `AppLocalizations.supportedLocales`
/// (the latter is generated automatically). Keep these three in lockstep.
///
/// `system` is a synthetic option meaning "follow the device locale". It is
/// not a Locale itself — when the user picks it the app stops overriding
/// MaterialApp.locale and lets Flutter resolve from device + supportedLocales.
enum AppLocale {
  system,
  english,
  spanish;

  /// The actual `Locale` to feed MaterialApp.locale, or `null` if the user
  /// chose `system` (let Flutter pick from the device).
  Locale? toLocale() {
    switch (this) {
      case AppLocale.system:
        return null;
      case AppLocale.english:
        return const Locale('en');
      case AppLocale.spanish:
        return const Locale('es');
    }
  }

  /// Persistence key written to / read from SharedPreferences.
  String get storageKey {
    switch (this) {
      case AppLocale.system:
        return 'system';
      case AppLocale.english:
        return 'en';
      case AppLocale.spanish:
        return 'es';
    }
  }

  /// Reverse of [storageKey]. Defaults to [AppLocale.system] for unknown
  /// values so an app upgrade that drops a locale won't trap the user.
  static AppLocale fromStorage(String? raw) {
    switch (raw) {
      case 'en':
        return AppLocale.english;
      case 'es':
        return AppLocale.spanish;
      case 'system':
      default:
        return AppLocale.system;
    }
  }

  /// Resolve the picker tile's *localized* label using the live
  /// [AppLocalizations]. Each language's name shows in the user's currently
  /// active language — the language ITSELF is rendered in its native form
  /// via [nativeName] for the right-hand affordance.
  String label(AppLocalizations s) {
    switch (this) {
      case AppLocale.system:
        return s.languageSystem;
      case AppLocale.english:
        return s.languageEnglish;
      case AppLocale.spanish:
        return s.languageSpanish;
    }
  }

  /// Native rendering of the language name (e.g. "Español"). Stays constant
  /// regardless of active locale so users can find their language when the
  /// app is in a language they don't read.
  String nativeName(AppLocalizations s) {
    switch (this) {
      case AppLocale.system:
        return s.languageSystem;
      case AppLocale.english:
        return s.languageNativeEnglish;
      case AppLocale.spanish:
        return s.languageNativeSpanish;
    }
  }
}
