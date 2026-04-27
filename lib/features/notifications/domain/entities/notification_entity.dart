class NotificationEntity {
  final String id;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final DateTime receivedAt;

  const NotificationEntity({
    required this.id,
    required this.title,
    required this.body,
    required this.data,
    required this.receivedAt,
  });
}
