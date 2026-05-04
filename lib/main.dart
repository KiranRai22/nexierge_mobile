import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/i18n/app_locale.dart';
import 'core/i18n/locale_controller.dart';
import 'core/network/api_client.dart';
import 'core/providers/sound_preferences_provider.dart';
import 'core/services/device_token_service.dart';
import 'core/services/firebase_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/realtime/xano_notification_channel.dart';
import 'core/services/realtime/xano_socket_lifecycle.dart';
import 'core/services/sound_manager.dart';
import 'core/theme/unified_theme_manager.dart';
import 'core/theme/theme_mode_controller.dart';
import 'core/utils/string_manager.dart';
import 'features/auth/domain/entities/auth_session.dart';
import 'features/auth/presentation/providers/auth_session_controller.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/dashboard/domain/entities/dashboard_bootstrap_state.dart';
import 'features/dashboard/presentation/providers/dashboard_bootstrap_controller.dart';
import 'features/dashboard/presentation/screens/dashboard_shimmer_screen.dart';
import 'features/shell/presentation/screens/home_shell.dart';
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

  // Initialize sound manager for UI sounds
  await SoundManager.instance.initialize();

  // Retrieve and persist device token to shared_preferences.
  // This token is used during login to enable push notifications.
  // Validated in background: if null/unavailable, login still proceeds
  // but push features are disabled until token is available.
  // Wrapped in timeout to prevent network hangs from blocking startup.
  String? token;
  try {
    token = await NotificationService.instance.getFCMToken().timeout(
      const Duration(seconds: 5),
    );
  } catch (e) {
    debugPrint('[DeviceToken] Failed to fetch: $e');
  }
  if (token != null) {
    await DeviceTokenService.saveToken(token);
  }
  debugPrint(
    '[DeviceToken] Saved to preferences: ${token != null ? 'present' : 'null'}',
  );

  runApp(
    ProviderScope(
      overrides: [
        // Wire bearer token into authed Dio. Reads from AuthSessionController
        // so any login/logout/refresh propagates to all authed requests.
        authTokenProviderOverride.overrideWith(
          (ref) =>
              ref.watch(authSessionControllerProvider).valueOrNull?.authToken,
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode =
        ref.watch(themeModeControllerProvider).valueOrNull ?? ThemeMode.system;
    final appLocale =
        ref.watch(localeControllerProvider).valueOrNull ?? AppLocale.system;
    final session = ref.watch(authSessionControllerProvider);
    final bootstrap = ref.watch(dashboardBootstrapControllerProvider);
    final soundEnabled = ref.watch(soundPreferencesProvider);

    // Realtime socket: connects after login, disconnects on logout.
    // Reconnect on transport drops handled inside the service.
    ref.watch(xanoSocketLifecycleProvider);

    // Auto-join notification channel when socket connects
    ref.watch(xanoNotificationChannelProvider);

    // Sync sound manager with preferences
    SoundManager.instance.setEnabled(soundEnabled);

    // Listen for session changes and trigger bootstrap when authenticated
    ref.listen(authSessionControllerProvider, (prev, next) {
      final prevSession = prev?.valueOrNull;
      final nextSession = next.valueOrNull;

      // When session changes from null to authenticated, trigger bootstrap
      if (prevSession == null && nextSession != null) {
        final userId = nextSession.user?.id;
        debugPrint(
          '[MyApp] New session detected, triggering bootstrap with userId: $userId',
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref
              .read(dashboardBootstrapControllerProvider.notifier)
              .runBootstrap(hotelUserId: userId);
        });
      }

      // When session is cleared (logout), clear bootstrap data
      if (prevSession != null && nextSession == null) {
        debugPrint('[MyApp] Session cleared, resetting bootstrap...');
        ref.read(dashboardBootstrapControllerProvider.notifier).clearCache();
      }
    });

    return MaterialApp(
      title: StringManager.appName,
      debugShowCheckedModeBanner: false,
      theme: UnifiedThemeManager.lightTheme,
      darkTheme: UnifiedThemeManager.darkTheme,
      themeMode: mode,
      // i18n. `null` locale = follow device. Always pass the full delegate
      // bundle so Material/Cupertino widgets localize too.
      locale: appLocale.toLocale(),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      // Routing logic:
      // 1. Loading → Splash screen
      // 2. No session → Login
      // 3. Session + Bootstrap loading → Shimmer
      // 4. Session + Bootstrap complete → HomeShell
      home: _resolveHome(session, bootstrap),
    );
  }

  Widget _resolveHome(
    AsyncValue<AuthSession?> session,
    AsyncValue<DashboardBootstrapState> bootstrap,
  ) {
    return session.when(
      loading: () => const _AuthBootstrapSplash(),
      error: (_, _) => const LoginScreen(),
      data: (s) {
        if (s == null) return const LoginScreen();

        // Has session - check bootstrap status
        return bootstrap.when(
          loading: () => const DashboardShimmerScreen(),
          error: (_, __) => const DashboardShimmerScreen(), // Retry via UI
          data: (state) {
            if (state.isComplete) {
              return const HomeShell();
            }
            return const DashboardShimmerScreen();
          },
        );
      },
    );
  }
}

class _AuthBootstrapSplash extends StatelessWidget {
  const _AuthBootstrapSplash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
