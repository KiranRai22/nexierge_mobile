import 'package:flutter/material.dart';

import '../../data/dtos/notification_ticket_dto.dart';

// ─── Kind ────────────────────────────────────────────────────────────────────

/// Operational event kinds. Drives icon selection on the card.
/// Maps 1-to-1 from API `type_key`.
enum NotificationInboxKind {
  newTicket,        // ticket_created
  ticketAssigned,   // ticket_assigned
  ticketOverdue,    // ticket_overdue
  ticketEscalated,  // ticket_escalated
  ticketCompleted,  // ticket_completed
  other,            // any future/unknown type_key
}

NotificationInboxKind _kindFromTypeKey(String typeKey) {
  switch (typeKey) {
    case 'ticket_created':
      return NotificationInboxKind.newTicket;
    case 'ticket_assigned':
      return NotificationInboxKind.ticketAssigned;
    case 'ticket_overdue':
      return NotificationInboxKind.ticketOverdue;
    case 'ticket_escalated':
      return NotificationInboxKind.ticketEscalated;
    case 'ticket_completed':
      return NotificationInboxKind.ticketCompleted;
    default:
      return NotificationInboxKind.other;
  }
}

// ─── Priority ─────────────────────────────────────────────────────────────────

/// Visual urgency treatment for the card.
enum NotificationPriority {
  informational,  // final_severity 1–2
  actionRequired, // final_severity 3–4
  urgent,         // final_severity 5
}

NotificationPriority _priorityFromSeverity(int severity) {
  if (severity >= 5) return NotificationPriority.urgent;
  if (severity >= 3) return NotificationPriority.actionRequired;
  return NotificationPriority.informational;
}

// ─── Entity ───────────────────────────────────────────────────────────────────

/// Single row inside the notifications bottom sheet.
///
/// Created either from the Xano REST API response (via [fromDto]) or by
/// applying a realtime mark-read event (via [copyWith]).
class NotificationInboxItem {
  final String id;
  final NotificationInboxKind kind;
  final NotificationPriority priority;

  /// Localised title sourced from the server's `_notification_type_details.label`.
  /// Falls back to the fallback string if the server doesn't send one.
  final String title;

  /// Free-form subtitle, e.g. "Room 8 · Housekeeping".
  final String subtitle;

  /// When the event was emitted. Used to compute the relative timestamp.
  final DateTime receivedAt;

  /// Whether this user has not yet read this notification.
  final bool unread;

  /// Hex colour for the icon background circle, e.g. "#4D8DFF".
  final String groupHexColor;

  /// Optional ticket ID for deep-linking into ticket detail.
  final String? ticketId;

  /// Route hint from the API payload, e.g. "ticket_detail".
  final String? routeHint;

  /// Name of the staff member who read this notification (read tab only).
  final String? readByName;

  /// When this notification was marked as read (epoch ms). Null if unread.
  final DateTime? readAt;

  const NotificationInboxItem({
    required this.id,
    required this.kind,
    required this.priority,
    required this.title,
    required this.subtitle,
    required this.receivedAt,
    required this.unread,
    required this.groupHexColor,
    this.ticketId,
    this.routeHint,
    this.readByName,
    this.readAt,
  });

  // ── Factory: build from Xano DTO ──────────────────────────────────────────

  /// Converts an API event DTO into a UI-ready inbox item.
  ///
  /// [languageCode] is used to pick the right server-localised label ('en'/'es').
  /// Defaults to 'en'.
  factory NotificationInboxItem.fromDto(
    NotificationTicketEventDto dto, {
    String languageCode = 'en',
  }) {
    final title = (languageCode == 'es' ? dto.typeLabelEs : dto.typeLabelEn) ??
        dto.typeLabelEn ??
        dto.typeKey;

    return NotificationInboxItem(
      id: dto.id,
      kind: _kindFromTypeKey(dto.typeKey),
      priority: _priorityFromSeverity(dto.finalSeverity),
      title: title,
      subtitle: dto.displaySecondaryText ?? '',
      receivedAt: DateTime.fromMillisecondsSinceEpoch(dto.emittedAt),
      unread: !dto.isRead,
      groupHexColor: dto.groupHexColor,
      ticketId: dto.targetRouteHint == 'ticket_detail' ? dto.targetId : null,
      routeHint: dto.targetRouteHint,
      readByName: dto.readByName,
      readAt: dto.readAt != null
          ? DateTime.fromMillisecondsSinceEpoch(dto.readAt!)
          : null,
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Parse [groupHexColor] into a Flutter [Color]. Returns [fallback] if
  /// the hex string is invalid. Callers should pass a theme-derived color
  /// (e.g. `context.appColors.fgInfo`) so the fallback flips with the theme.
  Color parsedGroupColor(Color fallback) {
    try {
      final hex = groupHexColor.replaceAll('#', '');
      final value = int.parse(hex, radix: 16);
      return Color(0xFF000000 | value);
    } catch (_) {
      return fallback;
    }
  }

  NotificationInboxItem copyWith({bool? unread}) {
    return NotificationInboxItem(
      id: id,
      kind: kind,
      priority: priority,
      title: title,
      subtitle: subtitle,
      receivedAt: receivedAt,
      unread: unread ?? this.unread,
      groupHexColor: groupHexColor,
      ticketId: ticketId,
      routeHint: routeHint,
      readByName: readByName,
      readAt: readAt,
    );
  }
}
