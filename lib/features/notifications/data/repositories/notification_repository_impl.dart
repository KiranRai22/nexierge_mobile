import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/i_notification_repository.dart';
import '../datasources/notification_remote_datasource.dart';

class NotificationRepositoryImpl implements INotificationRepository {
  final NotificationRemoteDataSource _dataSource;

  NotificationRepositoryImpl(this._dataSource);

  @override
  Future<String?> getFCMToken() => _dataSource.getFCMToken();

  @override
  Future<void> registerToken(String token) =>
      _dataSource.registerToken(token);

  @override
  Stream<NotificationEntity> get onNotificationReceived =>
      _dataSource.onNotificationReceived.map((model) => model.toEntity());
}
