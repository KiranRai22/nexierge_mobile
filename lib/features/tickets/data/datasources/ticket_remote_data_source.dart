import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_client.dart';

abstract class TicketRemoteDataSource {
  Future<TicketDetailDto> getTicketDetails({required String ticketId});
  Future<List<MyTicketDto>> getMyTickets({required String hotelId});

  /// GET /tickets/get/all — paginated list filtered by status[].
  Future<TicketsPageDto> getAllTickets({
    required String hotelId,
    required List<String> statuses,
    required int page,
    required int perPage,
  });
  Future<TicketFormOptionsDto> getDepartmentsAndRooms({
    required String hotelId,
  });
  Future<CreateManualTicketResponseDto> createManualTicket({
    required CreateManualTicketRequestDto request,
  });

  /// POST /tickets/update_status — advances ticket through state machine.
  Future<void> updateTicketStatus({required String ticketId});

  /// POST /tickets/cancel — cancels ticket with a required reason.
  Future<void> cancelTicket({required String ticketId, required String reason});

  /// POST /tickets/reset — resets ticket back to NEW status.
  Future<void> resetTicket({required String ticketId});

  /// POST /tickets/change_due — updates the due time with a required reason.
  Future<void> changeDueTime({
    required String ticketId,
    required int newDueAt,
    required String reason,
  });

  /// POST /tickets/update_status with resolution note — advances to DONE.
  Future<void> markDoneWithNote({
    required String ticketId,
    String? resolutionNote,
  });

  /// Get all service catalogs for a hotel
  Future<List<ServiceCatalogDto>> getServiceCatalogs({required String hotelId});

  /// Get all items for a specific service catalog
  Future<List<ServiceCatalogItemDto>> getServiceCatalogItems({
    required String catalogId,
    int page = 0,
  });

