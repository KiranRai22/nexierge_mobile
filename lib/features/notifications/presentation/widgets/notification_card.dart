import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/services/sound_manager.dart';
import '../../../../core/theme/card_theme.dart';
import '../../../../core/theme/unified_theme_manager.dart';
import '../../../../core/theme/typography_manager.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../tickets/presentation/providers/my_tickets_list_controller.dart';
import '../../domain/entities/notification_inbox_item.dart';

/// One inbox row.
///
/// Layout: `[priority accent] [icon circle] [title / subtitle] [time + unread dot]`
///
/// Read-tab cards additionally show who acknowledged the linked ticket
/// (resolved from the cached ticket's assigneeName).
class NotificationCard extends ConsumerWidget {
  final NotificationInboxItem item;
  final VoidCallback onTap;

  const NotificationCard({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.themeColors;
    final radius = BorderRadius.circular(12);

    // For Read-tab cards that link to a ticket, look up the assignee name
    // from the cached ticket (populated from the API's `_user` block).
    String? readByName;
    if (!item.unread && item.ticketId != null) {
      final ticket = ref.watch(cachedTicketByIdProvider(item.ticketId!));
      final name = ticket?.assigneeName;
      if (name != null && name.isNotEmpty) {
        readByName = name.split(' ').first;
      }
    }

    return Material(
      color: item.unread ? c.bgBase : c.bgSubtle,
      borderRadius: radius,
      child: InkWell(
        onTap: tapSound(onTap, SoundCategory.card),
        borderRadius: radius,
        child: Container(
          decoration: CardDecoration.subtle(colors: c, borderRadius: radius),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Priority left-border accent
                _PriorityAccent(priority: item.priority, radius: radius),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _LeadingIcon(item: item),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _Body(item: item, c: c, readByName: readByName),
                        ),
                        const SizedBox(width: 8),
                        _Trailing(item: item, c: c, s: context.l10n),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Priority accent bar ──────────────────────────────────────────────────────

class _PriorityAccent extends StatelessWidget {
  final NotificationPriority priority;
  final BorderRadius radius;

  const _PriorityAccent({required this.priority, required this.radius});

  @override
  Widget build(BuildContext context) {
    final color = switch (priority) {
      NotificationPriority.urgent => const Color(0xFFE53935),        // red
      NotificationPriority.actionRequired => const Color(0xFFFB8C00), // amber
      NotificationPriority.informational => Colors.transparent,
    };

    if (color == Colors.transparent) return const SizedBox(width: 4);

    return Container(
      width: 4,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.only(
          topLeft: radius.topLeft,
          bottomLeft: radius.bottomLeft,
        ),
      ),
    );
  }
}

// ─── Leading icon ─────────────────────────────────────────────────────────────

class _LeadingIcon extends StatelessWidget {
  final NotificationInboxItem item;

  const _LeadingIcon({required this.item});

  IconData _iconForKind(NotificationInboxKind kind) {
    return switch (kind) {
      NotificationInboxKind.newTicket => LucideIcons.ticket,
      NotificationInboxKind.ticketAssigned => LucideIcons.userCheck,
      NotificationInboxKind.ticketOverdue => LucideIcons.clock,
      NotificationInboxKind.ticketEscalated => LucideIcons.alertTriangle,
      NotificationInboxKind.ticketCompleted => LucideIcons.checkCircle2,
      NotificationInboxKind.other => LucideIcons.bell,
    };
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = item.parsedGroupColor.withValues(alpha: 0.15);
    final iconColor = item.parsedGroupColor;

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
      child: Icon(_iconForKind(item.kind), size: 18, color: iconColor),
    );
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  final NotificationInboxItem item;
  final AppColors c;
  final String? readByName;

  const _Body({required this.item, required this.c, this.readByName});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          item.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TypographyManager.textBodyStrong.copyWith(
            color: item.unread ? c.fgBase : c.fgMuted,
          ),
        ),
        if (item.subtitle.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            item.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TypographyManager.textMeta.copyWith(color: c.fgMuted),
          ),
        ],
        if (readByName != null) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.eye, size: 11, color: c.fgSubtle),
              const SizedBox(width: 3),
              Text(
                readByName!,
                style: TypographyManager.textCaption.copyWith(color: c.fgSubtle),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ─── Trailing ─────────────────────────────────────────────────────────────────

class _Trailing extends StatelessWidget {
  final NotificationInboxItem item;
  final AppColors c;
  final AppLocalizations s;

  const _Trailing({required this.item, required this.c, required this.s});

  String _relative(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return s.relativeJustNow;
    if (diff.inMinutes < 60) return s.relativeMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return s.relativeHoursAgo(diff.inHours);
    return s.relativeDaysAgo(diff.inDays);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _relative(item.receivedAt),
          style: TypographyManager.textCaption.copyWith(color: c.fgMuted),
        ),
        if (item.unread) ...[
          const SizedBox(height: 4),
          SizedBox(
            width: 8,
            height: 8,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: item.parsedGroupColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
