import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/i18n/app_locale.dart';
import 'core/i18n/locale_controller.dart';
import 'core/network/api_client.dart';
import 'core/providers/sound_preferences_provider.dart';
import 'core/services/app_info_service.dart';
import 'core/services/device_token_service.dart';
import 'core/services/firebase_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/realtime/xano_notification_channel.dart';
import 'core/services/realtime/xano_socket_lifecycle.dart';
import 'core/services/sound_manager.dart';
import 'core/theme/unified_theme_manager.dart';
import 'core/theme/theme_mode_controller.dart';
import 'core/utils/string_manager.dart';
import 'core/widgets/no_internet_dialog.dart';
import 'features/auth/domain/entities/auth_session.dart';
import 'features/fcm/presentation/providers/fcm_token_sync_provider.dart';
import 'features/auth/presentation/providers/auth_session_controller.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/dashboard/domain/entities/dashboard_bootstrap_state.dart';
import 'features/dashboard/presentation/providers/dashboard_bootstrap_controller.dart';
import 'features/dashboard/presentation/screens/dashboard_shimmer_screen.dart';
import 'features/shell/presentation/screens/home_shell.dart';
import 'features/tickets/notifications/ticket_sla_scheduler.dart';
import 'features/version_control/presentation/providers/version_check_notifier.dart';
import 'features/version_control/presentation/services/update_notification_service.dart';
import 'features/version_control/presentation/widgets/force_update_bottom_sheet.dart';
import 'features/version_control/presentation/widgets/force_update_gate.dart';
import 'features/version_control/presentation/widgets/optional_update_sheet.dart';
import 'l10n/generated/app_localizations.dart';
import 'core/services/vibration_manager.dart';
import 'core/providers/vibration_preferences_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // App is portrait-only by product decision.
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // iOS Keychain persists across app deletion; SharedPreferences does not.
  // Wipe stale Keychain data on a fresh install so auto-login can't resurrect
  // a session from a previous install. Android has no equivalent leak.
  if (Platform.isIOS) {
    await _clearKeychainOnFreshInstall();
  }

  // Firebase must initialize before any Firebase service is used (Critical)
  await FirebaseService.initialize();

  // FCM + local notifications bootstrap
  await NotificationService.instance.initialize();

  // Update-nudge notification channel (separate from FCM channel)
  await UpdateNotificationService.instance.initialize();

  // Read real app version from native platform once at startup
  final appInfo = await AppInfoService.create();

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
  } catch (_) {}
  if (token != null) {
    await DeviceTokenService.saveToken(token);
  }

  runApp(
    ProviderScope(
      overrides: [
        // Wire bearer token into authed Dio. Reads from AuthSessionController
        // so any login/logout/refresh propagates to all authed requests.
        authTokenProviderOverride.overrideWith(
          (ref) =>
              ref.watch(authSessionControllerProvider).valueOrNull?.authToken,
        ),
        // Seed the real app version synchronously so every provider can read it.
        appInfoServiceProvider.overrideWithValue(appInfo),
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

    // Realtime socket: connects after login, disconnects on logout.
    // Reconnect on transport drops handled inside the service.
    ref.watch(xanoSocketLifecycleProvider);

    // FCM token refresh: keeps backend in sync whenever Firebase rotates the token.
    ref.watch(fcmTokenSyncProvider);

    // Auto-join notification channel when socket connects
    ref.watch(xanoNotificationChannelProvider);

    // Log all events received from the hub_notifications channel
    ref.watch(xanoHubNotificationsLoggerProvider);

    // Schedule local SLA reminder notifications when tickets are loaded /
    // updated. Fires at (dueAt - 3min) and dueAt; grouped on Android.
    ref.watch(ticketSlaSchedulerProvider);

    // Sync sound manager with preferences in a listener.
    ref.listen<bool>(soundPreferencesProvider, (_, next) {
      SoundManager.instance.setEnabled(next);
    });
    SoundManager.instance.setEnabled(ref.read(soundPreferencesProvider));

    // Sync vibration manager with preferences.
    ref.listen<bool>(vibrationPreferencesProvider, (_, next) {
      VibrationManager.instance.setEnabled(next);
    });
    VibrationManager.instance.setEnabled(ref.read(vibrationPreferencesProvider));

    // Listen for session changes and trigger bootstrap when authenticated
    ref.listen(authSessionControllerProvider, (prev, next) {
      final prevSession = prev?.valueOrNull;
      final nextSession = next.valueOrNull;

      // When session changes from null to authenticated, trigger bootstrap
      if (prevSession == null && nextSession != null) {
        final userId = nextSession.user?.id;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref
              .read(dashboardBootstrapControllerProvider.notifier)
              .runBootstrap(hotelUserId: userId);
        });
      }

      // When session is cleared (logout), clear bootstrap data
      if (prevSession != null && nextSession == null) {
        ref.read(dashboardBootstrapControllerProvider.notifier).clearCache();
      }
    });

    // Version-check: runs once per session after bootstrap is complete.
    // Force-update is handled by wrapping HomeShell in ForceUpdateGate.
    // Optional update shows a local notification (once per version) and a
    // bottom-sheet on first app open after the version check lands.
    ref.listen<AsyncValue<VersionCheckResult>>(versionCheckProvider, (_, next) {
      final result = next.valueOrNull;
      if (result == null) return;

      // Guard: only show the dialog once per check cycle. The provider state
      // can trigger the listener multiple times (e.g. due to widget rebuilds
      // caused by ref.watch(versionCheckProvider) elsewhere in the tree).
      // markDialogShown() is called INSIDE each branch so that VersionUpToDate
      // results never consume the guard — only actual dialogs do.
      final notifier = ref.read(versionCheckProvider.notifier);
      if (notifier.dialogShown) return;

      if (result is VersionUpdateOptional) {
        notifier.markDialogShown();
        final platformVersion = Platform.isIOS
            ? result.version.iosVersion
            : result.version.androidVersion;
        final storeUrl = notifier.storeUrl(result.version);

        // Fire-and-forget local notification (debounced per version)
        UpdateNotificationService.instance.showIfNeeded(
          version: result.version,
          platformVersion: platformVersion,
        );

        // Show in-app sheet once (after first frame)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final ctx = appNavigatorKey.currentContext;
          if (ctx == null || !ctx.mounted) return;
          OptionalUpdateSheet.show(
            ctx,
            version: result.version,
            storeUrl: storeUrl,
          );
        });
      } else if (result is VersionUpdateForced) {
        notifier.markDialogShown();
        final storeUrl = notifier.storeUrl(result.version);

        // Show non-dismissable force update bottom sheet (after first frame)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final ctx = appNavigatorKey.currentContext;
          if (ctx == null || !ctx.mounted) return;
          ForceUpdateBottomSheet.show(
            ctx,
            version: result.version,
            storeUrl: storeUrl,
          );
        });
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
      navigatorKey: appNavigatorKey,
      builder: (context, child) =>
          ConnectivityGate(child: child ?? const SizedBox.shrink()),
      home: _resolveHome(session, bootstrap, ref),
    );
  }

  Widget _resolveHome(
    AsyncValue<AuthSession?> session,
    AsyncValue<DashboardBootstrapState> bootstrap,
    WidgetRef ref,
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
              final versionResult = ref.watch(versionCheckProvider);
              final result = versionResult.valueOrNull;
              final notifier = ref.read(versionCheckProvider.notifier);
              final forced = result is VersionUpdateForced ? result : null;
              return ForceUpdateGate(
                isForced: forced != null,
                version: forced?.version,
                storeUrl: forced != null
                    ? notifier.storeUrl(forced.version)
                    : '',
                child: const HomeShell(),
              );
            }
            return const DashboardShimmerScreen();
          },
        );
      },
    );
  }
}

/// Single navigator key so we can push the optional-update sheet from the
/// version-check listener without requiring a BuildContext.
final appNavigatorKey = GlobalKey<NavigatorState>();

class _AuthBootstrapSplash extends StatelessWidget {
  const _AuthBootstrapSplash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

/// iOS Keychain entries survive app deletion (system-level storage).
/// SharedPreferences lives in the app sandbox and IS wiped on delete.
/// We use that asymmetry: if the launch flag is absent → fresh install →
/// nuke the Keychain so a stale session can't resurrect auto-login.
Future<void> _clearKeychainOnFreshInstall() async {
  if (!Platform.isIOS) return;
  final prefs = await SharedPreferences.getInstance();
  const kLaunchFlag = 'app.has_launched';
  if (prefs.getBool(kLaunchFlag) == true) return;
  const storage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  await storage.deleteAll();
  await prefs.setBool(kLaunchFlag, true);
}
