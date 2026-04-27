import 'package:firebase_messaging/firebase_messaging.dart';

import '../../../../core/services/notification_service.dart';
import '../models/notification_model.dart';

class NotificationRemoteDataSource {
  final NotificationService _service;

  NotificationRemoteDataSource(this._service);

  Future<String?> getFCMToken() => _service.getFCMToken();

  // Called once the token is retrieved — POST it to your backend so the
  // server can send targeted pushes to this device.
  // Replace with your real HTTP client call when ready.
  Future<void> registerToken(String token) async {
    // TODO: call APIEndpoints.registerFcmToken with the token
    // e.g. await _httpClient.post(APIEndpoints.registerFcmToken, body: {'token': token});
  }

  // Maps raw FCM foreground messages to typed models
  Stream<NotificationModel> get onNotificationReceived {
    return FirebaseMessaging.onMessage.map(
      NotificationModel.fromRemoteMessage,
    );
  }
}
