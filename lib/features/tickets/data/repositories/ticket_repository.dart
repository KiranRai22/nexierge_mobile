import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/error_handler.dart';
import '../../../../core/network/api_client.dart';
import '../../data/datasources/ticket_remote_data_source.dart';
import '../../domain/entities/my_ticket.dart';
import '../../domain/entities/service_catalog.dart';
import '../../domain/entities/ticket_detail.dart';
import '../../domain/entities/ticket_form_options.dart';

/// Identifies which v2 list endpoint to call. The repo maps each to the
/// matching `getTicketsV2*` data-source method.
enum TicketsV2Tab {
  incoming, // /ticketsv2/new
  backlog, // /ticketsv2/backlog
  inProgress, // /ticketsv2/in_progress (drives Today)
  doneToday, // /ticketsv2/done (drives Today→Done sub-tab)
  doneHistory, // /ticketsv2/done/history (drives primary Done tab)
}

/// Page of tickets returned by the paginated `/tickets/get_my_tickets`
/// endpoint.
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

  /// Paginated tickets for the tab-driven UX, sourced from
  /// `/tickets/get_my_tickets`. Filters by [statuses] (server-side
  /// `status[]`); pages of [perPage] starting at [page].
  Future<TicketsPageResult> fetchTicketsPage({
    required String hotelId,
    required List<String> statuses,
    required int page,
    required int perPage,
    // NEW FILTERING PARAMETERS
    String? departmentId,
    int? createdAtStartDate,
    int? createdAtEndDate,
    String? ticketType,
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
    String type = 'MANUAL',
  });

  /// Sets a ticket's status explicitly. Allowed [newStatus] values:
  /// NEW, ACCEPTED, IN_PROGRESS, ON_HOLD, DONE.
  /// CANCELED is set via [cancelTicket]; EXPIRED is server-driven only.
  /// [resolutionNote] is sent as `resolution_notes` when set (used with DONE).
  Future<void> changeTicketStatus({
    required String ticketId,
    required String newStatus,
    String? resolutionNote,
  });

  /// Cancels a ticket with a required reason.
  Future<void> cancelTicket({required String ticketId, required String reason});

  /// Updates the due time with a required reason. The hotel id is required
  /// by the backend so the change is scoped to the correct tenant.
  Future<void> changeDueTime({
    required String ticketId,
    required String hotelId,
    required int newDueAt,
    required String reason,
  });

  /// Marks ticket as DONE, optionally with a resolution note.
  Future<void> markDoneWithNote({
    required String ticketId,
    String? resolutionNote,
  });

  /// @Deprecated('Use startTicketV2 instead')
  @Deprecated('Use startTicketV2 instead')
  Future<void> acknowledgeTicket({
    required String ticketId,
    required int dueAt,
    String? notes,
  });

  /// @Deprecated('Use startTicketV2 instead')
  @Deprecated('Use startTicketV2 instead')
  Future<void> acknowledgeAndStartTicket({
    required String ticketId,
    required int dueAt,
    String? notes,
  });

  // ─── Tickets V2 ───────────────────────────────────────────────────────
  // Per-status paginated lists. Response shape identical to v1 — same
  // domain mapping used in [fetchTicketsPage] is reused below.

  Future<TicketsPageResult> fetchTicketsV2Page({
    required TicketsV2Tab tab,
    required String hotelId,
    required int page,
    required int perPage,
    String? departmentId,
    String? source,
    String? ticketType,
    int? createdAtStartDate,
    int? createdAtEndDate,
  });

  /// POST /ticketsv2/start/{id}. [dueAt] is sent as UTC ISO-8601.
  Future<void> startTicketV2({
    required String ticketId,
    required DateTime dueAt,
  });

  /// POST /ticketsv2/done/{id}. Body carries `resolution_notes` (same as
  /// legacy [markDoneWithNote]).
  Future<void> completeTicketV2({
    required String ticketId,
    String? resolutionNote,
  });

  /// POST /ticketsv2/backlog/{id}. Moves ticket to backlog.
  Future<void> moveToBacklogV2({
    required String ticketId,
    required String reason,
  });

  /// POST /ticketsv2/add_time/{id}. Adds time to ticket SLA.
  Future<void> addTimeV2({
    required String ticketId,
    required String reason,
    int? extensionMinutes,
  });

  /// POST /ticketsv2/reset_acknowledge/{id}. Resets ticket acknowledgement.
  Future<void> resetAcknowledgeV2({
    required String ticketId,
    required String reason,
  });

  /// POST /ticketsv2/cancel. Cancels ticket.
  Future<void> cancelTicketV2({
    required String ticketId,
    required String reason,
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
      // ignore: avoid_print
      print('[TicketRepository] fetchTicketDetails called with ticketId: $ticketId');
      final dto = await _remote.getTicketDetails(ticketId: ticketId);
      // ignore: avoid_print
      print('[TicketRepository] Ticket details fetched successfully');
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
    String? departmentId,
    int? createdAtStartDate,
    int? createdAtEndDate,
    String? ticketType,
  }) async {
    try {
      final dto = await _remote.getMyTicketsPage(
        hotelId: hotelId,
        statuses: statuses,
        page: page,
        perPage: perPage,
        departmentId: departmentId,
        createdAtStartDate: createdAtStartDate,
        createdAtEndDate: createdAtEndDate,
        ticketType: ticketType,
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
            final deptCode = (dept?['code'] as String?) ?? '';
            final deptMobileIcon = (dept?['mobile_icon'] as String?) ?? '';
            final deptIcon = dept?['icon'] as Map?;
            final deptIconUrl = (deptIcon?['url'] as String?) ?? '';
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
            final universalItems = d.universalDetails
                .map(
                  (u) => UniversalTicketItem(
                    id: u.id,
                    item: u.item,
                    emoji: u.emoji,
                    thumbnailUrl: u.thumbnailUrl,
                    nameI18n: u.nameI18n,
                  ),
                )
                .toList(growable: false);
            final catalogDetails = d.catalogDetails == null
                ? null
                : CatalogTicketDetails(
                    catalogName: d.catalogDetails!.catalogName,
                    logoUrl: d.catalogDetails!.logoUrl,
                    brandColorHex: d.catalogDetails!.brandColorHex,
                    grandTotal: d.catalogDetails!.grandTotal,
                    currency: d.catalogDetails!.currency,
                    items: d.catalogDetails!.items
                        .map(
                          (i) => CatalogTicketItem(
                            itemName: i.itemName,
                            imageUrl: i.imageUrl,
                          ),
                        )
                        .toList(growable: false),
                  );
            final manualDetails = d.manualDetails == null
                ? null
                : ManualTicketDetails(
                    summary: d.manualDetails!.summary,
                    details: d.manualDetails!.details,
                  );
            return MyTicket(
              id: d.id,
              createdAt: d.createdAt,
              updatedAt: d.updatedAt,
              lastTransitionAt: d.lastTransitionAt,
              slaBreached: d.slaBreached,
              hotelId: d.hotelId,
              departmentId: deptId,
              departmentName: deptName.isEmpty ? null : deptName,
              departmentMobileIcon:
                  deptMobileIcon.isEmpty ? null : deptMobileIcon,
              departmentIconUrl: deptIconUrl.isEmpty ? null : deptIconUrl,
              departmentCode: deptCode.isEmpty ? null : deptCode,
              assignedToUserId: d.assignedToUserId,
              createdByUserId: d.createdByUserId,
              createdByAi: d.createdByAi,
              type: d.type,
              ticketType: d.ticketType,
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
              isTransitioning: false,
              universalItems: universalItems,
              catalogDetails: catalogDetails,
              manualDetails: manualDetails,
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
    String type = 'MANUAL',
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
          type: type,
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
  Future<void> changeTicketStatus({
    required String ticketId,
    required String newStatus,
    String? resolutionNote,
  }) async {
    try {
      await _remote.changeTicketStatus(
        ticketId: ticketId,
        newStatus: newStatus,
        resolutionNote: resolutionNote,
      );
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
  Future<void> changeDueTime({
    required String ticketId,
    required String hotelId,
    required int newDueAt,
    required String reason,
  }) async {
    try {
      await _remote.changeDueTime(
        ticketId: ticketId,
        hotelId: hotelId,
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
  Future<void> acknowledgeTicket({
    required String ticketId,
    required int dueAt,
    String? notes,
  }) async {
    try {
      await _remote.acknowledgeTicket(
        ticketId: ticketId,
        dueAt: dueAt,
        notes: notes,
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<void> acknowledgeAndStartTicket({
    required String ticketId,
    required int dueAt,
    String? notes,
  }) async {
    try {
      await _remote.acknowledgeAndStartTicket(
        ticketId: ticketId,
        dueAt: dueAt,
        notes: notes,
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  // ─── Tickets V2 implementations ─────────────────────────────────────

  TicketsPageResult _mapTicketsPageDto(TicketsPageDto dto) {
    final names = <String, String>{};
    final items = dto.items.map((d) {
      final dept = d.department;
      final deptId = (dept?['id'] as String?) ??
          (dept?['department_id'] as String?) ??
          '';
      final deptName = (dept?['name'] as String?) ?? '';
      final deptCode = (dept?['code'] as String?) ?? '';
      final deptMobileIcon = (dept?['mobile_icon'] as String?) ?? '';
      final deptIcon = dept?['icon'] as Map?;
      final deptIconUrl = (deptIcon?['url'] as String?) ?? '';
      if (deptId.isNotEmpty && deptName.isNotEmpty) names[d.id] = deptName;
      final roomData = d.roomData;
      final roomDetails = roomData != null
          ? RoomDetails(
              id: (roomData['id'] as String?) ?? '',
              onbRoomNumber: (roomData['onb_room_number'] as String?) ?? '',
              floorId: (roomData['floor_id'] as String?) ?? '',
              onbRoomTypeId: (roomData['onb_room_type_id'] as String?) ?? '',
            )
          : null;
      final universalItems = d.universalDetails
          .map((u) => UniversalTicketItem(
                id: u.id,
                item: u.item,
                emoji: u.emoji,
                thumbnailUrl: u.thumbnailUrl,
                nameI18n: u.nameI18n,
                etaStart: u.etaStart,
                etaEnd: u.etaEnd,
                slaTargetMinutes: u.slaTargetMinutes,
              ))
          .toList(growable: false);
      final catalogDetails = d.catalogDetails == null
          ? null
          : CatalogTicketDetails(
              catalogName: d.catalogDetails!.catalogName,
              logoUrl: d.catalogDetails!.logoUrl,
              brandColorHex: d.catalogDetails!.brandColorHex,
              grandTotal: d.catalogDetails!.grandTotal,
              currency: d.catalogDetails!.currency,
              slaTargetMinutes: d.catalogDetails!.slaTargetMinutes,
              items: d.catalogDetails!.items
                  .map((i) => CatalogTicketItem(
                        itemName: i.itemName,
                        imageUrl: i.imageUrl,
                      ))
                  .toList(growable: false),
            );
      final manualDetails = d.manualDetails == null
          ? null
          : ManualTicketDetails(
              summary: d.manualDetails!.summary,
              details: d.manualDetails!.details,
            );
      return MyTicket(
        id: d.id,
        opsTicketId: d.opsTicketId,
        createdAt: d.createdAt,
        updatedAt: d.updatedAt,
        lastTransitionAt: d.lastTransitionAt,
        slaBreached: d.slaBreached,
        overdue: d.overdue,
        needsAttention: d.needsAttention,
        hotelId: d.hotelId,
        departmentId: deptId,
        departmentName: deptName.isEmpty ? null : deptName,
        departmentMobileIcon: deptMobileIcon.isEmpty ? null : deptMobileIcon,
        departmentIconUrl: deptIconUrl.isEmpty ? null : deptIconUrl,
        departmentCode: deptCode.isEmpty ? null : deptCode,
        assignedToUserId: d.assignedToUserId,
        createdByUserId: d.createdByUserId,
        createdByAi: d.createdByAi,
        type: d.type,
        ticketType: d.ticketType,
        status: d.status,
        dueAt: d.dueAt,
        dueAtWithGrace: d.dueAtWithGrace,
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
        isTransitioning: false,
        universalItems: universalItems,
        catalogDetails: catalogDetails,
        manualDetails: manualDetails,
      );
    }).toList(growable: false);
    return TicketsPageResult(
      items: items,
      curPage: dto.curPage,
      nextPage: dto.nextPage,
      itemsTotal: dto.itemsTotal,
      departmentNameById: names,
    );
  }

  @override
  Future<TicketsPageResult> fetchTicketsV2Page({
    required TicketsV2Tab tab,
    required String hotelId,
    required int page,
    required int perPage,
    String? departmentId,
    String? source,
    String? ticketType,
    int? createdAtStartDate,
    int? createdAtEndDate,
  }) async {
    try {
      final TicketsPageDto dto;
      switch (tab) {
        case TicketsV2Tab.incoming:
          dto = await _remote.getTicketsV2New(
            hotelId: hotelId,
            page: page,
            perPage: perPage,
            departmentId: departmentId,
            source: source,
            ticketType: ticketType,
            createdAtStartDate: createdAtStartDate,
            createdAtEndDate: createdAtEndDate,
          );
          break;
        case TicketsV2Tab.backlog:
          dto = await _remote.getTicketsV2Backlog(
            hotelId: hotelId,
            page: page,
            perPage: perPage,
            departmentId: departmentId,
            source: source,
            ticketType: ticketType,
            createdAtStartDate: createdAtStartDate,
            createdAtEndDate: createdAtEndDate,
          );
          break;
        case TicketsV2Tab.inProgress:
          dto = await _remote.getTicketsV2InProgress(
            hotelId: hotelId,
            page: page,
            perPage: perPage,
            departmentId: departmentId,
            source: source,
            ticketType: ticketType,
            createdAtStartDate: createdAtStartDate,
            createdAtEndDate: createdAtEndDate,
          );
          break;
        case TicketsV2Tab.doneToday:
          dto = await _remote.getTicketsV2DoneToday(
            hotelId: hotelId,
            page: page,
            perPage: perPage,
            departmentId: departmentId,
            source: source,
            ticketType: ticketType,
            createdAtStartDate: createdAtStartDate,
            createdAtEndDate: createdAtEndDate,
          );
          break;
        case TicketsV2Tab.doneHistory:
          dto = await _remote.getTicketsV2DoneHistory(
            hotelId: hotelId,
            page: page,
            perPage: perPage,
            departmentId: departmentId,
            source: source,
            ticketType: ticketType,
            createdAtStartDate: createdAtStartDate,
            createdAtEndDate: createdAtEndDate,
          );
          break;
      }
      return _mapTicketsPageDto(dto);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<void> startTicketV2({
    required String ticketId,
    required DateTime dueAt,
  }) async {
    try {
      await _remote.startTicketV2(ticketId: ticketId, dueAt: dueAt);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<void> completeTicketV2({
    required String ticketId,
    String? resolutionNote,
  }) async {
    try {
      await _remote.completeTicketV2(
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
  Future<void> moveToBacklogV2({
    required String ticketId,
    required String reason,
  }) async {
    try {
      await _remote.moveToBacklogV2(
        ticketId: ticketId,
        reason: reason,
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<void> addTimeV2({
    required String ticketId,
    required String reason,
    int? extensionMinutes,
  }) async {
    try {
      await _remote.addTimeV2(
        ticketId: ticketId,
        reason: reason,
        extensionMinutes: extensionMinutes,
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<void> resetAcknowledgeV2({
    required String ticketId,
    required String reason,
  }) async {
    try {
      await _remote.resetAcknowledgeV2(
        ticketId: ticketId,
        reason: reason,
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<void> cancelTicketV2({
    required String ticketId,
    required String reason,
  }) async {
    try {
      await _remote.cancelTicketV2(
        ticketId: ticketId,
        reason: reason,
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
