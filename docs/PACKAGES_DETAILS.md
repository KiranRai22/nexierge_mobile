# Packages Details

> **Maintenance rule:** Every package added to `pubspec.yaml` MUST be documented here in the same commit. Every package and every font we use must be:
> 1. Free for commercial use (no GPL / no "personal use only").
> 2. Compatible with all currently supported Android & iOS versions targeted by this app.
> 3. Actively maintained (recent releases / responsive issue tracker).
> 4. Backed by a clear license (MIT / BSD / Apache-2.0 / SIL OFL preferred).
>
> Format for each entry:
> - **Package name**
> - **Version**
> - **Owner**
> - **License**
> - **Description** (what it does + license stance)
> - **Why we use it**

Last updated: 2026-04-26.

---

## Runtime dependencies

### `flutter`
- **Package name:** `flutter`
- **Version:** SDK (pinned by `environment.sdk: ^3.9.2`)
- **Owner:** Google / Flutter team
- **License:** BSD-3-Clause
- **Description:** The Flutter framework SDK. BSD-3-Clause permits commercial and closed-source use; only requires retention of the copyright notice.
- **Why we use it:** Cross-platform UI toolkit; the foundation of the app.

### `cupertino_icons`
- **Package name:** `cupertino_icons`
- **Version:** `^1.0.8`
- **Owner:** Flutter team (Google)
- **License:** MIT
- **Description:** iOS-style icon set used by Cupertino widgets. MIT license — unrestricted commercial use.
- **Why we use it:** Provides Cupertino glyphs needed for iOS-styled fallbacks and platform-consistent UI.

### `flutter_riverpod`
- **Package name:** `flutter_riverpod`
- **Version:** `^2.6.1`
- **Owner:** Remi Rousselet (`rrousselGit` on GitHub)
- **License:** MIT
- **Description:** Reactive caching / state-management framework. MIT licensed, large community, actively maintained.
- **Why we use it:** Mandated by `docs/02_RIVERPOD_GUIDELINES.md`. Provides AutoDispose, family providers, and StreamProvider — all used heavily in the tickets/activity features.

### `riverpod_annotation`
- **Package name:** `riverpod_annotation`
- **Version:** `^2.6.1`
- **Owner:** Remi Rousselet (`rrousselGit`)
- **License:** MIT
- **Description:** Annotations consumed by `riverpod_generator` to produce typed providers. MIT licensed.
- **Why we use it:** Annotation surface for `@riverpod` providers when we adopt code-gen for new providers.

### `firebase_core`
- **Package name:** `firebase_core`
- **Version:** `^3.6.0`
- **Owner:** FlutterFire team (Invertase / Google)
- **License:** BSD-3-Clause
- **Description:** Bootstraps Firebase services. BSD-3-Clause — commercial-friendly.
- **Why we use it:** Required by every Firebase plugin (Messaging, Auth, etc.).

### `firebase_messaging`
- **Package name:** `firebase_messaging`
- **Version:** `^15.1.3`
- **Owner:** FlutterFire team (Invertase / Google)
- **License:** BSD-3-Clause
- **Description:** Firebase Cloud Messaging client SDK. BSD-3-Clause — commercial-friendly.
- **Why we use it:** Push notifications for ticket lifecycle events (created, accepted, overdue).

### `flutter_local_notifications`
- **Package name:** `flutter_local_notifications`
- **Version:** `^17.2.2`
- **Owner:** Michael Bui (`MaikuB`)
- **License:** BSD-3-Clause
- **Description:** Cross-platform local-notification plugin (Android + iOS + macOS). BSD-3-Clause — commercial-friendly. Long-standing, widely used, actively maintained.
- **Why we use it:** Displays foreground notifications when an FCM message arrives while the app is open, and powers in-app reminders for ticket ETAs.

### `google_fonts`
- **Package name:** `google_fonts`
- **Version:** `^6.2.1`
- **Owner:** Material Design team (Google)
- **License:** Apache-2.0 (the package). The fonts themselves (e.g. Inter) are **SIL Open Font License 1.1** — explicitly free for commercial use, including embedding and redistribution.
- **Description:** Loads any Google Fonts family at runtime or bundled. Apache-2.0 + SIL OFL — both commercial-friendly.
- **Why we use it:** Provides the Inter type family used throughout `TypographyManager` without shipping the font binaries in the repo.

