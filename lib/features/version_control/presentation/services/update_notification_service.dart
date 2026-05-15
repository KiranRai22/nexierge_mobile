import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/app_version.dart';

/// Schedules (and debounces) the local notification that nudges the user
/// about an optional update. Only shows once per version so the operator
/// isn't spammed across sessions.
class UpdateNotificationService {
  UpdateNotificationService._();
  static final UpdateNotificationService instance =
      UpdateNotificationService._();

  static const _channelId = 'update_channel';
  static const _channelName = 'App Updates';
  static const _channelDesc = 'Notifications about available app updates';
  static const _notifId = 9000;
  static const _shownVersionKey = 'update.notif_shown_version';

  final _plugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (details) {
        debugPrint('[UpdateNotif] Tapped: ${details.payload}');
      },
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      const channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDesc,
        importance: Importance.defaultImportance,
      );
      await androidPlugin.createNotificationChannel(channel);
    }
  }

  /// Shows the optional-update notification for [version] unless it was
  /// already shown for this exact version in a prior session.
  Future<void> showIfNeeded({
    required AppVersion version,
    required String platformVersion,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyShown = prefs.getString(_shownVersionKey);
    if (alreadyShown == platformVersion) return;

    await _plugin.show(
      _notifId,
      version.title,
      version.description,
      NotificationDetails(
        android: const AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: false,
          presentSound: false,
        ),
      ),
    );

    await prefs.setString(_shownVersionKey, platformVersion);
    debugPrint('[UpdateNotif] Shown for version $platformVersion');
  }

  Future<void> cancel() async {
    await _plugin.cancel(_notifId);
  }
}
