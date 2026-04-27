# Changelog

All notable changes to Nexierge TM are documented here.
Format: `[Date] | Title | Label | Files Affected`

---

## [2026-04-25] — Package Additions + Google Fonts Wiring

**Title:** Install Riverpod Suite, Google Fonts, Socket.IO; Wire Inter Font into TypographyManager  
**Description:** Added all state management (prod + dev), font, and realtime packages. Migrated TypographyManager from hardcoded Roboto `const TextStyle` fields to `GoogleFonts.inter()` getters (runtime-loaded, not const). Updated `_textTheme` in ThemeManager from `const` field to `get` to match. Added `custom_lint` plugin to `analysis_options.yaml` so `riverpod_lint` rules surface in IDE.

| File | Change | Label |
|------|--------|-------|
| `pubspec.yaml` | **Updated** — Added `flutter_riverpod`, `riverpod_annotation`, `google_fonts`, `socket_io_client` (prod); `riverpod_generator`, `build_runner`, `riverpod_lint`, `custom_lint` (dev) | **(Critical)** |
| `analysis_options.yaml` | **Updated** — Added `analyzer: plugins: - custom_lint` for IDE lint integration | **(Medium)** |
| `lib/core/theme/typography_manager.dart` | **Updated** — All 15 `static const TextStyle` fields → `static TextStyle get` getters using `GoogleFonts.inter()` | **(Critical, UI)** |
| `lib/core/theme/theme_manager.dart` | **Updated** — `static const TextTheme _textTheme` → `static TextTheme get _textTheme` (Google Fonts not const-compatible) | **(Critical, UI)** |

---

## [2026-04-25] — Firebase Duplicate App Fix

**Title:** Fix `[core/duplicate-app]` crash on hot restart  
**Description:** Firebase was being initialized unconditionally on every `main()` call. On Android, hot restart keeps the native process alive so Firebase was already initialized, causing a crash on the second call.

| File | Change | Label |
|------|--------|-------|
| `lib/core/services/firebase_service.dart` | **Updated** — Added `if (Firebase.apps.isNotEmpty) return;` guard before `initializeApp()` | **(Critical, Logic)** |

---

## [2026-04-25] — Package Name Change

**Title:** Rename App Package ID — `io.nexierge.nexierge_tm` → `com.nexierge.app`  
**Description:** Used `change_app_package_name` to atomically rename the package across Android and iOS. All platform-specific identifiers updated consistently.

| File | Change | Label |
|------|--------|-------|
| `pubspec.yaml` | **Updated** — Added `change_app_package_name: ^1.4.0` to dev_dependencies | **(Medium)** |
| `android/app/build.gradle.kts` | **Updated** — `applicationId` → **`com.nexierge.app`** | **(Critical)** |
| `android/app/src/main/AndroidManifest.xml` | **Updated** — package attribute updated | **(Critical)** |
| `android/app/src/debug/AndroidManifest.xml` | **Updated** — package attribute updated | **(Critical)** |
| `android/app/src/profile/AndroidManifest.xml` | **Updated** — package attribute updated | **(Critical)** |
| `android/app/src/main/kotlin/com/nexierge/app/MainActivity.kt` | **Moved** — Kotlin source directory restructured from `io/nexierge/nexierge_tm/` | **(Critical)** |
| `ios/Runner.xcodeproj/project.pbxproj` | **Updated** — `PRODUCT_BUNDLE_IDENTIFIER` → **`com.nexierge.app`** | **(Critical, iOS)** |

---

## [2026-04-25] — Android Desugaring Fix

**Title:** Fix Android Build — Core Library Desugaring  
**Description:** `flutter_local_notifications` uses Java 8+ time APIs (`java.time.*`) that don't exist on older Android versions without desugaring. Enabled it and added the desugar runtime library.

| File | Change | Label |
|------|--------|-------|
| `android/app/build.gradle.kts` | **Updated** — `isCoreLibraryDesugaringEnabled = true` in `compileOptions` | **(Critical)** |
| `android/app/build.gradle.kts` | **Updated** — Added `coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")` dependency | **(Critical)** |

---

## [2026-04-25] — Base Layer Bootstrap

**Title:** Create Core Base Layer  
**Description:** Bootstrapped the entire base layer for the project. All future features must consume these modules rather than defining their own colors, styles, strings, or widgets.

### Changes

