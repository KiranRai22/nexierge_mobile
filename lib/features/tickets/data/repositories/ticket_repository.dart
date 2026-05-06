import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/error_handler.dart';
import '../../../../core/network/api_client.dart';
import '../../data/datasources/ticket_remote_data_source.dart';
import '../../domain/entities/my_ticket.dart';
import '../../domain/entities/service_catalog.dart';
import '../../domain/entities/ticket_detail.dart';
import '../../domain/entities/ticket_form_options.dart';

/// Page of tickets returned by the paginated `/tickets/get/all` endpoint.
class TicketsPageResult {
  final List<MyTicket> items;
  final int curPage;

  /// `null` when the server has no more pages — infinite scroll uses this
  /// as the stop signal.
  final int? nextPage;

  /// Total number of tickets matching the filter on the server (across
  /// all pages). Drives the tab badge counts.
  final int itemsTotal;

  /// Resolved `department_id` per ticket, sourced from the nested
  /// `department.id` block in the response. Keyed by ticket id. Allows
  /// the UI to preserve department info even though `MyTicket` carries
  /// only `departmentId` as a string.
  final Map<String, String> departmentNameById;

  const TicketsPageResult({
    required this.items,
    required this.curPage,
    required this.nextPage,
    required this.itemsTotal,
    required this.departmentNameById,
  });

  bool get hasMore => nextPage != null;
}

abstract class TicketRepository {
  Future<TicketDetail> fetchTicketDetails({required String ticketId});
  Future<List<MyTicket>> fetchMyTickets({required String hotelId});

  /// Paginated tickets for the new tab-driven UX. Filters by [statuses]
  /// (server-side `status[]`); pages of [perPage] starting at [page].
  Future<TicketsPageResult> fetchTicketsPage({
    required String hotelId,
    required List<String> statuses,
    required int page,
    required int perPage,
  });
  Future<TicketFormOptions> fetchTicketFormOptions({required String hotelId});

  /// Create manual ticket via API.
  /// Returns created ticket ID on success.
  Future<String> createManualTicket({
    required String hotelId,
    required String summary,
    required String details,
    String? departmentId,
    String? guestStayId,
    String? contactId,
    String? source,
    bool createdByAi = false,
  });

  /// Advances a ticket through the backend state machine
  /// (NEW → ACCEPTED → IN_PROGRESS → DONE).
  Future<void> updateTicketStatus({required String ticketId});

  /// Cancels a ticket with a required reason.
  Future<void> cancelTicket({required String ticketId, required String reason});

  /// Resets a ticket back to NEW status.
  Future<void> resetTicket({required String ticketId});

  /// Updates the due time with a required reason.
  Future<void> changeDueTime({
    required String ticketId,
    required int newDueAt,
    required String reason,
  });

  /// Marks ticket as DONE, optionally with a resolution note.
  Future<void> markDoneWithNote({
    required String ticketId,
    String? resolutionNote,
  });

  /// Submits a catalog (paid) order via
  /// `POST /service_catalogs/user_app/order/create`. Returns the created
  /// ticket id (may be empty when the backend doesn't echo one).
  Future<String> createCatalogOrder({
    required CreateCatalogOrderRequestDto request,
  });

  /// Get all service catalogs for a hotel
  Future<List<ServiceCatalog>> fetchServiceCatalogs({required String hotelId});

  /// Get all items for a specific service catalog
  Future<List<ServiceCatalogItemDto>> fetchServiceCatalogItems({
    required String catalogId,
    int page,
  });
}

class _TicketRepositoryImpl implements TicketRepository {
  final TicketRemoteDataSource _remote;
  _TicketRepositoryImpl(this._remote);

