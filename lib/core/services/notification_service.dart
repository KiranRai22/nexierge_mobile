import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../i18n/app_locale.dart';
import '../i18n/locale_aware_strings.dart';
import '../../l10n/generated/app_localizations.dart';

// Must be top-level — runs in an isolate when app is terminated. The isolate
// has its own LocaleAwareStrings instance with the device-locale fallback,
// which is good enough for the rare terminated-state path.
@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  debugPrint('[FCM] Background: ${message.notification?.title}');
}

/// FCM + local-notification bootstrap with i18n hooks.
///
/// Two strategies are supported for localized push:
///
/// 1. **Topic per locale.** Server publishes the same payload to `loc_en`
///    and `loc_es`, each pre-localized. Client subscribes to exactly one
///    topic at a time via [syncLocaleTopic]. Server-side cost: 1 publish
///    per supported locale, no client lookup needed.
///
/// 2. **Payload-keyed lookup.** Server omits `notification.title/body` and
///    sends `data: { l10nKey: 'createSuccessToast' }`. Client resolves the
///    string from [LocaleAwareStrings] at display time. Useful when the
///    catalogue of messages is small and server doesn't want to know about
///    locales. Wired through [_localizeFromPayload].
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  // High-importance Android channel required for heads-up notifications.
  // Channel name/description ARE shown in system Settings → Apps → Notifs,
  // so we localize them on creation. Re-creating with the same id but a
  // different name updates the user-visible label without losing prefs.
  //
  // Channel id is versioned because Android refuses to mutate the sound on
  // an existing channel — the only way to change it is to create a new one
  // under a fresh id. Bump the suffix any time the sound changes.
  static const _channelId = 'high_importance_channel_v2';
  static const _legacyChannelIds = <String>['high_importance_channel'];

  // Custom notification sound. The Android resource lives at
  // `android/app/src/main/res/raw/notification_sound.mp3` and is referenced
  // WITHOUT extension. The iOS resource lives at
  // `ios/Runner/notification_sound.caf` and is referenced WITH extension.
  // FCM payloads must use the same names for background/terminated pushes
  // (see `docs/PACKAGES_DETAILS.md` / notification payload notes).
  static const _soundAndroid = 'notification_sound';
  static const _soundIos = 'notification_sound.caf';

  final _onNotificationTap = ValueNotifier<RemoteMessage?>(null);

  /// Active locale-scoped topic, used so we can unsubscribe before swapping.
  String? _subscribedLocaleTopic;

  /// Listen to this to react when a user taps a notification.
  ValueNotifier<RemoteMessage?> get onNotificationTap => _onNotificationTap;

  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);
    await _requestPermissions();
    await _setupLocalNotifications();
    _listenForeground();
    _listenTaps();
    await _checkInitialMessage();
  }

  Future<void> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('[FCM] Auth status: ${settings.authorizationStatus}');
  }

  Future<void> _setupLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false, // already requested via FCM
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _localNotifications.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (details) {
        debugPrint('[LocalNotif] Tapped payload: ${details.payload}');
      },
    );

    await _refreshAndroidChannel();
  }

  /// (Re)create the Android channel so its visible name/description match
  /// the active locale. Idempotent — Android merges by id.
  ///
  /// Sound is set here at channel creation time. On Android 8+ the system
  /// only honours the channel-level sound; per-notification sound overrides
  /// are ignored. Once a channel exists, its sound cannot be changed — we
  /// version the channel id and delete the predecessors instead.
  Future<void> _refreshAndroidChannel() async {
    final s = LocaleAwareStrings.instance.strings;
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return;

    // Tear down obsolete channels so they don't linger in system settings.
    for (final legacyId in _legacyChannelIds) {
      await androidPlugin.deleteNotificationChannel(legacyId);
    }

    final channel = AndroidNotificationChannel(
      _channelId,
      s.notifChannelName,
      description: s.notifChannelDescription,
      importance: Importance.high,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound(_soundAndroid),
    );
    await androidPlugin.createNotificationChannel(channel);
  }

  // Show heads-up banner while app is in foreground.
  void _listenForeground() {
    FirebaseMessaging.onMessage.listen((message) {
      final localized = _localizeFromPayload(message);
      if (localized.title == null && localized.body == null) return;

      final s = LocaleAwareStrings.instance.strings;
      _localNotifications.show(
        message.hashCode,
        localized.title,
        localized.body,
        NotificationDetails(
          // Android: sound set on the channel, not here. On Android 8+ the
          // channel value wins regardless of what we pass.
          android: AndroidNotificationDetails(
            _channelId,
            s.notifChannelName,
            channelDescription: s.notifChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            sound: const RawResourceAndroidNotificationSound(_soundAndroid),
          ),
          // iOS uses the per-notification sound — no channels.
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: _soundIos,
          ),
        ),
        payload: message.data.toString(),
      );
    });
  }

  /// Resolves the user-visible title/body from a [RemoteMessage].
  ///
  /// Priority:
  ///   1. `data['l10nTitleKey']` / `data['l10nBodyKey']` → look up in
  ///      [LocaleAwareStrings]. Optional `data['l10nArg']` is interpolated
  ///      where the corresponding ARB string accepts a placeholder.
  ///   2. `notification.title` / `notification.body` (server pre-localized
  ///      via topic-per-locale strategy).
  _LocalizedNotification _localizeFromPayload(RemoteMessage m) {
    final s = LocaleAwareStrings.instance.strings;
    final data = m.data;
    final n = m.notification;

    final keyTitle = data['l10nTitleKey'] as String?;
    final keyBody = data['l10nBodyKey'] as String?;
    final arg = data['l10nArg'] as String?;

    final title = keyTitle != null
        ? _resolveKey(s, keyTitle, arg) ?? n?.title
        : n?.title;
    final body = keyBody != null
        ? _resolveKey(s, keyBody, arg) ?? n?.body
        : n?.body;

    return _LocalizedNotification(title: title, body: body);
  }

  /// Looks up a known notification key from [AppLocalizations]. Restricted
  /// to a finite allow-list so a malicious server can't pull arbitrary
  /// strings (e.g. error messages dressed up as notifications).
  String? _resolveKey(AppLocalizations s, String key, String? arg) {
    switch (key) {
      case 'createSuccessToast':
        return s.createSuccessToast;
      case 'languageChangedToast':
        return s.languageChangedToast;
      case 'comingSoonNotifications':
        return s.comingSoonNotifications;
      case 'notifGenericTitle':
        return s.notifGenericTitle;
      case 'notifNewTicket':
        // String-arg variant — accepts the ticket code.
        return s.notifNewTicket(arg ?? '');
      default:
        debugPrint('[Notif] Unknown l10n key: $key');
        return null;
    }
  }

  // App opened from background via notification tap.
  void _listenTaps() {
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _onNotificationTap.value = message;
    });
  }

  // App launched from terminated state via notification tap.
  Future<void> _checkInitialMessage() async {
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      _onNotificationTap.value = initial;
    }
  }

  Future<String?> getFCMToken() async {
    final token = await _messaging.getToken();
    debugPrint('[FCM] Token: $token');
    return token;
  }

  /// Subscribe to a generic topic (e.g. "all_users").
  Future<void> subscribeToTopic(String topic) =>
      _messaging.subscribeToTopic(topic);

  Future<void> unsubscribeFromTopic(String topic) =>
      _messaging.unsubscribeFromTopic(topic);

  /// Sync FCM topic membership with the active locale. Subscribes the
  /// device to `loc_<code>` and unsubscribes from any prior locale topic.
  /// Also re-creates the local-notification channel so its visible name in
  /// system settings matches the new language.
  ///
  /// Call this on app boot AFTER [LocaleController] resolves AND every time
  /// the user picks a new language.
  Future<void> syncLocaleTopic(AppLocale appLocale) async {
    final code = appLocale.toLocale()?.languageCode ?? _deviceLanguageCode();
    final next = 'loc_$code';

    final prev = _subscribedLocaleTopic;
    if (prev == next) {
      // Even if the topic didn't change, the underlying ARB lookups for
      // channel name/description may have — refresh anyway. Cheap.
      await _refreshAndroidChannel();
      return;
    }

    if (prev != null) {
      try {
        await _messaging.unsubscribeFromTopic(prev);
      } catch (e) {
        debugPrint('[FCM] Unsubscribe $prev failed: $e');
      }
    }

    try {
      await _messaging.subscribeToTopic(next);
      _subscribedLocaleTopic = next;
    } catch (e) {
      debugPrint('[FCM] Subscribe $next failed: $e');
    }

    await _refreshAndroidChannel();
  }

  String _deviceLanguageCode() {
    final code = PlatformDispatcher.instance.locale.languageCode;
    // Restrict to languages we actually publish for. Anything else falls
    // back to English so the user still sees something.
    return code == 'es' ? 'es' : 'en';
  }

  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;
}

class _LocalizedNotification {
  final String? title;
  final String? body;
  const _LocalizedNotification({this.title, this.body});
}