### `socket_io_client`
- **Package name:** `socket_io_client`
- **Version:** `^2.0.3+1`
- **Owner:** Rashed Tutul (`rikulo` org), maintained by the Rikulo team
- **License:** MIT
- **Description:** Dart port of the Socket.IO client. MIT licensed.
- **Why we use it:** Real-time channel for ticket updates from the backend (planned Phase 7 of the conversion plan).

### `go_router`
- **Package name:** `go_router`
- **Version:** `^14.2.7`
- **Owner:** Flutter team (Google)
- **License:** BSD-3-Clause
- **Description:** Declarative routing built on top of Navigator 2.0. BSD-3-Clause — commercial-friendly.
- **Why we use it:** Future deep-link / web routing support and to centralize route declarations.

### `flutter_localizations`
- **Package name:** `flutter_localizations`
- **Version:** SDK (Flutter)
- **Owner:** Flutter team (Google)
- **License:** BSD-3-Clause
- **Description:** First-party localizations for Material/Cupertino/Widgets layers (date pickers, dialog buttons, scrollbar tooltips, etc.). Ships with the Flutter SDK; pulled in by listing `flutter_localizations: sdk: flutter`.
- **Why we use it:** Required by `flutter gen-l10n`. Wires the platform localizations alongside our generated `AppLocalizations` so every locale gets correctly translated system widgets, not just our own strings.

### `intl`
- **Package name:** `intl`
- **Version:** `^0.20.2`
- **Owner:** Dart team (Google)
- **License:** BSD-3-Clause
- **Description:** Internationalization & localization primitives — `DateFormat`, `NumberFormat`, plurals, locale-aware messages. BSD-3-Clause.
- **Why we use it:** Powers `core/utils/date_utils.dart` ("Just now", "Apr 12") and underpins the ICU placeholder / plural support in our ARB files. Version is pinned by `flutter_localizations` (Flutter SDK); bump in lockstep with `flutter upgrade`.

### `shimmer`
- **Package name:** `shimmer`
- **Version:** `^3.0.0`
- **Owner:** `hnvn`
- **License:** BSD-2-Clause
- **Description:** Shimmer-style skeleton loader. BSD-2-Clause — commercial-friendly.
- **Why we use it:** Skeleton placeholders for ticket cards / activity rows while data loads.

### `shared_preferences`
- **Package name:** `shared_preferences`
- **Version:** `^2.3.2`
- **Owner:** Flutter team (Google)
- **License:** BSD-3-Clause
- **Description:** Lightweight key/value persistence wrapping `NSUserDefaults` (iOS) and `SharedPreferences` (Android). BSD-3-Clause.
- **Why we use it:** Persists `ThemeMode` (already wired) and will persist the user's selected `Locale` once i18n lands.

### `dio`
- **Package name:** `dio`
- **Version:** `^5.7.0`
- **Owner:** Cfug team (`cfug` on GitHub) — successor to the original `flutterchina/dio`.
- **License:** MIT
- **Description:** Powerful HTTP client for Dart with interceptor pipeline, FormData, request cancellation, timeouts and retry hooks. MIT licensed. Active maintenance with frequent releases.
- **Why we use it:** Single configured `Dio` instance is the chassis for every backend call — auth login, profile, tickets-when-live. Interceptor pipeline lets us attach the bearer token, log requests in debug, and translate failures into `AppException` in one place (per `api-and-realtime-rules`).

### `flutter_secure_storage`
- **Package name:** `flutter_secure_storage`
- **Version:** `^9.2.2`
- **Owner:** German Saprykin (`mogol` on GitHub)
- **License:** BSD-3-Clause
- **Description:** Cross-platform secure key-value storage. Uses Keychain on iOS / macOS, EncryptedSharedPreferences (AES + Android Keystore) on Android, libsecret/Credential Locker on Linux/Windows, IndexedDB+Web Crypto on Web. BSD-3-Clause. Active maintenance.
- **Why we use it:** The login spec mandates secure token storage (§9.2). Auth tokens (`authToken`, `refresh_token`) MUST live in the platform secure store — never in `shared_preferences` (which is plaintext on Android). Wrapped behind `AuthSessionStorage` so the rest of the app stays agnostic.

