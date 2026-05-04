import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/error_handler.dart';
import '../../../../core/network/api_client.dart';
import '../../data/datasources/ticket_remote_data_source.dart';
import '../../domain/entities/my_ticket.dart';
import '../../domain/entities/service_catalog.dart';
import '../../domain/entities/ticket_detail.dart';
import '../../domain/entities/ticket_form_options.dart';

abstract class TicketRepository {
  Future<TicketDetail> fetchTicketDetails({required String ticketId});
  Future<List<MyTicket>> fetchMyTickets({required String hotelId});
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

  /// Get all service catalogs for a hotel
  Future<List<ServiceCatalog>> fetchServiceCatalogs({required String hotelId});
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
}

final ticketRepositoryProvider = Provider<TicketRepository>((ref) {
  final remote = ref.watch(ticketRemoteDataSourceProvider);
  return _TicketRepositoryImpl(remote);
});
