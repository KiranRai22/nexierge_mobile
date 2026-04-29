import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/error_handler.dart';
import '../../../../core/network/api_client.dart';
import '../../data/datasources/ticket_remote_data_source.dart';
import '../../domain/entities/ticket_detail.dart';

abstract class TicketRepository {
  Future<TicketDetail> fetchTicketDetails({required String ticketId});
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
}

final ticketRepositoryProvider = Provider<TicketRepository>((ref) {
  final remote = ref.watch(ticketRemoteDataSourceProvider);
  return _TicketRepositoryImpl(remote);
});
