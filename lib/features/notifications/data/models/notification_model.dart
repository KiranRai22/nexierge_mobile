import 'package:firebase_messaging/firebase_messaging.dart';

import '../../domain/entities/notification_entity.dart';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final DateTime receivedAt;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.data,
    required this.receivedAt,
  });

  factory NotificationModel.fromRemoteMessage(RemoteMessage message) {
    return NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: message.notification?.title ?? '',
      body: message.notification?.body ?? '',
      data: message.data,
      receivedAt: DateTime.now(),
    );
  }

  NotificationEntity toEntity() => NotificationEntity(
        id: id,
        title: title,
        body: body,
        data: data,
        receivedAt: receivedAt,
      );
}
