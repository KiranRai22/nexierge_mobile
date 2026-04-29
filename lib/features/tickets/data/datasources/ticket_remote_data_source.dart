import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_client.dart';

abstract class TicketRemoteDataSource {
  Future<TicketDetailDto> getTicketDetails({required String ticketId});
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
