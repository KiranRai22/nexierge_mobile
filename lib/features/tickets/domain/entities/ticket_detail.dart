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
    return TicketDetail(
      id: ticket['id'] as String,
      createdAt: ticket['created_at'] as int,
      hotelId: ticket['hotel_id'] as String,
      departmentId: ticket['department_id'] as String,
      assignedToUserId: ticket['assigned_to_user_id'] as String?,
      createdByAi: ticket['created_by_ai'] as bool,
      type: ticket['type'] as String,
      status: ticket['status'] as String,
      category: ticket['category'] as String,
      priority: ticket['priority'] as String,
      issueSummary: ticket['issue_summary'] as String,
      issueDetails: ticket['issue_details'] as String,
      isIncident: ticket['is_incident'] as bool,
      incidentNotes: ticket['incident_notes'] as String,
      room: ticket['room'] as String,
      guestName: ticket['guest_name'] as String,
      acknowledgedByUserId: ticket['acknowledged_by_user_id'] as String?,
      acknowledgedAt: ticket['acknowledged_at'] as int,
      resolutionCode: ticket['resolution_code'] as String,
      resolutionNotes: ticket['resolution_notes'] as String,
      source: ticket['source'] as String,
      onbRoomNumber: ticket['onb_room_number'] as String,
      mobileIcon: ticket['mobile_icon'] as String,
      createdTime: ticket['created_time'] as String,
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
    return TicketEvent(
      createdAt: json['created_at'] as int,
      eventType: json['event_type'] as String,
      fromStatus: json['from_status'] as String,
      toStatus: json['to_status'] as String,
      notes: json['notes'] as String,
      eventBy: json['event_by'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      color: json['color'] as String,
      emoji: json['emoji'] as String,
    );
  }
}
