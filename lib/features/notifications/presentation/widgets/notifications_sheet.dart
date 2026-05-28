import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/services/sound_manager.dart';
import '../../../../core/theme/card_theme.dart';
import '../../../../core/theme/unified_theme_manager.dart';
import '../../../../core/theme/typography_manager.dart';
import '../../domain/entities/notification_inbox_item.dart';
import '../providers/notification_inbox_controller.dart';
import 'notification_card.dart';

/// Notifications inbox bottom sheet.
///
/// Structure:
///   drag handle → header (title + unread count + close)
///   → actions row (mark-all-read + total)
///   → All / Unread tab bar
///   → scrollable list with pull-to-refresh + infinite scroll
class NotificationsSheet extends ConsumerWidget {
  /// Called when the user taps a notification that links to a ticket.
  final ValueChanged<String>? onOpenTicket;

  const NotificationsSheet({super.key, this.onOpenTicket});

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
          decoration: CardDecoration.subtle(
            colors: c,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _Handle(),
              const _Header(),
              const _ActionsRow(),
              const _TabBar(),
              const Divider(height: 1),
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

// ─── Handle ───────────────────────────────────────────────────────────────────

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

// ─── Header ───────────────────────────────────────────────────────────────────

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
                  style: TypographyManager.textTitle.copyWith(color: c.fgBase),
                ),
                const SizedBox(height: 2),
                Text(
                  s.notificationsUnread(unread),
                  style: TypographyManager.textMeta.copyWith(color: c.fgMuted),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: s.cancel,
            onPressed: tapSound(
              () => Navigator.of(context).pop(),
              SoundCategory.back,
            ),
            icon: Icon(LucideIcons.x, size: 20, color: c.fgMuted),
          ),
        ],
      ),
    );
  }
}

// ─── Actions row ──────────────────────────────────────────────────────────────

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
            onTap: state.unreadCount == 0
                ? null
                : tapSound(controller.markAllAsRead),
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

// ─── Tab bar ─────────────────────────────────────────────────────────────────

class _TabBar extends ConsumerWidget {
  const _TabBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.l10n;
    final c = context.themeColors;
    final currentFilter = ref.watch(
      notificationInboxControllerProvider.select((v) => v.statusFilter),
    );
    final controller = ref.read(notificationInboxControllerProvider.notifier);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Row(
        children: [
          _Tab(
            label: s.notificationsTabAll,
            selected: currentFilter == 'all',
            onTap: () => controller.switchTab('all'),
            c: c,
          ),
          const SizedBox(width: 8),
          _Tab(
            label: s.notificationsTabUnread,
            selected: currentFilter == 'unread',
            onTap: () => controller.switchTab('unread'),
            c: c,
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final AppColors c;

  const _Tab({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? c.tagPurpleBg : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? c.tagPurpleIcon : c.borderBase,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TypographyManager.textLabel.copyWith(
            color: selected ? c.tagPurpleIcon : c.fgMuted,
          ),
        ),
      ),
    );
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────────

class _Body extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  final ValueChanged<String>? onOpenTicket;

  const _Body({
    required this.scrollController,
    required this.onOpenTicket,
  });

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    final pos = widget.scrollController.position;
    // Trigger load-more when user has scrolled 80% of available content
    if (pos.pixels >= pos.maxScrollExtent * 0.8) {
      ref.read(notificationInboxControllerProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationInboxControllerProvider);

    // First-page loading
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error state (first page)
    if (state.error != null && state.items.isEmpty) {
      return _ErrorState(
        onRetry: () =>
            ref.read(notificationInboxControllerProvider.notifier).refresh(),
      );
    }

    // Empty state
    if (state.items.isEmpty) {
      return const _EmptyState();
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(notificationInboxControllerProvider.notifier).refresh(),
      child: ListView.separated(
        controller: widget.scrollController,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, index) {
          // Load-more spinner at bottom
          if (index == state.items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final item = state.items[index];
          return NotificationCard(
            item: item,
            onTap: () => _onItemTap(item),
          );
        },
      ),
    );
  }

  void _onItemTap(NotificationInboxItem item) {
    ref.read(notificationInboxControllerProvider.notifier).markRead(item.id);

    final ticketId = item.ticketId;
    if (ticketId != null && ticketId.isNotEmpty) {
      Navigator.of(context).pop();
      widget.onOpenTicket?.call(ticketId);
    }
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

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
            child: Icon(LucideIcons.checkCheck, color: c.tagGreenIcon, size: 22),
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

// ─── Error state ──────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final c = context.themeColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.wifiOff, color: c.fgMuted, size: 32),
          const SizedBox(height: 12),
          Text(
            s.notificationsLoadError,
            textAlign: TextAlign.center,
            style: TypographyManager.textBodyStrong.copyWith(color: c.fgBase),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onRetry,
            child: Text(s.notificationsRetry),
          ),
        ],
      ),
    );
  }
}
