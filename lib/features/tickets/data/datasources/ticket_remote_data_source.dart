import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_client.dart';

abstract class TicketRemoteDataSource {
  Future<TicketDetailDto> getTicketDetails({required String ticketId});
  Future<List<MyTicketDto>> getMyTickets({required String hotelId});
  Future<TicketFormOptionsDto> getDepartmentsAndRooms({
    required String hotelId,
  });
  Future<CreateManualTicketResponseDto> createManualTicket({
    required CreateManualTicketRequestDto request,
  });

  /// Get all service catalogs for a hotel
  Future<List<ServiceCatalogDto>> getServiceCatalogs({required String hotelId});
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

  @override
  Future<CreateManualTicketResponseDto> createManualTicket({
    required CreateManualTicketRequestDto request,
  }) async {
    final payload = request.toJson();
    debugPrint('[TicketRemoteDataSource] createManualTicket payload: $payload');
    final res = await _dio.post(APIEndpoints.ticketsManual, data: payload);
    debugPrint(
      '[TicketRemoteDataSource] createManualTicket response: ${res.data}',
    );
    return CreateManualTicketResponseDto.fromJson(
      res.data as Map<String, dynamic>,
    );
  }

  @override
  Future<List<ServiceCatalogDto>> getServiceCatalogs({
    required String hotelId,
  }) async {
    final url = '${APIEndpoints.serviceCatalogsAll}/$hotelId';
    debugPrint('[TicketRemoteDataSource] getServiceCatalogs: $url');
    final res = await _dio.get(url);
    final list = res.data as List<dynamic>;
    return list
        .map((e) => ServiceCatalogDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final ticketRemoteDataSourceProvider = Provider<TicketRemoteDataSource>((ref) {
  final dio = ref.watch(authedDioProvider);
  return _TicketRemoteDataSourceImpl(dio);
});

/// Wraps the `/tickets/add/get_departnents_and_rooms` response.
///
/// We intentionally ignore the `rooms` array the server returns — rooms now
/// come from `checkedInGuestStaysProvider`. Only departments are persisted.
class TicketFormOptionsDto {
  final List<DepartmentDto> departments;

  TicketFormOptionsDto({required this.departments});

  factory TicketFormOptionsDto.fromJson(Map<String, dynamic> json) {
    return TicketFormOptionsDto(
      departments: ((json['departments'] as List?) ?? const [])
          .map((e) => DepartmentDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DepartmentDto {
  /// Server-issued `department_id` — the canonical id we send back on every
  /// payload. The wrapping `id` (the record/row id) is intentionally not
  /// read; per the API contract it is not the value the backend expects.
  final String id;
  final String name;

  DepartmentDto({required this.id, required this.name});

  factory DepartmentDto.fromJson(Map<String, dynamic> json) {
    return DepartmentDto(
      id: (json['department_id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
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

/// Request DTO for POST /tickets/manual
class CreateManualTicketRequestDto {
  final String? hotelId;
  final bool createdByAi;
  final String? departmentId;
  final String? guestStayId;
  final String? contactId;
  final String summary;
  final String details;

  /// Origin of the ticket (e.g. whatsApp, frontDesk). Wire format: camelCase
  /// `TicketSource.name`. Omitted from the payload when null.
  final String? source;

  CreateManualTicketRequestDto({
    this.hotelId,
    this.createdByAi = false,
    this.departmentId,
    this.guestStayId,
    this.contactId,
    this.source,
    required this.summary,
    required this.details,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'hotel_id': hotelId,
      'created_by_ai': createdByAi,
      'department_id': departmentId,
      'guest_stay_id': guestStayId,
      'contact_id': contactId,
      'summary': summary,
      'details': details,
    };
    if (source != null) map['source'] = source;
    return map;
  }
}

/// Response DTO for POST /tickets/manual
/// Returns created ticket ID and success flag.
class CreateManualTicketResponseDto {
  final String? ticketId;
  final bool success;
  final String? message;

  CreateManualTicketResponseDto({
    this.ticketId,
    required this.success,
    this.message,
  });

  factory CreateManualTicketResponseDto.fromJson(Map<String, dynamic> json) {
    return CreateManualTicketResponseDto(
      ticketId: json['ticket_id'] as String? ?? json['id'] as String?,
      success: (json['success'] as bool?) ?? true,
      message: json['message'] as String?,
    );
  }
}

/// Logo info for service catalog
class ServiceCatalogLogoDto {
  final String? url;
  final String? name;
  final String? mime;

  ServiceCatalogLogoDto({this.url, this.name, this.mime});

  factory ServiceCatalogLogoDto.fromJson(Map<String, dynamic> json) {
    return ServiceCatalogLogoDto(
      url: json['url'] as String?,
      name: json['name'] as String?,
      mime: json['mime'] as String?,
    );
  }
}

/// Service Catalog DTO from API
class ServiceCatalogDto {
  final String id;
  final String name;
  final String? description;
  final bool isEnabled;
  final String? brandColor;
  final ServiceCatalogLogoDto? logo;
  final int categories;
  final int items;
  final int sections;

  ServiceCatalogDto({
    required this.id,
    required this.name,
    this.description,
    this.isEnabled = true,
    this.brandColor,
    this.logo,
    this.categories = 0,
    this.items = 0,
    this.sections = 0,
  });

  factory ServiceCatalogDto.fromJson(Map<String, dynamic> json) {
    return ServiceCatalogDto(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      isEnabled: json['is_enabled'] as bool? ?? true,
      brandColor: json['brand_color'] as String?,
      logo: json['logo'] != null
          ? ServiceCatalogLogoDto.fromJson(json['logo'] as Map<String, dynamic>)
          : null,
      categories: json['categories'] as int? ?? 0,
      items: json['items'] as int? ?? 0,
      sections: json['sections'] as int? ?? 0,
    );
  }
}
