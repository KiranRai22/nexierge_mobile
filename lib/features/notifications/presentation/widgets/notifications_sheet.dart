import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/services/sound_manager.dart';
import '../../../../core/theme/card_theme.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/typography_manager.dart';
import '../../../../core/widgets/shimmer_widget.dart';
import '../../domain/entities/notification_inbox_item.dart';
import '../providers/notification_inbox_controller.dart';
import '../providers/swipe_coach_provider.dart';
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

  /// Called when the user taps the "Open Tickets" footer button on the
  /// Unread tab. When null, the footer button is hidden.
  final VoidCallback? onOpenAllTickets;

  const NotificationsSheet({
    super.key,
    this.onOpenTicket,
    this.onOpenAllTickets,
  });

  static Future<void> show(
    BuildContext context, {
    ValueChanged<String>? onOpenTicket,
    VoidCallback? onOpenAllTickets,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: context.appColors.scrimBlack.withValues(alpha: 0.4),
      builder: (_) => NotificationsSheet(
        onOpenTicket: onOpenTicket,
        onOpenAllTickets: onOpenAllTickets,
      ),
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
              // Always render the footer — its own build decides whether to
              // show itself (only on the Unread tab, and only when there
              // are unread items to act on).
              _OpenTicketsFooter(onPressed: onOpenAllTickets),
            ],
          ),
        );
      },
    );
  }
}

// ─── Footer ───────────────────────────────────────────────────────────────────

class _OpenTicketsFooter extends ConsumerWidget {
  /// When null, tapping the button just dismisses the sheet — used so the
  /// footer's visibility no longer depends on whether the caller passed a
  /// navigation hook.
  final VoidCallback? onPressed;

