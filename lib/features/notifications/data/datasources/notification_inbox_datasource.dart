import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../dtos/notification_ticket_dto.dart';

abstract class NotificationInboxDatasource {
  /// Fetches a paginated list of notification events for the current user.
  Future<NotificationTicketsResponseDto> fetchNotifications({
    required String hotelId,
    required String hotelUserId,
    required int limit,
    required int offset,
    required String statusFilter, // "unread" | "read"
    String scopeFilter = 'unread',
  });

  /// Marks a single notification event as read for the current user.
  Future<void> markAsRead({
    required String hotelId,
    required String hotelUserId,
    required String notificationEventId,
  });

  /// Clears all read notifications for the current user.
  Future<void> clearAllRead({
    required String hotelId,
    required String hotelUserId,
  });
}

class _NotificationInboxDatasourceImpl implements NotificationInboxDatasource {
  final Dio _dio;
  _NotificationInboxDatasourceImpl(this._dio);

  @override
  Future<NotificationTicketsResponseDto> fetchNotifications({
    required String hotelId,
    required String hotelUserId,
    required int limit,
    required int offset,
    required String statusFilter,
    String scopeFilter = 'unread',
  }) async {
    final res = await _dio.get(
      APIEndpoints.notificationsTickets,
      queryParameters: {
        'hotel_id': hotelId,
        'hotel_user_id': hotelUserId,
        'limit': limit.toString(),
        'offset': offset.toString(),
        'status_filter': statusFilter,
        'scope_filter': scopeFilter,
      },
    );
    final data = res.data as Map<String, dynamic>;
    return NotificationTicketsResponseDto.fromJson(data);
  }

  @override
  Future<void> markAsRead({
    required String hotelId,
    required String hotelUserId,
    required String notificationEventId,
  }) async {
    await _dio.post(
      APIEndpoints.notificationsMarkRead,
      data: {
        'hotel_id': hotelId,
        'hotel_user_id': hotelUserId,
        'notification_event_id': notificationEventId,
      },
    );
  }

  @override
  Future<void> clearAllRead({
    required String hotelId,
    required String hotelUserId,
  }) async {
    await _dio.post(
      APIEndpoints.notificationsClearRead,
      data: {
        'hotel_id': hotelId,
        'hotel_user_id': hotelUserId,
      },
    );
  }
}

/// Provider — uses the same authenticated Dio instance as the rest of the app.
final notificationInboxDatasourceProvider =
    Provider<NotificationInboxDatasource>((ref) {
  final dio = ref.watch(authedDioProvider);
  return _NotificationInboxDatasourceImpl(dio);
});
