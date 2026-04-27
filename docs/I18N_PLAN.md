# Internationalization (i18n) Plan

## Goal
Make Nexierge fully multilingual. Initial languages: **English (en)** and **Spanish (es)**. Architecture must scale to N languages without UI changes.

## Hard Requirements (from product)

1. App supports multiple languages (English & Spanish on day 1).
2. User language choice is **persistent** — survives cold start, survives logout.
3. **Every** user-visible string follows the choice:
   - Screen text
   - Snackbars / toasts / popups
   - Dialog & bottom-sheet content
   - Validation messages, error responses, empty states
   - Push notifications (FCM payload + on-device formatting)
   - Local notifications (foreground display)
4. Packages must be free for commercial use, well-maintained, support all current Android & iOS versions.

---

## Approach — Flutter's official `gen-l10n` + ARB files

We will use the **Flutter team's first-party** localization stack. It is the canonical approach, has zero license risk, and integrates with the existing `intl` dependency.

| Concern | Tool | Why |
|---|---|---|
| String catalog | ARB files (`app_en.arb`, `app_es.arb`) | Industry standard, tooling support |
| Code generation | `flutter gen-l10n` (built-in to SDK) | No third-party generator |
| Plurals / placeholders | ICU MessageFormat (built into `intl`) | Standard, well-documented |
| Date / number formatting | `intl` (already in pubspec) | Already a dependency |
| Material widget translations | `flutter_localizations` (Flutter SDK) | First-party |
| Persistence | `shared_preferences` (already in pubspec) | Already in use for `ThemeMode` |
| Locale-aware strings outside widget tree (services, errors) | `LocaleAwareStrings` thin wrapper | See "Strings outside `BuildContext`" below |

**Rejected alternatives:**
- `easy_localization`: third-party, has had maintenance gaps, redundant given first-party support exists.
- `slang`: nice DX but adds another generator on top of `riverpod_generator`/`build_runner`. Sticking to one generator.

---

## Phased Delivery

### Phase L1 — Foundation
1. Add `flutter_localizations` SDK dependency to `pubspec.yaml`.
2. Add `generate: true` flag under the `flutter:` block in `pubspec.yaml`.
3. Create `l10n.yaml` at project root with `arb-dir`, `template-arb-file`, `output-localization-file`, `nullable-getter: false`.
4. Create `lib/l10n/app_en.arb` (template) and `lib/l10n/app_es.arb`.
5. Run `flutter gen-l10n` once to validate config and generate `AppLocalizations`.

**Files added:**
- `l10n.yaml`
- `lib/l10n/app_en.arb`
- `lib/l10n/app_es.arb`

**Files modified:**
- `pubspec.yaml`

### Phase L2 — String migration
1. Move every `StringManager.<key>` constant into `app_en.arb` (keeping the same key names so the diff is a search-and-replace).
2. Translate each into `app_es.arb`.
3. Delete `core/utils/string_manager.dart` (or leave only a thin deprecation shim during migration).
4. Update every import / call-site to use `AppLocalizations.of(context).<key>` (or a short helper `context.l10n.<key>`).
5. For ALL_CAPS overlines (e.g. `INCOMING NOW`), keep the source text in normal case and apply `.toUpperCase()` at render time — Spanish capitalization rules differ.

**Helper to add:** `lib/core/i18n/l10n_extension.dart` — a one-line extension `BuildContext.l10n` that returns `AppLocalizations.of(context)`.

### Phase L3 — Locale persistence + provider
1. Add `LocaleController` (Riverpod `AsyncNotifier<Locale>`), backed by `SharedPreferences` key `app.locale`.
2. Default to system locale, falling back to English if system locale isn't supported.
3. Wire `MaterialApp.locale` and `MaterialApp.supportedLocales` from the provider.
4. Add `MaterialApp.localizationsDelegates`: `AppLocalizations.delegate`, `GlobalMaterialLocalizations.delegate`, `GlobalWidgetsLocalizations.delegate`, `GlobalCupertinoLocalizations.delegate`.

**Files added:**
- `lib/core/i18n/locale_controller.dart`

**Files modified:**
- `lib/main.dart`

### Phase L4 — Strings outside `BuildContext`
Some strings (push notification bodies, repository errors, services) cannot use `AppLocalizations.of(context)`. We will:

1. Create a singleton-style accessor `LocaleAwareStrings` that holds the current `AppLocalizations` instance.
2. Refresh it from a top-level `Builder` inside `MaterialApp.builder` whenever locale changes.
3. Services / repositories / `NotificationService` look up strings via this accessor.

**File added:** `lib/core/i18n/locale_aware_strings.dart`

### Phase L5 — Push notifications & local notifications
1. **Outgoing FCM**: send the user's locale as a custom data field (`user_locale: "es"`) to the server, and as a topic subscription `loc_es` / `loc_en`. Server-side teams localize the payload before send.
2. **Incoming FCM**: when a notification arrives, prefer payload's localized title/body if present; otherwise look up a translation key sent by the server (e.g. `data.l10n_key: "ticket_overdue"`) via `LocaleAwareStrings`.
3. **Local notifications** (`flutter_local_notifications`): pull title/body from `LocaleAwareStrings` at display time.
4. Update `NotificationService.initialize` to subscribe/unsubscribe FCM topics on locale change.

### Phase L6 — Language picker UI
1. Add a language picker bottom sheet (`LanguagePickerSheet`) listing supported locales with native names ("English", "Español").
2. Surface it from the Profile screen and from the avatar tap on `AppTopBar`.
3. Show a `SnackBar` confirmation in the *new* locale after switching.

**Files added:**
- `lib/core/i18n/language_picker_sheet.dart`

**Files modified:**
- `lib/features/profile/presentation/screens/profile_screen.dart`
- `lib/features/tickets/presentation/widgets/app_top_bar.dart` (callback already exposed; just wire it)

### Phase L7 — Polish & verification
1. Run `flutter gen-l10n` and `flutter analyze` — both must be clean.
2. Manual smoke test:
   - Switch to Spanish from Profile → cold-restart → app stays Spanish.
   - Trigger a snackbar (notifications bell) — text is Spanish.
   - Trigger an error toast (offline FAB tap) — text is Spanish.
   - Receive a local notification — text is Spanish.
3. Add a unit test that flips locale and asserts a sample string changed.
4. Document every new package in `docs/PACKAGES_DETAILS.md` (already started — see file).

---

## Risks & decisions

- **Untranslated strings**: ARB enforces parity. CI step `flutter gen-l10n` will fail if a key is missing in `app_es.arb`. We will commit translations alongside English additions — no "ship English first, translate later".
- **Server-driven content** (ticket titles, guest names): not localized; passed through as-is.
- **Adding a third language** is purely an ARB drop-in: copy `app_en.arb` → `app_xx.arb`, translate, run `flutter gen-l10n`, add `Locale('xx')` to supported list. No code changes elsewhere.

---

## Out of scope

- RTL languages (Arabic, Hebrew). Architecture doesn't preclude it — `MaterialApp` already handles RTL when the locale is RTL — but we won't validate it until we add such a language.
- In-app translation editor.
- Server-side string catalogs.
