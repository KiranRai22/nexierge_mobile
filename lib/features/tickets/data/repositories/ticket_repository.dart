import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/error_handler.dart';
import '../../../../core/network/api_client.dart';
import '../../data/datasources/ticket_remote_data_source.dart';
import '../../domain/entities/my_ticket.dart';
import '../../domain/entities/ticket_detail.dart';

abstract class TicketRepository {
  Future<TicketDetail> fetchTicketDetails({required String ticketId});
  Future<List<MyTicket>> fetchMyTickets({required String hotelId});
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
                      id: dto.roomDetails!['id'] as String,
                      onbRoomNumber:
                          dto.roomDetails!['onb_room_number'] as String,
                      floorId: dto.roomDetails!['floor_id'] as String,
                      onbRoomTypeId:
                          dto.roomDetails!['onb_room_type_id'] as String,
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
}

final ticketRepositoryProvider = Provider<TicketRepository>((ref) {
  final remote = ref.watch(ticketRemoteDataSourceProvider);
  return _TicketRepositoryImpl(remote);
});