| File | Change | Label |
|------|--------|-------|
| `lib/core/theme/color_palette.dart` | **New** — Single source of truth for all colors (primary, secondary, semantic, neutrals, text, background) | **(Critical)** |
| `lib/core/theme/typography_manager.dart` | **New** — All text styles following Material 3 type scale (display → label) | **(Critical)** |
| `lib/core/theme/theme_manager.dart` | **New** — Light and dark `ThemeData` consuming `ColorPalette` + `TypographyManager`. Includes AppBar, Button, TextField, Card themes | **(Critical, UI)** |
| `lib/core/network/api_endpoints.dart` | **New** — Centralized API base URL, auth endpoints, timeout constants, and header keys | **(Medium)** |
| `lib/core/utils/string_manager.dart` | **New** — All app strings: auth labels, error messages, success messages, validation messages, common labels | **(Medium)** |
| `lib/core/error/error_handler.dart` | **New** — `AppException` type + `ErrorHandler.handle()` for centralized error classification from HTTP codes and exception messages | **(Critical, Logic)** |
| `lib/core/widgets/widget_manager.dart` | **New** — Reusable widgets: `AppPrimaryButton`, `AppOutlinedButton`, `AppTextField`, `AppLoader`, `AppEmptyState`, `AppErrorWidget` | **(Medium, UI)** |
| `lib/main.dart` | **Updated** — Replaced inline `ThemeData` with `ThemeManager.lightTheme` / `darkTheme`. App title sourced from `StringManager` | **(Medium)** |

### Rules Enforced
- No hardcoded colors, font sizes, or string literals anywhere
- All managers are `abstract` — cannot be instantiated
- Dependency direction: `WidgetManager` → `TypographyManager` + `ColorPalette` + `StringManager` (no upward imports)

---

## [2026-04-25] — Firebase & Push Notification Setup

**Title:** Firebase Core + FCM Push Notifications (Android & iOS)  
**Description:** Full Firebase integration and push notification readiness for both platforms. Architecture-compliant: all Firebase access is wrapped in services, all FCM data flows through the repository layer. App will not receive push notifications until real credentials are dropped in.

### Changes

| File | Change | Label |
|------|--------|-------|
| `pubspec.yaml` | **Updated** — Added `flutter_riverpod`, `firebase_core`, `firebase_messaging`, `flutter_local_notifications` | **(Critical)** |
| `android/settings.gradle.kts` | **Updated** — Registered `com.google.gms.google-services` v4.4.2 plugin | **(Critical)** |
| `android/app/build.gradle.kts` | **Updated** — Applied `com.google.gms.google-services` plugin | **(Critical)** |
| `android/app/src/main/AndroidManifest.xml` | **Updated** — `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`, `VIBRATE` permissions; FCM channel + icon meta-data | **(Critical)** |
| `ios/Runner/Info.plist` | **Updated** — `UIBackgroundModes` (fetch, remote-notification) + usage description | **(Critical, iOS)** |
| `ios/Runner/AppDelegate.swift` | **Updated** — `FirebaseApp.configure()`, APNs token forwarding, `MessagingDelegate` | **(Critical, iOS)** |
| `lib/firebase_options.dart` | **New (placeholder)** — Replace all values via `flutterfire configure` | **(Critical)** |
| `lib/core/services/firebase_service.dart` | **New** — Wraps `Firebase.initializeApp()` | **(Critical, Logic)** |
| `lib/core/services/notification_service.dart` | **New** — Singleton: FCM permissions, local channel, foreground display, background handler, tap stream, topic subscriptions | **(Critical, Logic)** |
| `lib/features/notifications/domain/entities/notification_entity.dart` | **New** — Pure domain notification model | **(Medium, Logic)** |
| `lib/features/notifications/domain/repositories/i_notification_repository.dart` | **New** — Abstract repository contract | **(Medium, Logic)** |
| `lib/features/notifications/data/models/notification_model.dart` | **New** — `RemoteMessage` → entity DTO | **(Medium, Logic)** |
| `lib/features/notifications/data/datasources/notification_remote_datasource.dart` | **New** — FCM source + backend token registration stub | **(Medium, Logic)** |
| `lib/features/notifications/data/repositories/notification_repository_impl.dart` | **New** — Repository implementation | **(Medium, Logic)** |
| `lib/features/notifications/presentation/providers/notification_notifier.dart` | **New** — `AsyncNotifier<NotificationState>` + Riverpod providers | **(Medium, Logic)** |
| `lib/main.dart` | **Updated** — `async main`, Firebase + Notification init, `ProviderScope` root | **(Critical)** |

---
