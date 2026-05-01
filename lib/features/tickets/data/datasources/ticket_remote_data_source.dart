import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_client.dart';

abstract class TicketRemoteDataSource {
  Future<TicketDetailDto> getTicketDetails({required String ticketId});
  Future<List<MyTicketDto>> getMyTickets({required String hotelId});
}

class _TicketRemoteDataSourceImpl implements TicketRemoteDataSource {
  final Dio _dio;
  _TicketRemoteDataSourceImpl(this._dio);

  @override
  Future<TicketDetailDto> getTicketDetails({required String ticketId}) async {
    final res = await _dio.post(
      APIEndpoints.ticketsDetails,
      data: {'ticket_id': ticketId},
    );
    return TicketDetailDto.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<List<MyTicketDto>> getMyTickets({required String hotelId}) async {
    // ignore: avoid_print
    print('[TicketRemoteDataSource] Fetching tickets for hotel: $hotelId');
    // ignore: avoid_print
    print(
      '[TicketRemoteDataSource] Endpoint: ${APIEndpoints.ticketsGetMyTickets}',
    );
    final res = await _dio.get(
      APIEndpoints.ticketsGetMyTickets,
      queryParameters: {'hotel_id': hotelId},
    );
    // ignore: avoid_print
    print('[TicketRemoteDataSource] Response status: ${res.statusCode}');
    // ignore: avoid_print
    print(
      '[TicketRemoteDataSource] Response data type: ${res.data.runtimeType}',
    );
    final list = res.data as List<dynamic>;
    // ignore: avoid_print
    print('[TicketRemoteDataSource] Parsed ${list.length} tickets');
    return list
        .map((e) => MyTicketDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final ticketRemoteDataSourceProvider = Provider<TicketRemoteDataSource>((ref) {
  final dio = ref.watch(authedDioProvider);
  return _TicketRemoteDataSourceImpl(dio);
});

class TicketDetailDto {
  final Map<String, dynamic> ticket;
  final List<dynamic> events;

  TicketDetailDto({required this.ticket, required this.events});

  factory TicketDetailDto.fromJson(Map<String, dynamic> json) {
    return TicketDetailDto(
      ticket: json['ticket'] as Map<String, dynamic>,
      events: json['events'] as List,
    );
  }
}

/// DTO for my_tickets API response.
class MyTicketDto {
  final String id;
  final int createdAt;
  final String hotelId;
  final String departmentId;
  final String? assignedToUserId;
  final String createdByUserId;
  final bool createdByAi;
  final String type;
  final String status;
  final int dueAt;
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
  final int confirmedAt;
  final String? closedAt;
  final Map<String, dynamic>? roomDetails;

  MyTicketDto({
    required this.id,
    required this.createdAt,
    required this.hotelId,
    required this.departmentId,
    this.assignedToUserId,
    required this.createdByUserId,
    required this.createdByAi,
    required this.type,
    required this.status,
    required this.dueAt,
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
    required this.confirmedAt,
    this.closedAt,
    this.roomDetails,
  });

  factory MyTicketDto.fromJson(Map<String, dynamic> json) {
    return MyTicketDto(
      id: json['id'] as String,
      createdAt: json['created_at'] as int,
      hotelId: json['hotel_id'] as String,
      departmentId: json['department_id'] as String,
      assignedToUserId: json['assigned_to_user_id'] as String?,
      createdByUserId: json['created_by_user_id'] as String,
      createdByAi: json['created_by_ai'] as bool,
      type: json['type'] as String,
      status: json['status'] as String,
      dueAt: json['due_at'] as int,
      category: json['category'] as String,
      priority: json['priority'] as String,
      issueSummary: json['issue_summary'] as String,
      issueDetails: json['issue_details'] as String,
      isIncident: json['is_incident'] as bool,
      incidentNotes: json['incident_notes'] as String,
      room: json['room'] as String,
      guestName: json['guest_name'] as String,
      acknowledgedByUserId: json['acknowledged_by_user_id'] as String?,
      acknowledgedAt: json['acknowledged_at'] as int,
      resolutionCode: json['resolution_code'] as String,
      resolutionNotes: json['resolution_notes'] as String,
      confirmedAt: json['confirmed_at'] as int,
      closedAt: json['closed_at'] as String?,
      roomDetails: json['room_details'] as Map<String, dynamic>?,
    );
  }
}
