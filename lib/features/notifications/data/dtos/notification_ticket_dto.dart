/// DTOs for POST /mobile/notifications/tickets
/// and POST /notifications/mark-read.
///
/// Field names match the exact Xano API response keys confirmed from
/// the production payload (2026-05-28).
library;

// ─── Single event ────────────────────────────────────────────────────────────

class NotificationTicketEventDto {
  /// Notification event ID — used as the key for mark-read.
  final String id;

  /// Event type key, e.g. "ticket_created", "ticket_overdue".
  final String typeKey;

  /// "emitted_and_unread" | "emitted_and_read"
  final String status;

  /// When the event was emitted — epoch ms.
  final int emittedAt;

  /// Severity 1–5 (higher = more urgent).
  final int finalSeverity;

  /// Convenience bool from the API (derived from status).
  final bool isRead;

  // --- payload fields (may be absent for older/sparse events) ---

  /// Human-readable subtitle, e.g. "Room 8 · Housekeeping".
  final String? displaySecondaryText;

  /// Route hint from payload.target, e.g. "ticket_detail".
  final String? targetRouteHint;

  /// Target entity ID — ticket/order/conversation/guest UUID.
  final String? targetId;

  // --- group / type details ---

  /// Background colour for the icon circle, e.g. "#4D8DFF".
  final String groupHexColor;

  /// Localised type label in English, e.g. "New ticket created".
  final String? typeLabelEn;

  /// Localised type label in Spanish, e.g. "Nuevo ticket creado".
  final String? typeLabelEs;

  /// First name (or full name) of the staff member who read/acknowledged
  /// this notification. Only present on read-tab items.
  final String? readByName;

  /// Epoch ms when this notification was marked as read. Null if unread.
  final int? readAt;

  /// Display name of the user who *created* the underlying ticket, if the
  /// API payload carries it (best-effort across a few likely field paths).
  /// Rendered as the "Created by" line on the card.
  final String? createdByName;

  /// Source channel the ticket came in through (e.g. "WhatsApp", "Guest
  /// app", "Walk-in"). Best-effort parse from a few likely payload paths;
  /// snake_case raw values are humanised at render time.
  final String? source;

  const NotificationTicketEventDto({
    required this.id,
    required this.typeKey,
    required this.status,
    required this.emittedAt,
    required this.finalSeverity,
    required this.isRead,
    this.displaySecondaryText,
    this.targetRouteHint,
    this.targetId,
    required this.groupHexColor,
    this.typeLabelEn,
    this.typeLabelEs,
    this.readByName,
    this.readAt,
    this.createdByName,
    this.source,
  });

