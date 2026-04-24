# Copilot Instructions for daily_expense

- This repository is a vanilla Flutter application. The app entrypoint is `lib/main.dart` and currently uses a single `MaterialApp` with a `Scaffold` and centered `Text`.
- `pubspec.yaml` includes only the Flutter SDK plus `flutter_test` and `flutter_lints`. There are no additional third-party packages or custom state management frameworks currently in use.
- Use Flutter conventions: `lib/` contains Dart source, platform folders are managed by Flutter (`android/`, `ios/`, `web/`, `linux/`, `macos/`, `windows/`).
- Keep changes scoped to Flutter idioms and standard Dart style. Prefer `const` where possible, use 2-space indentation, camelCase for variables and methods, PascalCase for classes.
- Build and run commands:
  - `flutter pub get`
  - `flutter run` (or `flutter run -d <device>`)
  - `flutter test`
- Since this project has no custom architecture yet, do not introduce unnecessary complexity. If adding structure, keep it minimal and idiomatic for Flutter apps.
- When editing the app, update `lib/main.dart` first for UI changes and preserve the simple `runApp(const MainApp())` entrypoint.
- Tests should use Flutter's built-in testing library and be placed under `test/` if added.
- Avoid making assumptions about external integrations; this repo currently has no backend dependencies or package-based services configured.
- If you add new files or packages, document the purpose clearly in the same commit and keep the app bootstrap in `lib/main.dart` straightforward.
- Refer to `.github/instructions/code_rules.instructions.md` for general project style and quality expectations, but focus Copilot responses on this repository's actual current implementation.