  @override
  Future<TicketDetail> fetchTicketDetails({required String ticketId}) async {
    try {
      final dto = await _remote.getTicketDetails(ticketId: ticketId);
      return TicketDetail.fromJson({
        'ticket': dto.ticket,
        'events': dto.events,
      });
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<TicketsPageResult> fetchTicketsPage({
    required String hotelId,
    required List<String> statuses,
    required int page,
    required int perPage,
  }) async {
    try {
      final dto = await _remote.getAllTickets(
        hotelId: hotelId,
        statuses: statuses,
        page: page,
        perPage: perPage,
      );
      final names = <String, String>{};
      final items = dto.items
          .map((d) {
            // Prefer the nested department block — it carries the id and
            // localized name. Fall back to whatever flat id the server may
            // also include.
            final dept = d.department;
            final deptId =
                (dept?['id'] as String?) ??
                (dept?['department_id'] as String?) ??
                '';
            final deptName = (dept?['name'] as String?) ?? '';
            if (deptId.isNotEmpty && deptName.isNotEmpty) {
              names[d.id] = deptName;
            }
            final roomData = d.roomData;
            final roomDetails = roomData != null
                ? RoomDetails(
                    id: (roomData['id'] as String?) ?? '',
                    onbRoomNumber:
                        (roomData['onb_room_number'] as String?) ?? '',
                    floorId: (roomData['floor_id'] as String?) ?? '',
                    onbRoomTypeId:
                        (roomData['onb_room_type_id'] as String?) ?? '',
                  )
                : null;
            return MyTicket(
              id: d.id,
              createdAt: d.createdAt,
              lastTransitionAt: d.lastTransitionAt,
              hotelId: d.hotelId,
              departmentId: deptId,
              assignedToUserId: d.assignedToUserId,
              createdByUserId: d.createdByUserId,
              createdByAi: d.createdByAi,
              type: d.type,
              status: d.status,
              dueAt: d.dueAt,
              category: d.category,
              priority: d.priority,
              issueSummary: d.issueSummary,
              issueDetails: d.issueDetails,
              isIncident: d.isIncident,
              incidentNotes: d.incidentNotes,
              room: d.room,
              guestName: d.guestName,
              acknowledgedByUserId: d.acknowledgedByUserId,
              acknowledgedAt: d.acknowledgedAt,
              resolutionCode: d.resolutionCode,
              resolutionNotes: d.resolutionNotes,
              confirmedAt: d.confirmedAt,
              closedAt: d.closedAt is String ? d.closedAt as String : null,
              roomDetails: roomDetails,
            );
          })
          .toList(growable: false);
      return TicketsPageResult(
        items: items,
        curPage: dto.curPage,
        nextPage: dto.nextPage,
        itemsTotal: dto.itemsTotal,
        departmentNameById: names,
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<List<MyTicket>> fetchMyTickets({required String hotelId}) async {
    try {
      // ignore: avoid_print
      print('[TicketRepository] fetchMyTickets called with hotelId: $hotelId');
      final dtos = await _remote.getMyTickets(hotelId: hotelId);
      // ignore: avoid_print
      print('[TicketRepository] Mapped ${dtos.length} DTOs to domain entities');
      return dtos
          .map(
            (dto) => MyTicket(
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
                          (dto.roomDetails!['onb_room_number'] as String?) ??
                          '',
                      floorId: (dto.roomDetails!['floor_id'] as String?) ?? '',
                      onbRoomTypeId:
                          (dto.roomDetails!['onb_room_type_id'] as String?) ??
                          '',
                    )
                  : null,
            ),
          )
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<TicketFormOptions> fetchTicketFormOptions({
    required String hotelId,
  }) async {
    try {
      final dto = await _remote.getDepartmentsAndRooms(hotelId: hotelId);
      // Dedupe departments by department_id; skip rows missing the id since
      // they cannot be sent back to the server. `id` (the record id) is not
      // considered — the backend expects department_id.
      final seenDeptIds = <String>{};
      final uniqueDepartments = <HotelDepartment>[];
      for (final d in dto.departments) {
        if (d.id.isEmpty) continue;
        if (!seenDeptIds.add(d.id)) continue;
        uniqueDepartments.add(HotelDepartment.fromName(id: d.id, name: d.name));
      }
      return TicketFormOptions(departments: uniqueDepartments);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<String> createManualTicket({
    required String hotelId,
    required String summary,
    required String details,
    String? departmentId,
    String? guestStayId,
    String? contactId,
    String? source,
    bool createdByAi = false,
  }) async {
    try {
      final dto = await _remote.createManualTicket(
        request: CreateManualTicketRequestDto(
          hotelId: hotelId,
          summary: summary,
          details: details,
          departmentId: departmentId,
          guestStayId: guestStayId,
          contactId: contactId,
          source: source,
          createdByAi: createdByAi,
        ),
      );
      return dto.ticketId ?? '';
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<void> updateTicketStatus({required String ticketId}) async {
    try {
      await _remote.updateTicketStatus(ticketId: ticketId);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<void> cancelTicket({
    required String ticketId,
    required String reason,
  }) async {
    try {
      await _remote.cancelTicket(ticketId: ticketId, reason: reason);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<void> resetTicket({required String ticketId}) async {
    try {
      await _remote.resetTicket(ticketId: ticketId);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<void> changeDueTime({
    required String ticketId,
    required int newDueAt,
    required String reason,
  }) async {
    try {
      await _remote.changeDueTime(
        ticketId: ticketId,
        newDueAt: newDueAt,
        reason: reason,
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<String> createCatalogOrder({
    required CreateCatalogOrderRequestDto request,
  }) async {
    try {
      final dto = await _remote.createCatalogOrder(request: request);
      if (!dto.success) {
        throw Exception(dto.message ?? 'Catalog order create failed');
      }
      return dto.ticketId ?? '';
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<void> markDoneWithNote({
    required String ticketId,
    String? resolutionNote,
  }) async {
    try {
      await _remote.markDoneWithNote(
        ticketId: ticketId,
        resolutionNote: resolutionNote,
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<List<ServiceCatalog>> fetchServiceCatalogs({
    required String hotelId,
  }) async {
    try {
      final dtos = await _remote.getServiceCatalogs(hotelId: hotelId);
      return dtos.map((dto) => ServiceCatalog.fromDto(dto)).toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<List<ServiceCatalogItemDto>> fetchServiceCatalogItems({
    required String catalogId,
    int page = 0,
  }) async {
    try {
      return await _remote.getServiceCatalogItems(
        catalogId: catalogId,
        page: page,
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}

final ticketRepositoryProvider = Provider<TicketRepository>((ref) {
  final remote = ref.watch(ticketRemoteDataSourceProvider);
  return _TicketRepositoryImpl(remote);
});