  const _OpenTicketsFooter({required this.onPressed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.l10n;
    final c = context.themeColors;
    final state = ref.watch(notificationInboxControllerProvider);

    // Visibility rules:
    //   - Only on the Unread tab (Open Tickets is a per-ticket action).
    //   - Only when there are unread items to act on; an empty list means
    //     there's nothing to open.
    if (state.statusFilter != 'unread') return const SizedBox.shrink();
    if (state.items.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: c.bgBase,
        border: Border(top: BorderSide(color: c.borderBase, width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 40,
          child: ElevatedButton.icon(
            onPressed: tapSound(() {
              Navigator.of(context).pop();
              onPressed?.call();
            }, SoundCategory.button),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 245, 175, 23),
              foregroundColor: context.appColors.fgOnBrand,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(LucideIcons.ticket, size: 16),
            label: Text(
              s.notificationsOpenTickets,
              style: TypographyManager.textLabel.copyWith(
                color: context.appColors.fgOnBrand,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
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

  const _Body({required this.scrollController, required this.onOpenTicket});

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

    // Show the swipe-coach banner once per device, only on the unread tab
    // (the only tab where swipe actions exist).
    final showCoach =
        state.statusFilter == 'unread' &&
        !ref.watch(swipeCoachDismissedProvider);
    final leadingCount = showCoach ? 1 : 0;

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(notificationInboxControllerProvider.notifier).refresh(),
      child: ListView.separated(
        controller: widget.scrollController,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount:
            leadingCount + state.items.length + (state.isLoadingMore ? 10 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, index) {
          if (showCoach && index == 0) {
            return _SwipeCoachBanner(
              onDismiss: () =>
                  ref.read(swipeCoachDismissedProvider.notifier).dismiss(),
            );
          }

          final itemIndex = index - leadingCount;

          // Load-more skeletons at bottom — one per incoming item slot
          if (itemIndex >= state.items.length) {
            return const _NotificationCardSkeleton();
          }

          final item = state.items[itemIndex];
          final card = NotificationCard(
            item: item,
            onTap: () => _onItemTap(item),
          );

          // Swipe actions only apply to unread items.
          if (!item.unread) return card;

          return _SwipeableNotification(
            key: ValueKey('notif-${item.id}'),
            item: item,
            onMarkRead: () => _onMarkRead(item),
            onView: () => _onView(item),
            child: card,
          );
        },
      ),
    );
  }

  void _onItemTap(NotificationInboxItem item) {
    // Tap is intentionally a no-op for unread items — swipe right to view,
    // swipe left to mark as read. Read-tab items keep the open-ticket
    // behavior so users can still jump to a ticket they've already seen.
    if (item.unread) return;

    final ticketId = item.ticketId;
    if (ticketId != null && ticketId.isNotEmpty) {
      Navigator.of(context).pop();
      widget.onOpenTicket?.call(ticketId);
    }
  }

  void _onMarkRead(NotificationInboxItem item) {
    ref.read(notificationInboxControllerProvider.notifier).markRead(item.id);
  }

  void _onView(NotificationInboxItem item) {
    ref.read(notificationInboxControllerProvider.notifier).markRead(item.id);
    final ticketId = item.ticketId;
    if (ticketId == null || ticketId.isEmpty) return;
    Navigator.of(context).pop();
    widget.onOpenTicket?.call(ticketId);
  }
}

// ─── Swipeable notification row ──────────────────────────────────────────────

class _SwipeableNotification extends StatelessWidget {
  final NotificationInboxItem item;
  final VoidCallback onMarkRead;
  final VoidCallback onView;
  final Widget child;

  const _SwipeableNotification({
    super.key,
    required this.item,
    required this.onMarkRead,
    required this.onView,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final c = context.themeColors;
    final radius = BorderRadius.circular(12);

    return ClipRRect(
      borderRadius: radius,
      child: Dismissible(
        key: ValueKey('dismiss-${item.id}'),
        background: _SwipeBackground(
          bgColor: c.tagGreenBg,
          fgColor: c.tagGreenText,
          icon: LucideIcons.eye,
          label: s.notificationsActionView,
          alignment: Alignment.centerLeft,
          radius: radius,
        ),
        secondaryBackground: _SwipeBackground(
          bgColor: c.tagBlueBg,
          fgColor: c.tagBlueText,
          icon: LucideIcons.checkCheck,
          label: s.notificationsActionRead,
          alignment: Alignment.centerRight,
          radius: radius,
        ),
        dismissThresholds: const {
          DismissDirection.startToEnd: 0.3,
          DismissDirection.endToStart: 0.3,
        },
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            onView();
          } else if (direction == DismissDirection.endToStart) {
            onMarkRead();
          }
          // Returning false snaps the row back into place — the action has
          // already been fired and the list will update on its own.
          return false;
        },
        child: child,
      ),
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  final Color bgColor;
  final Color fgColor;
  final IconData icon;
  final String label;
  final Alignment alignment;
  final BorderRadius radius;

  const _SwipeBackground({
    required this.bgColor,
    required this.fgColor,
    required this.icon,
    required this.label,
    required this.alignment,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: bgColor, borderRadius: radius),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: fgColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: TypographyManager.textLabel.copyWith(
              color: fgColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
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
          TextButton(onPressed: onRetry, child: Text(s.notificationsRetry)),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
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
                    const ShimmerContainer(
                      width: 30,
                      height: 20,
                      borderRadius: 4,
                    ),
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

// ─── Swipe coach banner ──────────────────────────────────────────────────────

/// One-time coach card shown at the top of the unread list teaching the user
/// about swipe actions. Persists dismissal via [swipeCoachDismissedProvider].
class _SwipeCoachBanner extends StatefulWidget {
  final VoidCallback onDismiss;

  const _SwipeCoachBanner({required this.onDismiss});

  @override
  State<_SwipeCoachBanner> createState() => _SwipeCoachBannerState();
}

class _SwipeCoachBannerState extends State<_SwipeCoachBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _swipe; // -1 (left) .. 0 (rest) .. 1 (right)

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();

    // Two-phase loop: right swipe (View) then left swipe (Read), with rests.
    _swipe = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 0.0),
        weight: 10, // rest
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 20, // swipe right
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.0),
        weight: 10, // hold right
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 10, // snap back
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 0.0),
        weight: 10, // rest
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: -1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 20, // swipe left
      ),
      TweenSequenceItem(
        tween: Tween(begin: -1.0, end: -1.0),
        weight: 10, // hold left
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: -1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 10, // snap back
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final c = context.themeColors;
    final radius = BorderRadius.circular(12);

    return Container(
      decoration: BoxDecoration(
        color: c.bgSubtle,
        borderRadius: radius,
        border: Border.all(color: c.borderBase),
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.notificationsCoachTitle,
            style: TypographyManager.textBodyStrong.copyWith(color: c.fgBase),
          ),
          const SizedBox(height: 10),
          _SwipeCoachDemo(animation: _swipe),
          const SizedBox(height: 10),
          _CoachHint(
            icon: LucideIcons.arrowRight,
            text: s.notificationsCoachSwipeRight,
            color: c.tagGreenText,
          ),
          const SizedBox(height: 4),
          _CoachHint(
            icon: LucideIcons.arrowLeft,
            text: s.notificationsCoachSwipeLeft,
            color: c.tagBlueText,
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              height: 32,
              child: ElevatedButton(
                onPressed: tapSound(widget.onDismiss, SoundCategory.button),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.appColors.fgWarning,
                  foregroundColor: context.appColors.fgOnBrand,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  s.notificationsCoachGotIt,
                  style: TypographyManager.textLabel.copyWith(
                    color: context.appColors.fgOnBrand,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoachHint extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _CoachHint({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TypographyManager.textMeta.copyWith(color: c.fgMuted),
          ),
        ),
      ],
    );
  }
}

/// The animated demo strip: a mock notification "card" that slides L/R
/// revealing the colored View / Mark-as-read backgrounds underneath.
class _SwipeCoachDemo extends StatelessWidget {
  final Animation<double> animation;

  const _SwipeCoachDemo({required this.animation});

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    final s = context.l10n;
    final radius = BorderRadius.circular(10);
    const stripHeight = 52.0;

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        height: stripHeight,
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            final v = animation.value;
            final showRight = v > 0;
            final bgColor = showRight ? c.tagGreenBg : c.tagBlueBg;
            final fgColor = showRight ? c.tagGreenText : c.tagBlueText;
            final icon = showRight ? LucideIcons.eye : LucideIcons.checkCheck;
            final label = showRight
                ? s.notificationsActionView
                : s.notificationsActionRead;

            return Stack(
              children: [
                // Background slot (revealed by the sliding card).
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(color: bgColor),
                    alignment: showRight
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Opacity(
                      opacity: v.abs().clamp(0.0, 1.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 16, color: fgColor),
                          const SizedBox(width: 6),
                          Text(
                            label,
                            style: TypographyManager.textLabel.copyWith(
                              color: fgColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Sliding mock card on top.
                Transform.translate(
                  offset: Offset(v * 90, 0),
                  child: _MockNotificationRow(radius: radius),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MockNotificationRow extends StatelessWidget {
  final BorderRadius radius;

  const _MockNotificationRow({required this.radius});

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    return Container(
      decoration: BoxDecoration(
        color: c.bgBase,
        borderRadius: radius,
        border: Border.all(color: c.borderBase),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: c.tagPurpleBg,
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.bell, size: 14, color: c.tagPurpleText),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 8,
                  width: 110,
                  decoration: BoxDecoration(
                    color: c.bgSubtle,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 6,
                  width: 70,
                  decoration: BoxDecoration(
                    color: c.bgSubtle,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
