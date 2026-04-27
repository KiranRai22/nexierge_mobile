import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/i18n/app_locale.dart';
import 'core/i18n/locale_controller.dart';
import 'core/services/device_token_service.dart';
import 'core/services/firebase_service.dart';
import 'core/services/notification_service.dart';
import 'core/theme/theme_manager.dart';
import 'core/theme/theme_mode_controller.dart';
import 'core/utils/string_manager.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'l10n/generated/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // App is portrait-only by product decision.
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Firebase must initialize before any Firebase service is used (Critical)
  await FirebaseService.initialize();

  // FCM + local notifications bootstrap
  await NotificationService.instance.initialize();

  // Retrieve and persist device token to shared_preferences.
  // This token is used during login to enable push notifications.
  // Validated in background: if null/unavailable, login still proceeds
  // but push features are disabled until token is available.
  final token = await NotificationService.instance.getFCMToken();
  if (token != null) {
    await DeviceTokenService.saveToken(token);
  }
  debugPrint(
    '[DeviceToken] Saved to preferences: ${token != null ? 'present' : 'null'}',
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode =
        ref.watch(themeModeControllerProvider).valueOrNull ?? ThemeMode.system;
    final appLocale =
        ref.watch(localeControllerProvider).valueOrNull ?? AppLocale.system;
    return MaterialApp(
      title: StringManager.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeManager.lightTheme,
      darkTheme: ThemeManager.darkTheme,
      themeMode: mode,
      // i18n. `null` locale = follow device. Always pass the full delegate
      // bundle so Material/Cupertino widgets localize too.
      locale: appLocale.toLocale(),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: const LoginScreen(),
    );
  }
}