  /// POST /service_catalogs/user_app/order/create — submits a catalog order
  /// (paid restaurant / room-service order). Returns the created ticket id.
  Future<CreateCatalogOrderResponseDto> createCatalogOrder({
    required CreateCatalogOrderRequestDto request,
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
  Future<CreateCatalogOrderResponseDto> createCatalogOrder({
    required CreateCatalogOrderRequestDto request,
  }) async {
    final payload = request.toJson();
    debugPrint(
      '[TicketRemoteDataSource] createCatalogOrder payload: $payload',
    );
    final res = await _dio.post(
      APIEndpoints.serviceCatalogsCreateOrder,
      data: payload,
    );
    debugPrint(
      '[TicketRemoteDataSource] createCatalogOrder response: ${res.data}',
    );
    return CreateCatalogOrderResponseDto.fromJson(
      res.data is Map<String, dynamic>
          ? res.data as Map<String, dynamic>
          : <String, dynamic>{},
    );
  }

  @override
  Future<TicketsPageDto> getAllTickets({
    required String hotelId,
    required List<String> statuses,
    required int page,
    required int perPage,
  }) async {
    debugPrint(
      '[TicketRemoteDataSource] getAllTickets hotel=$hotelId statuses=$statuses page=$page perPage=$perPage',
    );
    final res = await _dio.get(
      APIEndpoints.ticketsGetAll,
      queryParameters: {
        'hotel_id': hotelId,
        'status[]': statuses,
        'page': page,
        'per_page': perPage,
      },
      // Xano expects repeated `status[]=A&status[]=B` (not bracketed
      // indices). ListFormat.multi emits the key once per value as-is.
      options: Options(listFormat: ListFormat.multi),
    );
    return TicketsPageDto.fromJson(res.data as Map<String, dynamic>);
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
  Future<void> updateTicketStatus({required String ticketId}) async {
    debugPrint('[TicketRemoteDataSource] updateTicketStatus: $ticketId');
    await _dio.post(
      APIEndpoints.ticketsUpdateStatus,
      data: {'ticket_id': ticketId},
    );
  }

  @override
  Future<void> cancelTicket({
    required String ticketId,
    required String reason,
  }) async {
    debugPrint('[TicketRemoteDataSource] cancelTicket: $ticketId');
    await _dio.post(
      APIEndpoints.ticketsCancel,
      data: {'ticket_id': ticketId, 'reason': reason},
    );
  }

  @override
  Future<void> resetTicket({required String ticketId}) async {
    debugPrint('[TicketRemoteDataSource] resetTicket: $ticketId');
    await _dio.post(APIEndpoints.ticketsReset, data: {'ticket_id': ticketId});
  }

  @override
  Future<void> changeDueTime({
    required String ticketId,
    required int newDueAt,
    required String reason,
  }) async {
    debugPrint('[TicketRemoteDataSource] changeDueTime: $ticketId');
    await _dio.post(
      APIEndpoints.ticketsChangeDue,
      data: {'ticket_id': ticketId, 'due_at': newDueAt, 'reason': reason},
    );
  }

  @override
  Future<void> markDoneWithNote({
    required String ticketId,
    String? resolutionNote,
  }) async {
    debugPrint('[TicketRemoteDataSource] markDoneWithNote: $ticketId');
    await _dio.post(
      APIEndpoints.ticketsUpdateStatus,
      data: {
        'ticket_id': ticketId,
        if (resolutionNote != null && resolutionNote.isNotEmpty)
          'resolution_notes': resolutionNote,
      },
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

  @override
  Future<List<ServiceCatalogItemDto>> getServiceCatalogItems({
    required String catalogId,
    int page = 0,
  }) async {
    final url = '${APIEndpoints.serviceCatalogItems}/$catalogId';
    debugPrint('[TicketRemoteDataSource] getServiceCatalogItems: $url');
    final res = await _dio.get(url, queryParameters: {'page': page});
    final list = res.data as List<dynamic>;
    return list
        .map((e) => ServiceCatalogItemDto.fromJson(e as Map<String, dynamic>))
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

/// Wraps the paginated `/tickets/get/all` response.
///
/// `nextPage` is null when the server has no more pages — this is the
/// signal infinite-scroll uses to stop loading.
class TicketsPageDto {
  final List<AllTicketDto> items;
  final int curPage;
  final int? nextPage;
  final int itemsTotal;

  TicketsPageDto({
    required this.items,
    required this.curPage,
    required this.nextPage,
    required this.itemsTotal,
  });

  factory TicketsPageDto.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List?) ?? const [];
    return TicketsPageDto(
      items: rawItems
          .map((e) => AllTicketDto.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      curPage: (json['curPage'] as num?)?.toInt() ?? 1,
      nextPage: (json['nextPage'] as num?)?.toInt(),
      itemsTotal: (json['itemsTotal'] as num?)?.toInt() ?? rawItems.length,
    );
  }
}

/// DTO for items inside the `/tickets/get/all` response. Carries the
/// richer nested fields the endpoint returns (department object, room_data,
/// last_transition_at) so we don't have to refetch ticket detail just to
/// render the card.
class AllTicketDto {
  final String id;
  final int createdAt;
  final int updatedAt;
  final int lastTransitionAt;
  final String hotelId;
  final String? assignedToUserId;
  final String createdByUserId;
  final bool createdByAi;
  final String type;
  final String ticketType;
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
  final dynamic closedAt;

  /// Department block: `{ id, name, mobile_icon, ... }`.
  final Map<String, dynamic>? department;

  /// Room data block: `{ id, onb_room_number, ... }`.
  final Map<String, dynamic>? roomData;

  AllTicketDto({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.lastTransitionAt,
    required this.hotelId,
    this.assignedToUserId,
    required this.createdByUserId,
    required this.createdByAi,
    required this.type,
    required this.ticketType,
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
    this.department,
    this.roomData,
  });

  factory AllTicketDto.fromJson(Map<String, dynamic> json) {
    String s(String key) => (json[key] as String?) ?? '';
    int i(String key) => (json[key] as num?)?.toInt() ?? 0;
    bool b(String key) => (json[key] as bool?) ?? false;
    return AllTicketDto(
      id: s('id'),
      createdAt: i('created_at'),
      updatedAt: i('updated_at'),
      lastTransitionAt: i('last_transition_at'),
      hotelId: s('hotel_id'),
      assignedToUserId: json['assigned_to_user_id'] as String?,
      createdByUserId: s('created_by_user_id'),
      createdByAi: b('created_by_ai'),
      type: s('type'),
      ticketType: s('ticket_type'),
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
      closedAt: json['closed_at'],
      department: json['department'] as Map<String, dynamic>?,
      roomData: json['room_data'] as Map<String, dynamic>?,
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

// ─────────────────────────────────────────────────────────────────────────────
// Service Catalog Items DTOs
// ─────────────────────────────────────────────────────────────────────────────

/// One item inside a service catalog (e.g. "Akara").
class ServiceCatalogItemDto {
  final String id;
  final String name;
  final String? description;
  final List<String> images;
  final double price;
  final String currency;
  final String availability;
  final int? etaMinutesMin;
  final int? etaMinutesMax;
  final List<String> ingredients;
  final String? categoryName;
  final List<ModifierListItemDto> modifierList;

  ServiceCatalogItemDto({
    required this.id,
    required this.name,
    this.description,
    this.images = const [],
    this.price = 0,
    this.currency = 'USD',
    this.availability = 'available',
    this.etaMinutesMin,
    this.etaMinutesMax,
    this.ingredients = const [],
    this.categoryName,
    this.modifierList = const [],
  });

  factory ServiceCatalogItemDto.fromJson(Map<String, dynamic> json) {
    return ServiceCatalogItemDto(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      images:
          (json['image'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .where((s) => s.isNotEmpty)
              .toList() ??
          const [],
      price: (json['price'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'USD',
      availability: json['availability'] as String? ?? 'available',
      etaMinutesMin: (json['eta_minute_min'] as num?)?.toInt(),
      etaMinutesMax: (json['eta_minutes_max'] as num?)?.toInt(),
      ingredients:
          (json['ingredients'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .where((s) => s.isNotEmpty)
              .toList() ??
          const [],
      categoryName: json['category_name'] as String?,
      modifierList:
          (json['modifier_list'] as List<dynamic>?)
              ?.map(
                (e) => ModifierListItemDto.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    );
  }
}

/// Wrapper around modifier_group inside an item's modifier_list array.
class ModifierListItemDto {
  final String id;
  final ModifierGroupDto? modifierGroup;

  ModifierListItemDto({required this.id, this.modifierGroup});

  factory ModifierListItemDto.fromJson(Map<String, dynamic> json) {
    return ModifierListItemDto(
      id: json['id'] as String,
      modifierGroup: json['modifier_group'] != null
          ? ModifierGroupDto.fromJson(
              json['modifier_group'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

/// Modifier group (e.g. "With Onions", "Sides") with selection rules.
class ModifierGroupDto {
  final String id;
  final String name;
  final int minSelect;
  final int maxSelect;
  final bool isRequired;
  final List<ModifierDto> modifiers;

  ModifierGroupDto({
    required this.id,
    required this.name,
    this.minSelect = 0,
    this.maxSelect = 1,
    this.isRequired = false,
    this.modifiers = const [],
  });

  factory ModifierGroupDto.fromJson(Map<String, dynamic> json) {
    return ModifierGroupDto(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      minSelect: (json['min_select'] as num?)?.toInt() ?? 0,
      maxSelect: (json['max_select'] as num?)?.toInt() ?? 1,
      isRequired: json['is_required'] as bool? ?? false,
      modifiers:
          (json['modifiers'] as List<dynamic>?)
              ?.map((e) => ModifierDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

/// Individual modifier option (e.g. "Yes", "Agege Bread").
class ModifierDto {
  final String id;
  final String name;
  final bool enableMultipleSelect;
  final int maxItems;
  final double price;

  ModifierDto({
    required this.id,
    required this.name,
    this.enableMultipleSelect = false,
    this.maxItems = 1,
    this.price = 0,
  });

  factory ModifierDto.fromJson(Map<String, dynamic> json) {
    return ModifierDto(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      enableMultipleSelect: json['enable_multiple_select'] as bool? ?? false,
      maxItems: (json['max_items'] as num?)?.toInt() ?? 1,
      price: (json['price'] as num?)?.toDouble() ?? 0,
    );
  }
}

// ──────────────────────────────────────────────────────────────────────
// Create Catalog Order — request/response DTOs
// ──────────────────────────────────────────────────────────────────────

/// One picked modifier. `modifierQuantity` is 1 for single-select radios,
/// the stepper value for multi-add-on groups.
class CreateOrderModifierDto {
  final String modifierId;
  final String modifierName;
  final int modifierQuantity;
  final double modifierPrice;

  const CreateOrderModifierDto({
    required this.modifierId,
    required this.modifierName,
    required this.modifierQuantity,
    required this.modifierPrice,
  });

  Map<String, dynamic> toJson() => {
        'modifier_id': modifierId,
        'modifier_name': modifierName,
        'modifier_quantity': modifierQuantity,
        'modifier_price': modifierPrice,
      };
}

/// Bundle of picked modifiers from a single option-group.
class CreateOrderModifierGroupDto {
  final String modifierGroupId;
  final String modifierGroupName;
  final List<CreateOrderModifierDto> modifiers;

  const CreateOrderModifierGroupDto({
    required this.modifierGroupId,
    required this.modifierGroupName,
    required this.modifiers,
  });

  Map<String, dynamic> toJson() => {
        'modifier_group_id': modifierGroupId,
        'modifier_group_name': modifierGroupName,
        'modifiers': modifiers.map((m) => m.toJson()).toList(),
      };
}

/// One ordered item with its picked modifier groups.
class CreateOrderItemDto {
  final String itemId;
  final String specialInstructions;
  final List<CreateOrderModifierGroupDto> modifierGroups;

  const CreateOrderItemDto({
    required this.itemId,
    required this.specialInstructions,
    required this.modifierGroups,
  });

  Map<String, dynamic> toJson() => {
        'item_id': itemId,
        'special_instructions': specialInstructions,
        'modifier_groups':
            modifierGroups.map((g) => g.toJson()).toList(),
      };
}

/// Request body for `/service_catalogs/user_app/order/create`.
///
/// `guestStayId` and `contactId` are sent as empty strings when no
/// checked-in stay is selected (walk-in / unattended order).
class CreateCatalogOrderRequestDto {
  final String hotelId;
  final String guestStayId;
  final String contactId;
  final String serviceCatalogsId;
  final String notes;
  final double subTotal;
  final double tax;
  final int slaTargetMinutes;
  final String trackingId;
  final List<CreateOrderItemDto> items;

  const CreateCatalogOrderRequestDto({
    required this.hotelId,
    required this.guestStayId,
    required this.contactId,
    required this.serviceCatalogsId,
    required this.notes,
    required this.subTotal,
    required this.tax,
    required this.slaTargetMinutes,
    required this.trackingId,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
        'hotel_id': hotelId,
        'guest_stay_id': guestStayId,
        'contact_id': contactId,
        'service_catalogs_id': serviceCatalogsId,
        'notes': notes,
        'sub_total': subTotal,
        'tax': tax,
        'sla_target_minutes': slaTargetMinutes,
        'tracking_id': trackingId,
        'items': items.map((i) => i.toJson()).toList(),
      };
}

/// Response for `/service_catalogs/user_app/order/create`. The exact
/// shape isn't fully nailed down — we accept either a flat ticket id at
/// `id` / `ticket_id` or null, and surface a derived success flag.
class CreateCatalogOrderResponseDto {
  final String? ticketId;
  final bool success;
  final String? message;

  const CreateCatalogOrderResponseDto({
    this.ticketId,
    required this.success,
    this.message,
  });

  factory CreateCatalogOrderResponseDto.fromJson(Map<String, dynamic> json) {
    final rawId = json['ticket_id'] as String? ?? json['id'] as String?;
    return CreateCatalogOrderResponseDto(
      ticketId: rawId,
      success: (json['success'] as bool?) ?? rawId != null,
      message: json['message'] as String?,
    );
  }
}
