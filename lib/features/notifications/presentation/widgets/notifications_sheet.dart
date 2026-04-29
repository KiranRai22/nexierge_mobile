import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/theme/unified_theme_manager.dart';
import '../../../../core/theme/typography_manager.dart';
import '../../domain/entities/notification_inbox_item.dart';
import '../providers/notification_inbox_controller.dart';
import 'notification_card.dart';

/// Notifications inbox bottom sheet. Mirrors the Lovable prototype:
/// drag handle → header (title + close) → unread count + actions →
/// scrollable list of `NotificationCard`s.
///
/// Sheet is draggable: starts at ~60% height, snaps to 95% on a long
/// drag, content scrolls when the sheet is fully expanded.
class NotificationsSheet extends ConsumerWidget {
  /// Optional callback when the user taps a row that has a `ticketId`.
  /// Receives the ticket id so the host (DashboardScreen) can route.
  final ValueChanged<String>? onOpenTicket;

  const NotificationsSheet({super.key, this.onOpenTicket});

  /// Launch helper. Owns the modal-bottom-sheet config so call sites
  /// don't repeat the boilerplate.
  static Future<void> show(
    BuildContext context, {
    ValueChanged<String>? onOpenTicket,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (_) => NotificationsSheet(onOpenTicket: onOpenTicket),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.themeColors;
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      snap: true,
      snapSizes: const [0.6, 0.95],
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: c.bgBase,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _Handle(),
              const _Header(),
              const _ActionsRow(),
              const SizedBox(height: 8),
              Expanded(
                child: _Body(
                  scrollController: scrollController,
                  onOpenTicket: onOpenTicket,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Handle extends StatelessWidget {
  const _Handle();

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: c.borderBase,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.l10n;
    final c = context.themeColors;
    final unread = ref.watch(
      notificationInboxControllerProvider.select((v) => v.unreadCount),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.notificationsTitle,
                  style: TypographyManager.textTitle.copyWith(
                    color: c.fgBase,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  s.notificationsUnread(unread),
                  style: TypographyManager.textMeta.copyWith(
                    color: c.fgMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: s.cancel,
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(LucideIcons.x, size: 20, color: c.fgMuted),
          ),
        ],
      ),
    );
  }
}

class _ActionsRow extends ConsumerWidget {
  const _ActionsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.l10n;
    final c = context.themeColors;
    final state = ref.watch(notificationInboxControllerProvider);
    final controller = ref.read(notificationInboxControllerProvider.notifier);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Row(
        children: [
          InkWell(
            onTap: state.unreadCount == 0 ? null : controller.markAllAsRead,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Text(
                s.notificationsMarkAllRead,
                style: TypographyManager.textLabel.copyWith(
                  color: state.unreadCount == 0
                      ? c.fgSubtle
                      : c.tagPurpleIcon,
                ),
              ),
            ),
          ),
          const Spacer(),
          Text(
            s.notificationsTotal(state.totalCount),
            style: TypographyManager.textMeta.copyWith(color: c.fgMuted),
          ),
        ],
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  final ScrollController scrollController;
  final ValueChanged<String>? onOpenTicket;

  const _Body({required this.scrollController, required this.onOpenTicket});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(
      notificationInboxControllerProvider.select((v) => v.items),
    );

    if (items.isEmpty) {
      return const _EmptyState();
    }

    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, index) {
        final item = items[index];
        return NotificationCard(
          item: item,
          onTap: () => _onItemTap(context, ref, item),
        );
      },
    );
  }

  void _onItemTap(
    BuildContext context,
    WidgetRef ref,
    NotificationInboxItem item,
  ) {
    ref.read(notificationInboxControllerProvider.notifier).markRead(item.id);
    final ticketId = item.ticketId;
    if (ticketId != null) {
      Navigator.of(context).pop();
      onOpenTicket?.call(ticketId);
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final c = context.themeColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: c.tagGreenBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.checkCheck,
              color: c.tagGreenIcon,
              size: 22,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            s.notificationsEmpty,
            style: TypographyManager.textBodyStrong.copyWith(color: c.fgBase),
          ),
          const SizedBox(height: 4),
          Text(
            s.notificationsEmptyHint,
            textAlign: TextAlign.center,
            style: TypographyManager.textMeta.copyWith(color: c.fgMuted),
          ),
        ],
      ),
    );
  }
}
