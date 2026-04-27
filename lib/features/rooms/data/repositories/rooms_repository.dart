import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/error_handler.dart';
import '../../../../core/network/api_client.dart';
import '../../data/datasources/rooms_remote_data_source.dart';

abstract class RoomsRepository {
  Future<RoomDetailsDto> getRoomDetails({required String roomId});
  Future<List<RoomDto>> getAll({required String hotelId, String? status});
  Future<RoomDto> updateStatus({
    required String roomId,
    required String status,
  });
  Future<void> approveStatusChange({required int roomEventId});
}

class _RoomsRepositoryImpl implements RoomsRepository {
  final RoomsRemoteDataSource _remote;
  _RoomsRepositoryImpl(this._remote);

  @override
  Future<RoomDetailsDto> getRoomDetails({required String roomId}) async {
    try {
      return await _remote.getRoomDetails(roomId: roomId);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<List<RoomDto>> getAll({
    required String hotelId,
    String? status,
  }) async {
    try {
      return await _remote.getAll(hotelId: hotelId, status: status);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<RoomDto> updateStatus({
    required String roomId,
    required String status,
  }) async {
    try {
      return await _remote.updateStatus(roomId: roomId, status: status);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<void> approveStatusChange({required int roomEventId}) async {
    try {
      return await _remote.approveStatusChange(roomEventId: roomEventId);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}

final roomsRepositoryProvider = Provider<RoomsRepository>((ref) {
  final remote = ref.watch(roomsRemoteDataSourceProvider);
  return _RoomsRepositoryImpl(remote);
});