### `lucide_icons_flutter`
- **Package name:** `lucide_icons_flutter`
- **Version:** `^3.0.0`
- **Owner:** `lucide-icons` org (Lucide community fork of Feather Icons)
- **License:** ISC (permissive — same family as MIT/BSD; commercial use allowed without attribution beyond license preservation)
- **Description:** Pure-Dart Flutter binding for the Lucide icon set (~1500 SVG glyphs exposed as `IconData`). No native code; works on Android, iOS, web, desktop. Active maintenance with frequent releases tracking upstream Lucide.
- **Why we use it:** The HotelOps web prototype uses Lucide icons across the dashboard (`Sun`, `Moon`, `Clock`, `AlertCircle`, `CheckCheck`, `ChevronRight`, `PauseCircle`, `PlayCircle`, `Bell`). Matching the visual identity 1:1 in Flutter requires the same glyph set — Material Icons cannot reproduce Lucide's stroke-style consistently.

---

## Dev dependencies

### `flutter_test`
- **Package name:** `flutter_test`
- **Version:** SDK
- **Owner:** Flutter team (Google)
- **License:** BSD-3-Clause
- **Description:** Testing framework shipped with the Flutter SDK. BSD-3-Clause.
- **Why we use it:** Runs widget and unit tests; required by `docs/08_TESTING_AND_REVIEW.md`.

### `flutter_lints`
- **Package name:** `flutter_lints`
- **Version:** `^5.0.0`
- **Owner:** Flutter team (Google)
- **License:** BSD-3-Clause
- **Description:** Recommended lint rule set for Flutter projects. BSD-3-Clause.
- **Why we use it:** Baseline static-analysis rules referenced from `analysis_options.yaml`.

### `change_app_package_name`
- **Package name:** `change_app_package_name`
- **Version:** `^1.4.0`
- **Owner:** `ekasetiawans`
- **License:** MIT
- **Description:** CLI helper that rewrites the Android `applicationId` and iOS bundle identifier in one shot. MIT.
- **Why we use it:** Used once during initial scaffolding to apply the app's bundle ID across all native projects.

### `riverpod_generator`
- **Package name:** `riverpod_generator`
- **Version:** `^2.6.4`
- **Owner:** Remi Rousselet (`rrousselGit`)
- **License:** MIT
- **Description:** `build_runner`-based generator that emits provider boilerplate from `@riverpod`-annotated functions/classes. MIT.
- **Why we use it:** Pairs with `riverpod_annotation`. Reduces hand-written provider plumbing.

### `build_runner`
- **Package name:** `build_runner`
- **Version:** `^2.4.13`
- **Owner:** Dart team (Google)
- **License:** BSD-3-Clause
- **Description:** Standard Dart code-generation runner. BSD-3-Clause.
- **Why we use it:** Required by `riverpod_generator` and any future generators (e.g. JSON serialization).

### `riverpod_lint`
- **Package name:** `riverpod_lint`
- **Version:** `^2.6.3`
- **Owner:** Remi Rousselet (`rrousselGit`)
- **License:** MIT
- **Description:** Riverpod-specific lint rules (warns on `ref` misuse, AutoDispose pitfalls, etc.). MIT.
- **Why we use it:** Catches common Riverpod mistakes at analysis time.

### `custom_lint`
- **Package name:** `custom_lint`
- **Version:** `^0.7.0`
- **Owner:** Remi Rousselet (`rrousselGit`)
- **License:** MIT
- **Description:** Plugin host that lets third-party packages publish lint rules. MIT.
- **Why we use it:** Required by `riverpod_lint`.

---

## Fonts

### Inter (loaded via `google_fonts`)
- **Owner:** Rasmus Andersson (rsms)
- **License:** SIL Open Font License 1.1 (OFL-1.1)
- **Description:** Variable sans-serif type family. OFL-1.1 explicitly permits embedding in commercial software; only restriction is that the font itself can't be sold standalone.
- **Why we use it:** Primary UI typeface across all `TypographyManager` styles.

---

## i18n status (2026-04-26)

All planned i18n packages are now landed and documented above:

- ✅ `flutter_localizations` — added.
- ✅ `intl` — bumped to `^0.20.2` to satisfy `flutter_localizations` pin.

No further i18n-related package additions are needed. The localization
pipeline relies entirely on first-party Flutter `gen-l10n` (no third-party
runtime: no `easy_localization`, no `slang`).
