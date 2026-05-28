import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/notification_inbox_datasource.dart';
import '../../domain/entities/notification_inbox_item.dart';
import '../../../dashboard/presentation/providers/dashboard_bootstrap_controller.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class NotificationInboxState {
  final List<NotificationInboxItem> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int offset;

  /// "all" | "unread" — maps to the status_filter request param.
  final String statusFilter;

  /// Total unread count across all pages — from API meta.
  final int totalUnreadCount;

  final String? error;

  const NotificationInboxState({
    required this.items,
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasMore,
    required this.offset,
    required this.statusFilter,
    required this.totalUnreadCount,
    this.error,
  });

  static const loading = NotificationInboxState(
    items: [],
    isLoading: true,
    isLoadingMore: false,
    hasMore: false,
    offset: 0,
    statusFilter: 'all',
    totalUnreadCount: 0,
  );

  static const empty = NotificationInboxState(
    items: [],
    isLoading: false,
    isLoadingMore: false,
    hasMore: false,
    offset: 0,
    statusFilter: 'all',
    totalUnreadCount: 0,
  );

  /// Local unread count from the currently loaded items.
  int get localUnreadCount => items.where((i) => i.unread).length;

  /// Displayed unread count — prefer server total, fall back to local.
  int get unreadCount => totalUnreadCount;

  int get totalCount => items.length;

  NotificationInboxState copyWith({
    List<NotificationInboxItem>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? offset,
    String? statusFilter,
    int? totalUnreadCount,
    String? error,
  }) {
    return NotificationInboxState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      offset: offset ?? this.offset,
      statusFilter: statusFilter ?? this.statusFilter,
      totalUnreadCount: totalUnreadCount ?? this.totalUnreadCount,
      error: error,
    );
  }
}

// ─── Controller ───────────────────────────────────────────────────────────────

class NotificationInboxController extends Notifier<NotificationInboxState> {
  static const int _pageSize = 30;

  @override
  NotificationInboxState build() {
    // Watch bootstrap so we retry when profile becomes available after a
    // cold-start race (socket connects before auth/me completes).
    ref.listen(dashboardBootstrapControllerProvider, (_, next) {
      final hasProfile = next.valueOrNull?.userProfile != null;
      if (hasProfile && state.items.isEmpty && !state.isLoading) {
        _fetchPage(offset: 0, reset: true);
      }
    });

    // Schedule first load after the frame so the sheet renders immediately.
    Future.microtask(() => _fetchPage(offset: 0, reset: true));

    return NotificationInboxState.loading;
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Called by the All / Unread tab switcher.
  void switchTab(String statusFilter) {
    if (state.statusFilter == statusFilter) return;
    state = state.copyWith(
      statusFilter: statusFilter,
      items: [],
      isLoading: true,
      offset: 0,
      hasMore: false,
      error: null,
    );
    _fetchPage(offset: 0, reset: true, filterOverride: statusFilter);
  }

  /// Pull-to-refresh — resets to page 0.
  Future<void> refresh() async {
    state = state.copyWith(
      isLoading: true,
      items: [],
      offset: 0,
      hasMore: false,
      error: null,
    );
    await _fetchPage(offset: 0, reset: true);
  }

  /// Infinite scroll — loads next page. No-op if already loading or no more.
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    await _fetchPage(offset: state.offset);
  }

  /// Marks a single notification as read — optimistic UI then API call.
  void markRead(String id) {
    if (!state.items.any((i) => i.id == id && i.unread)) return;

    // Optimistic update
    _applyLocalRead(id);

    // Fire-and-forget API call; on error we silently leave the local state
    // since the server will reconcile on next fetch.
    _callMarkRead(id);
  }

  /// Marks all currently loaded unread items as read — optimistic then API.
  void markAllAsRead() {
    final unreadIds =
        state.items.where((i) => i.unread).map((i) => i.id).toList();
    if (unreadIds.isEmpty) return;

    // Optimistic: mark all read locally immediately
    state = state.copyWith(
      items: [for (final i in state.items) i.copyWith(unread: false)],
      totalUnreadCount: 0,
    );

    // Fire API calls for each (no bulk endpoint in MVP)
    for (final id in unreadIds) {
      _callMarkRead(id);
    }
  }

  /// Called by the realtime handler when another device/session reads a
  /// notification belonging to this user. Updates local state without an
  /// API round-trip.
  void markReadLocally(String notificationEventId) {
    _applyLocalRead(notificationEventId);
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  void _applyLocalRead(String id) {
    final updated = [
      for (final i in state.items)
        if (i.id == id && i.unread) i.copyWith(unread: false) else i,
    ];
    final newUnreadCount = (state.totalUnreadCount - 1).clamp(0, 99999);
    state = state.copyWith(items: updated, totalUnreadCount: newUnreadCount);
  }

  Future<void> _fetchPage({
    required int offset,
    bool reset = false,
    String? filterOverride,
  }) async {
    final credentials = _credentials();
    if (credentials == null) {
      state = state.copyWith(isLoading: false, isLoadingMore: false);
      return;
    }

    final filter = filterOverride ?? state.statusFilter;

    try {
      final response = await ref
          .read(notificationInboxDatasourceProvider)
          .fetchNotifications(
            hotelId: credentials.$1,
            hotelUserId: credentials.$2,
            limit: _pageSize,
            offset: offset,
            statusFilter: filter,
          );

      // Detect locale from the device (en/es) to pick server label
      // We default to English for now; locale-aware pick happens in fromDto.
      const languageCode = 'en';

      final newItems = response.events
          .map((dto) =>
              NotificationInboxItem.fromDto(dto, languageCode: languageCode))
          .toList();

      final allItems = reset ? newItems : [...state.items, ...newItems];

      state = state.copyWith(
        items: allItems,
        isLoading: false,
        isLoadingMore: false,
        hasMore: response.meta.hasMore,
        offset: offset + newItems.length,
        totalUnreadCount: response.meta.unreadCount,
        error: null,
      );
    } catch (e, st) {
      debugPrint('[NotificationInboxController] fetch error: $e\n$st');
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }

  Future<void> _callMarkRead(String notificationEventId) async {
    final credentials = _credentials();
    if (credentials == null) return;

    try {
      await ref.read(notificationInboxDatasourceProvider).markAsRead(
            hotelId: credentials.$1,
            hotelUserId: credentials.$2,
            notificationEventId: notificationEventId,
          );
    } catch (e) {
      debugPrint('[NotificationInboxController] markAsRead error: $e');
    }
  }

  /// Returns (hotelId, hotelUserId) from bootstrap, or null if not ready.
  (String, String)? _credentials() {
    final bootstrap =
        ref.read(dashboardBootstrapControllerProvider).valueOrNull;
    final profile = bootstrap?.userProfile;
    if (profile == null) return null;

    final hotelId = profile.hotelDetails?.hotel.id ?? '';
    final userId = profile.id;

    if (hotelId.isEmpty || userId.isEmpty) return null;
    return (hotelId, userId);
  }
}

final notificationInboxControllerProvider =
    NotifierProvider<NotificationInboxController, NotificationInboxState>(
  NotificationInboxController.new,
);
