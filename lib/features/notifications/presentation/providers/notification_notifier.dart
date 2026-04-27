import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/notification_service.dart';
import '../../data/datasources/notification_remote_datasource.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/i_notification_repository.dart';

// ── Dependency providers ──────────────────────────────────────────────────────

final notificationServiceProvider = Provider<NotificationService>(
  (_) => NotificationService.instance,
);

final notificationDataSourceProvider = Provider<NotificationRemoteDataSource>(
  (ref) => NotificationRemoteDataSource(ref.read(notificationServiceProvider)),
);

final notificationRepositoryProvider = Provider<INotificationRepository>(
  (ref) => NotificationRepositoryImpl(ref.read(notificationDataSourceProvider)),
);

// ── State ─────────────────────────────────────────────────────────────────────

class NotificationState {
  final String? fcmToken;
  final NotificationEntity? latest;

  const NotificationState({this.fcmToken, this.latest});

  NotificationState copyWith({String? fcmToken, NotificationEntity? latest}) =>
      NotificationState(
        fcmToken: fcmToken ?? this.fcmToken,
        latest: latest ?? this.latest,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class NotificationNotifier extends AsyncNotifier<NotificationState> {
  late final INotificationRepository _repo;

  @override
  Future<NotificationState> build() async {
    _repo = ref.read(notificationRepositoryProvider);

    final token = await _repo.getFCMToken();

    // Register token with backend and keep state in sync on refresh
    if (token != null) await _repo.registerToken(token);

    // Listen for incoming foreground notifications
    ref.listen<INotificationRepository>(notificationRepositoryProvider, (
      _,
      repo,
    ) {
      repo.onNotificationReceived.listen(_onNotificationReceived);
    }, fireImmediately: true);

    _repo.onNotificationReceived.listen(_onNotificationReceived);

    return NotificationState(fcmToken: token);
  }

  void _onNotificationReceived(NotificationEntity entity) {
    final current = state.valueOrNull ?? const NotificationState();
    state = AsyncData(current.copyWith(latest: entity));
  }
}

final notificationNotifierProvider =
    AsyncNotifierProvider<NotificationNotifier, NotificationState>(
      NotificationNotifier.new,
    );
