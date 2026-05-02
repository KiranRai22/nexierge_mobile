import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/error_handler.dart';
import '../../../../core/network/api_client.dart';
import '../../data/datasources/ticket_remote_data_source.dart';
import '../../domain/entities/my_ticket.dart';
import '../../domain/entities/ticket_detail.dart';
import '../../domain/entities/ticket_form_options.dart';
import '../../domain/models/ticket.dart';

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
    String? hotelDepartmentId,
    bool createdByAi = false,
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
      // Dedupe rooms by visible number — API can return multiple rows with
      // the same `onb_room_number` (e.g. across floors); the picker only
      // needs one entry per number. Keep the first occurrence.
      final seenRoomNumbers = <String>{};
      final uniqueRooms = <Room>[];
      for (final r in dto.rooms) {
        if (!seenRoomNumbers.add(r.onbRoomNumber)) continue;
        uniqueRooms.add(Room(id: r.id, number: r.onbRoomNumber, floor: 0));
      }
      // Sort by room number ascending — numeric when both sides parse,
      // alphabetical otherwise (so e.g. "101" < "102" < "1A" works).
      uniqueRooms.sort((a, b) {
        final na = int.tryParse(a.number);
        final nb = int.tryParse(b.number);
        if (na != null && nb != null) return na.compareTo(nb);
        if (na != null) return -1;
        if (nb != null) return 1;
        return a.number.compareTo(b.number);
      });
      // Same defensive dedupe for departments by id.
      final seenDeptIds = <String>{};
      final uniqueDepartments = <HotelDepartment>[];
      for (final d in dto.departments) {
        if (!seenDeptIds.add(d.id)) continue;
        uniqueDepartments.add(HotelDepartment.fromName(id: d.id, name: d.name));
      }
      return TicketFormOptions(
        departments: uniqueDepartments,
        rooms: uniqueRooms,
      );
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
    String? hotelDepartmentId,
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
          hotelDepartmentId: hotelDepartmentId,
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
}

final ticketRepositoryProvider = Provider<TicketRepository>((ref) {
  final remote = ref.watch(ticketRemoteDataSourceProvider);
  return _TicketRepositoryImpl(remote);
});
