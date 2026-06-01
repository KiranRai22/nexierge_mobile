import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/services/sound_manager.dart';
import '../../../../core/theme/card_theme.dart';
import '../../../../core/theme/unified_theme_manager.dart';
import '../../../../core/theme/typography_manager.dart';
import '../../../../core/widgets/shimmer_widget.dart';
import '../../domain/entities/notification_inbox_item.dart';
import '../providers/notification_inbox_controller.dart';
import 'notification_card.dart';

/// Notifications inbox bottom sheet.
///
/// Structure:
///   drag handle → header row (title + mark-all-read + close)
///   → Unread / Read underline tab bar with counts
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
              const _TabBar(),
              const _InfoBar(),
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

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final c = context.themeColors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            s.notificationsTitle,
            style: TypographyManager.textTitle.copyWith(color: c.fgBase),
          ),
          const Spacer(),
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

// ─── Tab bar ─────────────────────────────────────────────────────────────────

class _TabBar extends ConsumerWidget {
  const _TabBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.l10n;
    final c = context.themeColors;
    final state = ref.watch(notificationInboxControllerProvider);
    final controller = ref.read(notificationInboxControllerProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.borderBase, width: 1)),
      ),
      child: Row(
        children: [
          _Tab(
            label: s.notificationsTabUnread,
            count: state.totalUnreadCount,
            icon: LucideIcons.eyeOff,
            selected: state.statusFilter == 'unread',
            onTap: tapSound(() => controller.switchTab('unread')),
            c: c,
          ),
          _Tab(
            label: s.notificationsTabRead,
            count: null,
            icon: LucideIcons.eye,
            selected: state.statusFilter == 'read',
            onTap: tapSound(() => controller.switchTab('read')),
            c: c,
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final int? count;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;
  final AppColors c;

  const _Tab({
    required this.label,
    required this.count,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? c.fgBase : c.fgMuted;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? c.fgBase : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TypographyManager.textLabel.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (count case final n? when n > 0) ...[
              const SizedBox(width: 5),
              Container(
                width: 18,
                height: 18,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? c.tagPurpleBg : c.bgSubtle,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  n > 99 ? '99+' : n.toString(),
                  style: TypographyManager.textMeta.copyWith(
                    fontSize: 9,
                    color: selected ? c.tagPurpleText : c.fgMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Info bar ────────────────────────────────────────────────────────────────

class _InfoBar extends ConsumerWidget {
  const _InfoBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.l10n;
    final c = context.themeColors;
    final state = ref.watch(notificationInboxControllerProvider);
    final controller = ref.read(notificationInboxControllerProvider.notifier);
    final isRead = state.statusFilter == 'read';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              isRead ? s.notificationsInfoRead : s.notificationsInfoUnread,
              style: TypographyManager.textMeta.copyWith(
                color: c.fgMuted,
                fontSize: 11,
              ),
            ),
          ),
          if (isRead && state.items.isNotEmpty) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: tapSound(() => controller.clearAllRead()),
              child: Text(
                s.notificationsClearAll,
                style: TypographyManager.textMeta.copyWith(
                  color: c.tagPurpleIcon,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
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
      return const _NotificationListSkeleton();
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
        itemCount: state.items.length + (state.isLoadingMore ? 10 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, index) {
          // Load-more skeletons at bottom — one per incoming item slot
          if (index >= state.items.length) {
            return const _NotificationCardSkeleton();
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

// ─── Skeleton loaders ────────────────────────────────────────────────────────

class _NotificationCardSkeleton extends StatelessWidget {
  const _NotificationCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    final radius = BorderRadius.circular(12);

    return Container(
      decoration: BoxDecoration(
        color: c.bgBase,
        borderRadius: radius,
        border: Border.all(color: c.borderBase),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Priority accent bar placeholder
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: c.bgSubtle,
                borderRadius: BorderRadius.only(
                  topLeft: radius.topLeft,
                  bottomLeft: radius.bottomLeft,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ShimmerCircle(size: 36),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const ShimmerText(width: 120, height: 14),
                          const SizedBox(height: 8),
                          const ShimmerText(width: double.infinity, height: 12),
                          const SizedBox(height: 6),
                          const ShimmerText(width: 80, height: 12),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const ShimmerContainer(width: 30, height: 20, borderRadius: 4),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationListSkeleton extends StatelessWidget {
  final int count;
  const _NotificationListSkeleton({this.count = 6});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => const _NotificationCardSkeleton(),
    );
  }
}
