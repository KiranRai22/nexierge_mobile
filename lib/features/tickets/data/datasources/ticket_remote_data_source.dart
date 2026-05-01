import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_client.dart';

abstract class TicketRemoteDataSource {
  Future<TicketDetailDto> getTicketDetails({required String ticketId});
  Future<List<MyTicketDto>> getMyTickets({required String hotelId});
  Future<TicketFormOptionsDto> getDepartmentsAndRooms({
    required String hotelId,
  });
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
  Future<TicketFormOptionsDto> getDepartmentsAndRooms({
    required String hotelId,
  }) async {
    final res = await _dio.get(
      APIEndpoints.ticketsAddGetDepartmentsAndRooms,
      queryParameters: {'hotel_id': hotelId},
    );
    return TicketFormOptionsDto.fromJson(res.data as Map<String, dynamic>);
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

class TicketFormOptionsDto {
  final List<DepartmentDto> departments;
  final List<RoomLiteDto> rooms;

  TicketFormOptionsDto({required this.departments, required this.rooms});

  factory TicketFormOptionsDto.fromJson(Map<String, dynamic> json) {
    return TicketFormOptionsDto(
      departments: ((json['departments'] as List?) ?? const [])
          .map((e) => DepartmentDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      rooms: ((json['rooms'] as List?) ?? const [])
          .map((e) => RoomLiteDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DepartmentDto {
  final String id;
  final String name;

  DepartmentDto({required this.id, required this.name});

  factory DepartmentDto.fromJson(Map<String, dynamic> json) {
    return DepartmentDto(
      id: (json['department_id'] as String?) ??
          (json['id'] as String?) ??
          '',
      name: (json['name'] as String?) ?? '',
    );
  }
}

class RoomLiteDto {
  final String id;
  final String onbRoomNumber;

  RoomLiteDto({required this.id, required this.onbRoomNumber});

  factory RoomLiteDto.fromJson(Map<String, dynamic> json) {
    return RoomLiteDto(
      id: (json['id'] as String?) ?? '',
      onbRoomNumber: (json['onb_room_number'] as String?) ?? '',
    );
  }
}

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
    String s(String key) => (json[key] as String?) ?? '';
    int i(String key) => (json[key] as num?)?.toInt() ?? 0;
    bool b(String key) => (json[key] as bool?) ?? false;
    return MyTicketDto(
      id: s('id'),
      createdAt: i('created_at'),
      hotelId: s('hotel_id'),
      departmentId: s('department_id'),
      assignedToUserId: json['assigned_to_user_id'] as String?,
      createdByUserId: s('created_by_user_id'),
      createdByAi: b('created_by_ai'),
      type: s('type'),
      status: s('status'),
      dueAt: i('due_at'),
      category: s('category'),
      priority: s('priority'),
      issueSummary: s('issue_summary'),
      issueDetails: s('issue_details'),
      isIncident: b('is_incident'),
      incidentNotes: s('incident_notes'),
      room: s('room'),
      guestName: s('guest_name'),
      acknowledgedByUserId: json['acknowledged_by_user_id'] as String?,
      acknowledgedAt: i('acknowledged_at'),
      resolutionCode: s('resolution_code'),
      resolutionNotes: s('resolution_notes'),
      confirmedAt: i('confirmed_at'),
      closedAt: json['closed_at'] as String?,
      roomDetails: json['room_details'] as Map<String, dynamic>?,
    );
  }
}
