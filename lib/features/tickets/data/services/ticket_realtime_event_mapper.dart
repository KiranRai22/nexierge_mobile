import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../domain/entities/my_ticket.dart';
import '../datasources/ticket_remote_data_source.dart';

/// Realtime event coming off the Xano `liveTickets/{hotelId}` channel.
@immutable
sealed class TicketRealtimeEvent {
  const TicketRealtimeEvent();
}

class TicketUpsertEvent extends TicketRealtimeEvent {
  final MyTicket ticket;
  const TicketUpsertEvent(this.ticket);
}

class TicketDeleteEvent extends TicketRealtimeEvent {
  final String ticketId;
  const TicketDeleteEvent(this.ticketId);
}

/// Parses a single WS frame into a [TicketRealtimeEvent], or returns null
/// if the frame is unrelated (channel-join ack, presence, heartbeat, etc.).
///
/// Tolerant by design: Xano envelopes vary across deployments, so the
/// mapper accepts the row at any of `payload`/`data`/root, and recognises
/// `insert`/`update`/`delete` actions case-insensitively.
TicketRealtimeEvent? parseTicketRealtimeEvent(dynamic raw) {
  final decoded = _decode(raw);
  if (decoded == null) return null;

  final action = (decoded['action'] ?? decoded['type'] ?? decoded['event'])
      ?.toString()
      .toLowerCase();

  // Find the row body wherever Xano put it.
  final body = _firstMap(decoded['payload']) ??
      _firstMap(decoded['data']) ??
      _firstMap(decoded['record']) ??
      _firstMap(decoded);

  // Delete action can ship just an id (no full row).
  if (action == 'delete' || action == 'remove') {
    final id = _id(body) ?? _id(decoded);
    if (id == null || id.isEmpty) return null;
    return TicketDeleteEvent(id);
  }

  // Upsert path requires a row with an id.
  if (body == null) return null;
  final id = _id(body);
  if (id == null || id.isEmpty) return null;

  try {
    final dto = MyTicketDto.fromJson(body);
    return TicketUpsertEvent(_dtoToDomain(dto));
  } catch (e) {
    debugPrint('[TicketRealtimeEvent] parse failed: $e');
    return null;
  }
}

Map<String, dynamic>? _decode(dynamic raw) {
  if (raw == null) return null;
  if (raw is Map<String, dynamic>) return raw;
  if (raw is String) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {
      return null;
    }
  }
  return null;
}

Map<String, dynamic>? _firstMap(dynamic v) {
  if (v is Map<String, dynamic>) return v;
  if (v is List && v.isNotEmpty && v.first is Map<String, dynamic>) {
    return v.first as Map<String, dynamic>;
  }
  return null;
}

String? _id(Map<String, dynamic>? m) {
  if (m == null) return null;
  final v = m['id'] ?? m['ticket_id'] ?? m['ticketId'];
  if (v == null) return null;
  return v.toString();
}

MyTicket _dtoToDomain(MyTicketDto dto) {
  return MyTicket(
    id: dto.id,
    createdAt: dto.createdAt,
    hotelId: dto.hotelId,
    departmentId: dto.departmentId,
    assignedToUserId: dto.assignedToUserId,
    createdByUserId: dto.createdByUserId,
    createdByAi: dto.createdByAi,
    type: dto.type,
    status: dto.status,
    dueAt: dto.dueAt,
    category: dto.category,
    priority: dto.priority,
    issueSummary: dto.issueSummary,
    issueDetails: dto.issueDetails,
    isIncident: dto.isIncident,
    incidentNotes: dto.incidentNotes,
    room: dto.room,
    guestName: dto.guestName,
    acknowledgedByUserId: dto.acknowledgedByUserId,
    acknowledgedAt: dto.acknowledgedAt,
    resolutionCode: dto.resolutionCode,
    resolutionNotes: dto.resolutionNotes,
    confirmedAt: dto.confirmedAt,
    closedAt: dto.closedAt,
    roomDetails: dto.roomDetails != null
        ? RoomDetails(
            id: (dto.roomDetails!['id'] as String?) ?? '',
            onbRoomNumber:
                (dto.roomDetails!['onb_room_number'] as String?) ?? '',
            floorId: (dto.roomDetails!['floor_id'] as String?) ?? '',
            onbRoomTypeId:
                (dto.roomDetails!['onb_room_type_id'] as String?) ?? '',
          )
        : null,
  );
}