  factory NotificationTicketEventDto.fromJson(Map<String, dynamic> json) {
    // --- payload (can be empty map {}) ---
    final payload = json['payload'];
    final payloadMap =
        payload is Map<String, dynamic> ? payload : <String, dynamic>{};

    final target = payloadMap['target'];
    final targetMap =
        target is Map<String, dynamic> ? target : <String, dynamic>{};

    final display = payloadMap['display'];
    final displayMap =
        display is Map<String, dynamic> ? display : <String, dynamic>{};

    final secondaryText = displayMap['secondary_text'] as String?;
    final routeHint = targetMap['route_hint'] as String?;
    // Prefer payload.target.id; fall back to payload.ticket_id / entity_id.
    final targetId = (targetMap['id'] as String?)?.isEmpty == false
        ? targetMap['id'] as String
        : (payloadMap['ticket_id'] as String?)?.isEmpty == false
        ? payloadMap['ticket_id'] as String?
        : payloadMap['entity_id'] as String?;

    // --- _notification_group_details ---
    final group = json['_notification_group_details'];
    final groupMap =
        group is Map<String, dynamic> ? group : <String, dynamic>{};
    final hexColor =
        (groupMap['hexa_color_ui'] as String?)?.trim() ?? '#4D8DFF';

    // --- _notification_type_details ---
    final typeDetails = json['_notification_type_details'];
    final typeMap =
        typeDetails is Map<String, dynamic> ? typeDetails : <String, dynamic>{};
    final labelList = typeMap['label'];
    String? labelEn;
    String? labelEs;
    if (labelList is List) {
      for (final entry in labelList) {
        if (entry is Map<String, dynamic>) {
          final lang = entry['lang'] as String?;
          final name = entry['name'] as String?;
          if (lang == 'en') labelEn = name;
          if (lang == 'es') labelEs = name;
        }
      }
    }

    // --- read-by metadata (present on read-tab items) ---
    // Try several possible field shapes the backend may use.
    final rawReadByName = json['read_by_name'] as String? ??
        json['read_by'] as String? ??
        json['acknowledged_by_name'] as String?;
    final readByNameValue =
        (rawReadByName?.isNotEmpty == true) ? rawReadByName : null;

    final readAtValue = (json['read_at'] as num?)?.toInt() ??
        (json['acknowledged_at'] as num?)?.toInt();

    // --- ticket owner + source ---
    // The backend payload shape isn't formally pinned for these two fields,
    // so we probe a handful of likely paths: `payload.display.*` first
    // (matches the existing `secondary_text` convention), then top-level
    // `payload.*`, then nested objects (`created_by.name`). If none yield
    // a non-empty string the card row degrades gracefully and renders
    // nothing.
    String? stringFrom(Map<String, dynamic> map, List<String> keys) {
      for (final k in keys) {
        final v = map[k];
        if (v is String && v.isNotEmpty) return v;
      }
      return null;
    }

    String? nameFromNested(Map<String, dynamic> map, String key) {
      final nested = map[key];
      if (nested is Map<String, dynamic>) {
        final name = nested['name'] ?? nested['full_name'] ?? nested['display_name'];
        if (name is String && name.isNotEmpty) return name;
      }
      return null;
    }

    final createdByNameValue = stringFrom(displayMap,
            ['created_by_name', 'creator_name']) ??
        stringFrom(payloadMap,
            ['created_by_name', 'creator_name', 'createdByName']) ??
        nameFromNested(payloadMap, 'created_by') ??
        nameFromNested(payloadMap, 'creator');

    final sourceValue = stringFrom(displayMap, ['source', 'source_label']) ??
        stringFrom(payloadMap, ['source', 'ticket_source']);

    return NotificationTicketEventDto(
      id: json['id'] as String,
      typeKey: json['type_key'] as String? ?? '',
      status: json['status'] as String? ?? '',
      emittedAt: (json['emitted_at'] as num?)?.toInt() ?? 0,
      finalSeverity: (json['final_severity'] as num?)?.toInt() ?? 3,
      isRead: json['is_read'] as bool? ?? false,
      displaySecondaryText:
          (secondaryText?.isEmpty == true) ? null : secondaryText,
      targetRouteHint: routeHint,
      targetId: targetId,
      groupHexColor: hexColor,
      typeLabelEn: labelEn,
      typeLabelEs: labelEs,
      readByName: readByNameValue,
      readAt: readAtValue,
      createdByName: createdByNameValue,
      source: sourceValue,
    );
  }
}

// ─── Pagination meta ─────────────────────────────────────────────────────────

class NotificationTicketMetaDto {
  final int limit;
  final int offset;
  final int count;
  final bool hasMore;

  /// Total unread count across ALL pages (not just current page).
  final int unreadCount;

  const NotificationTicketMetaDto({
    required this.limit,
    required this.offset,
    required this.count,
    required this.hasMore,
    required this.unreadCount,
  });

  factory NotificationTicketMetaDto.fromJson(Map<String, dynamic> json) {
    return NotificationTicketMetaDto(
      limit: (json['limit'] as num?)?.toInt() ?? 30,
      offset: (json['offset'] as num?)?.toInt() ?? 0,
      count: (json['count'] as num?)?.toInt() ?? 0,
      hasMore: json['has_more'] as bool? ?? false,
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
    );
  }
}

// ─── Full response ────────────────────────────────────────────────────────────

class NotificationTicketsResponseDto {
  final List<NotificationTicketEventDto> events;
  final NotificationTicketMetaDto meta;

  const NotificationTicketsResponseDto({
    required this.events,
    required this.meta,
  });

  factory NotificationTicketsResponseDto.fromJson(Map<String, dynamic> json) {
    final rawEvents = json['events'];
    final events = rawEvents is List
        ? rawEvents
            .whereType<Map<String, dynamic>>()
            .map(NotificationTicketEventDto.fromJson)
            .toList()
        : <NotificationTicketEventDto>[];

    final rawMeta = json['meta'];
    final meta = rawMeta is Map<String, dynamic>
        ? NotificationTicketMetaDto.fromJson(rawMeta)
        : const NotificationTicketMetaDto(
            limit: 30,
            offset: 0,
            count: 0,
            hasMore: false,
            unreadCount: 0,
          );

    return NotificationTicketsResponseDto(events: events, meta: meta);
  }
}
