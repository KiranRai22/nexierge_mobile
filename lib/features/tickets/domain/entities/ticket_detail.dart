/// Ticket detail from tickets/details API.
class TicketDetail {
  final String id;
  final int createdAt;
  final String hotelId;
  final String departmentId;
  final String? assignedToUserId;
  final bool createdByAi;
  final String type;
  final String status;
  final String category;
  final String priority;
  final String issueSummary;
  final String issueDetails;
  final bool isIncident;
  final String incidentNotes;
  final String room;
  final String guestName;
  final String? acknowledgedByUserId;
  final int acknowledgedAt;
  final String resolutionCode;
  final String resolutionNotes;
  final String source;
  final String onbRoomNumber;
  final String mobileIcon;
  final String createdTime;
  final List<TicketEvent> events;

  const TicketDetail({
    required this.id,
    required this.createdAt,
    required this.hotelId,
    required this.departmentId,
    this.assignedToUserId,
    required this.createdByAi,
    required this.type,
    required this.status,
    required this.category,
    required this.priority,
    required this.issueSummary,
    required this.issueDetails,
    required this.isIncident,
    required this.incidentNotes,
    required this.room,
    required this.guestName,
    this.acknowledgedByUserId,
    required this.acknowledgedAt,
    required this.resolutionCode,
    required this.resolutionNotes,
    required this.source,
    required this.onbRoomNumber,
    required this.mobileIcon,
    required this.createdTime,
    required this.events,
  });

  factory TicketDetail.fromJson(Map<String, dynamic> json) {
    final ticket = json['ticket'] as Map<String, dynamic>;
    final eventsList = json['events'] as List? ?? [];
    String s(String key) => (ticket[key] as String?) ?? '';
    int i(String key) => (ticket[key] as num?)?.toInt() ?? 0;
    bool b(String key) => (ticket[key] as bool?) ?? false;
    return TicketDetail(
      id: s('id'),
      createdAt: i('created_at'),
      hotelId: s('hotel_id'),
      departmentId: s('department_id'),
      assignedToUserId: ticket['assigned_to_user_id'] as String?,
      createdByAi: b('created_by_ai'),
      type: s('type'),
      status: s('status'),
      category: s('category'),
      priority: s('priority'),
      issueSummary: s('issue_summary'),
      issueDetails: s('issue_details'),
      isIncident: b('is_incident'),
      incidentNotes: s('incident_notes'),
      room: s('room'),
      guestName: s('guest_name'),
      acknowledgedByUserId: ticket['acknowledged_by_user_id'] as String?,
      acknowledgedAt: i('acknowledged_at'),
      resolutionCode: s('resolution_code'),
      resolutionNotes: s('resolution_notes'),
      source: s('source'),
      onbRoomNumber: s('onb_room_number'),
      mobileIcon: s('mobile_icon'),
      createdTime: s('created_time'),
      events: eventsList
          .map((e) => TicketEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class TicketEvent {
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

  const TicketEvent({
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

  factory TicketEvent.fromJson(Map<String, dynamic> json) {
    String s(String key) => (json[key] as String?) ?? '';
    return TicketEvent(
      createdAt: (json['created_at'] as num?)?.toInt() ?? 0,
      eventType: s('event_type'),
      fromStatus: s('from_status'),
      toStatus: s('to_status'),
      notes: s('notes'),
      eventBy: s('event_by'),
      firstName: s('first_name'),
      lastName: s('last_name'),
      color: s('color'),
      emoji: s('emoji'),
    );
  }
}
