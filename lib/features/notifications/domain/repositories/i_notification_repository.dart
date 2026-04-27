import '../entities/notification_entity.dart';

abstract class INotificationRepository {
  /// Returns the current FCM device token.
  Future<String?> getFCMToken();

  /// Sends the FCM token to the backend so the server can target this device.
  Future<void> registerToken(String token);

  /// Emits each incoming foreground notification as an entity.
  Stream<NotificationEntity> get onNotificationReceived;
}
