import 'package:flutter/material.dart';

import '../../../../../core/i18n/l10n_extension.dart';
import '../../../../../core/theme/unified_theme_manager.dart';
import '../../../../../core/theme/typography_manager.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../../domain/entities/ticket_detail.dart';

/// Activity timeline for a single ticket using API events.
///
/// Visual:
///   ●─┐  Title           [emoji pill]
///     │  timestamp
///     ●  Title           [emoji pill]
///        timestamp
class TicketActivityTimeline extends StatelessWidget {
  final TicketDetail ticket;
  const TicketActivityTimeline({super.key, required this.ticket});

  @override
  Widget build(BuildContext context) {
    // Create events list including ticket creation
    final allEvents = <_TimelineEvent>[];

    // Add ticket created event
    allEvents.add(
      _TimelineEvent(
        createdAt: ticket.createdAt,
        eventType: 'created',
        fromStatus: '',
        toStatus: 'new',
        notes: '',
        eventBy: '',
        firstName: '',
        lastName: '',
        color: '#3B82F6',
        emoji: '🎫',
      ),
    );

    // Add API events
    for (final event in ticket.events) {
      allEvents.add(
        _TimelineEvent(
          createdAt: event.createdAt,
          eventType: event.eventType,
          fromStatus: event.fromStatus,
          toStatus: event.toStatus,
          notes: event.notes,
          eventBy: event.eventBy,
          firstName: event.firstName,
          lastName: event.lastName,
          color: event.color,
          emoji: event.emoji,
        ),
      );
    }

    // Sort in descending order by createdAt
    allEvents.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (allEvents.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No activity yet',
            style: TypographyManager.textBody.copyWith(
              color: context.themeColors.fgMuted,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < allEvents.length; i++)
          _TimelineRow(event: allEvents[i], isLast: i == allEvents.length - 1),
      ],
    );
  }
}

class _TimelineEvent {
  final int createdAt;
  final String eventType;
  final String fromStatus;
  final String toStatus;
  final String notes;
  final String eventBy;
  final String firstName;
  final String lastName;
  final String color;
  final String emoji;

  const _TimelineEvent({
    required this.createdAt,
    required this.eventType,
    required this.fromStatus,
    required this.toStatus,
    required this.notes,
    required this.eventBy,
    required this.firstName,
    required this.lastName,
    required this.color,
    required this.emoji,
  });
}

class _TimelineRow extends StatelessWidget {
  final _TimelineEvent event;
  final bool isLast;
  const _TimelineRow({required this.event, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    final s = context.l10n;
    final bgColor = _parseColor(event.color, c);

    // Build title based on event type
    final title = _buildTitle(s, event);

    // Build pill label (emoji + event type or status change)
    final pillLabel = _buildPillLabel(event);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: bgColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(event.emoji, style: const TextStyle(fontSize: 16)),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: c.borderBase,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: TypographyManager.textBodyStrong.copyWith(
                            color: c.fgBase,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: bgColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          pillLabel,
                          style: TypographyManager.textMicro.copyWith(
                            color: bgColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTimestamp(event.createdAt),
                    style: TypographyManager.textMeta.copyWith(
                      color: c.fgMuted,
                    ),
                  ),
                  if (event.notes.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      event.notes,
                      style: TypographyManager.textBody.copyWith(
                        color: c.fgMuted,
                      ),
                    ),
                  ],
                  if (event.firstName.isNotEmpty ||
                      event.lastName.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${event.firstName} ${event.lastName}'.trim(),
                      style: TypographyManager.textMeta.copyWith(
                        color: c.fgMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _buildTitle(AppLocalizations s, _TimelineEvent event) {
    if (event.eventType == 'created') {
      return s.ticketActivityCreated;
    }

    if (event.fromStatus.isNotEmpty && event.toStatus.isNotEmpty) {
      return '${_capitalize(event.fromStatus)} → ${_capitalize(event.toStatus)}';
    }

    return _capitalize(event.eventType);
  }

  String _buildPillLabel(_TimelineEvent event) {
    if (event.eventType == 'created') {
      return 'Created';
    }

    if (event.eventType.isNotEmpty) {
      return _capitalize(event.eventType);
    }

    if (event.toStatus.isNotEmpty) {
      return _capitalize(event.toStatus);
    }

    return '';
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  Color _parseColor(String hexColor, AppColors c) {
    try {
      final hex = hexColor.replaceAll('#', '');
      if (hex.length == 6) {
        final r = int.parse(hex.substring(0, 2), radix: 16);
        final g = int.parse(hex.substring(2, 4), radix: 16);
        final b = int.parse(hex.substring(4, 6), radix: 16);
        return Color.fromARGB(255, r, g, b);
      }
    } catch (_) {}
    return c.tagBlueIcon;
  }

  String _formatTimestamp(int timestamp) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour24 = dt.hour;
    final isPm = hour24 >= 12;
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = isPm ? 'PM' : 'AM';
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}, $hour12:$minute $ampm';
  }
}
