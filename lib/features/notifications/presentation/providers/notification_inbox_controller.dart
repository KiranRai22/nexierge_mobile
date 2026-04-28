import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/notification_inbox_item.dart';

/// Inbox state for the notifications bottom sheet.
///
/// Today fed by an in-memory mock that mirrors the Lovable prototype.
/// When the backend ships, swap `_seed()` for a repository call —
/// the UI layer keeps its contract (`items`, `unreadCount`, mark APIs).
class NotificationInboxState {
  final List<NotificationInboxItem> items;

  const NotificationInboxState({required this.items});

  static const empty = NotificationInboxState(items: <NotificationInboxItem>[]);

  int get unreadCount => items.where((i) => i.unread).length;
  int get totalCount => items.length;

  NotificationInboxState copyWith({List<NotificationInboxItem>? items}) {
    return NotificationInboxState(items: items ?? this.items);
  }
}

class NotificationInboxController extends Notifier<NotificationInboxState> {
  @override
  NotificationInboxState build() {
    return NotificationInboxState(items: _seed());
  }

  /// Mark every unread row as read. Idempotent — safe to call from a
  /// "Mark all as read" tap even when nothing is unread.
  void markAllAsRead() {
    if (state.unreadCount == 0) return;
    state = state.copyWith(
      items: [for (final i in state.items) i.copyWith(unread: false)],
    );
  }

  /// Mark a single row as read (e.g. after the user taps it to deep-link
  /// into the ticket). No-op if already read.
  void markRead(String id) {
    final updated = [
      for (final i in state.items)
        if (i.id == id && i.unread) i.copyWith(unread: false) else i,
    ];
    state = state.copyWith(items: updated);
  }

  /// Mock data — matches the four rows shown in the Lovable prototype.
  /// All four are unread so the sheet opens with the expected header
  /// ("4 unread") on first launch.
  static List<NotificationInboxItem> _seed() {
    final now = DateTime.now();
    final sevenHoursAgo = now.subtract(const Duration(hours: 7));
    return [
      NotificationInboxItem(
        id: 'n1',
        kind: NotificationInboxKind.newTicket,
        title: 'New ticket received',
        subtitle: 'Extra towels · Room 208 · Housekeeping',
        receivedAt: sevenHoursAgo,
        unread: true,
        ticketId: 't1',
      ),
      NotificationInboxItem(
        id: 'n2',
        kind: NotificationInboxKind.newTicket,
        title: 'New ticket received',
        subtitle: 'Hotel Restaurant (×3 items) · Room 304 · Room Service',
        receivedAt: sevenHoursAgo,
        unread: true,
        ticketId: 't2',
      ),
      NotificationInboxItem(
        id: 'n3',
        kind: NotificationInboxKind.newTicket,
        title: 'New ticket received',
        subtitle: 'AC not cooling · Room 512 · Maintenance',
        receivedAt: sevenHoursAgo,
        unread: true,
        ticketId: 't4',
      ),
      NotificationInboxItem(
        id: 'n4',
        kind: NotificationInboxKind.newTicket,
        title: 'New ticket received',
        subtitle: 'Pillows (2) · Room 117 · Housekeeping',
        receivedAt: sevenHoursAgo,
        unread: true,
        ticketId: 't3',
      ),
    ];
  }
}

final notificationInboxControllerProvider =
    NotifierProvider<NotificationInboxController, NotificationInboxState>(
      NotificationInboxController.new,
    );
