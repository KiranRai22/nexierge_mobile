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
    required String statusFilter, // "all" | "unread" | "read"
    String scopeFilter = 'all',
  });

  /// Marks a single notification event as read for the current user.
  Future<void> markAsRead({
    required String hotelId,
    required String hotelUserId,
    required String notificationEventId,
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
    String scopeFilter = 'all',
  }) async {
    final res = await _dio.post(
      APIEndpoints.notificationsTickets,
      data: {
        'hotel_id': hotelId,
        'hotel_user_id': hotelUserId,
        // API expects string values for limit and offset
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
}

/// Provider — uses the same authenticated Dio instance as the rest of the app.
final notificationInboxDatasourceProvider =
    Provider<NotificationInboxDatasource>((ref) {
  final dio = ref.watch(dioProvider);
  return _NotificationInboxDatasourceImpl(dio);
});
