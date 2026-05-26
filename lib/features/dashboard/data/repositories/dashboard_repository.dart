import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/error_handler.dart';
import '../../../../core/network/api_client.dart';
import '../../data/datasources/dashboard_remote_data_source.dart';
import '../../domain/entities/dashboard_counts.dart';
import '../../domain/entities/needs_attention_item.dart';

abstract class DashboardRepository {
  Future<HotelDetailsDto> fetchHotelDetails({String? hotelUserId});
  Future<DashboardNumbersDto> fetchNumbers({String? hotelId, bool today});

  /// Fetch + map dashboard KPI counts. UI / providers consume this domain
  /// model; the raw DTO never leaves the data layer.
  /// Set [today] to true to get only today's counts.
  Future<DashboardCounts> fetchCounts({String? hotelId, bool today});

  /// Fetch needs attention items from API.
  Future<List<NeedsAttentionItem>> fetchNeedsAttention({
    required String hotelId,
  });
}

class _DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource _remote;
  _DashboardRepositoryImpl(this._remote);

  @override
  Future<HotelDetailsDto> fetchHotelDetails({String? hotelUserId}) async {
    try {
      return await _remote.getHotelDetails(hotelUserId: hotelUserId);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<DashboardNumbersDto> fetchNumbers({String? hotelId, bool today = false}) async {
    try {
      return await _remote.getNumbers(hotelId: hotelId, today: today);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<DashboardCounts> fetchCounts({String? hotelId, bool today = false}) async {
    final dto = await fetchNumbers(hotelId: hotelId, today: today);
    return DashboardCounts(
      // not_started from API maps to incoming
      incomingCount: _toInt(dto.notStarted),
      inProgressCount: _toInt(dto.inprogress),
      overdueCount: _toInt(dto.overdue),
      doneCount: _toInt(dto.done),
    );
  }

  @override
  Future<List<NeedsAttentionItem>> fetchNeedsAttention({
    required String hotelId,
  }) async {
    try {
      final dtos = await _remote.getNeedsAttention(hotelId: hotelId);
      debugPrint(
        '[DashboardRepository] fetchNeedsAttention: received ${dtos.length} items, '
        'statuses: ${dtos.map((d) => d.status).toSet().toList()}',
      );
      // Filter out DONE tickets — they don't need attention.
      final active = dtos.where(
        (dto) => dto.status.toUpperCase() != 'DONE',
      );
      return active
          .map(
            (dto) => NeedsAttentionItem(
              id: dto.id,
              createdAt: dto.createdAt,
              departmentId: dto.departmentId,
              status: dto.status,
              dueAt: dto.dueAt,
              room: dto.room,
              guestName: dto.guestName,
              acknowledgedAt: dto.acknowledgedAt,
              department: DepartmentInfo(
                name: dto.department.name,
                mobileIcon: dto.department.mobileIcon,
                icon: IconInfo(url: dto.department.icon.url),
              ),
              onbRoomNumber: dto.onbRoomNumber,
            ),
          )
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  /// Defensive parse — backend ships numeric counts as strings. Null /
  /// non-numeric falls back to 0 so the UI never breaks on a stray payload.
  int _toInt(String? raw) {
    if (raw == null || raw.isEmpty) return 0;
    return int.tryParse(raw.trim()) ?? 0;
  }
}

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final remote = ref.watch(dashboardRemoteDataSourceProvider);
  return _DashboardRepositoryImpl(remote);
});
