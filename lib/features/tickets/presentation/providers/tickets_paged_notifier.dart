// ─── V2 TICKETS PAGED NOTIFIER (2026-05-14) ──────────────────────
// Implements the ticketsv2 5-tab model with dedicated paged providers
// per tab: incoming, todayInProgress, todayDone, backlog, doneHistory.
// Replaces legacy v1 single-list model with local status bucketing.
// See internal LEGACY-V1 markers for removed v1 code paths.
// ─────────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dashboard/presentation/providers/dashboard_bootstrap_controller.dart';
import '../../data/repositories/ticket_repository.dart';
import '../../domain/entities/my_ticket.dart';
import 'session_providers.dart';

/// Sort direction for the ticket list. Newest-first is the default; the
/// "Oldest" filter chip flips this to oldest-first.
enum TicketsSortOrder { newestFirst, oldestFirst }

/// Identifier for one of the five logical ticket lists (v2). Used by the
/// realtime listener to pick which provider to push events into.
///
/// ─── LEGACY-V1 (2026-05-14) ──────────────────────────────────────
/// Replaced by ticketsv2 5-tab model. Kept for reference.
/// Old enum: enum TicketsTab { incoming, today, backlog, done }
/// ─────────────────────────────────────────────────────────────────
enum TicketsTab { incoming, todayInProgress, overdue, todayDone, backlog, doneHistory }

/// Configuration for a paged ticket list — turns each tab into a
/// declarative spec the notifier uses to call the API and decide whether
/// realtime events match.
@immutable
class TicketsPagedSpec {
  /// Which v2 list endpoint this spec maps to.
  final TicketsTab tab;

  /// Items per page on this tab. Mobile default is 10.
  final int perPage;

  // NEW SERVER-SIDE FILTERING PARAMETERS
  /// Server-side department filter.
  final String? departmentId;

  /// Server-side created_at start date filter (epoch ms).
  final int? createdAtStartDate;

  /// Server-side created_at end date filter (epoch ms).
  final int? createdAtEndDate;

  /// Server-side ticket_type filter.
  final String? ticketType;

  // ─── LEGACY-V1 (2026-05-14) ──────────────────────────────────────
  // Replaced by ticketsv2 5-tab model. Kept for reference.
  // final List<String> statuses;
  // final bool Function(MyTicket t)? localPredicate;
  // ─────────────────────────────────────────────────────────────────

  const TicketsPagedSpec({
    required this.tab,
    this.perPage = 10,
    this.departmentId,
    this.createdAtStartDate,
    this.createdAtEndDate,
    this.ticketType,
  });

  /// V2 endpoint tab this spec drives.
  TicketsV2Tab get v2Tab {
    switch (tab) {
      case TicketsTab.incoming:
        return TicketsV2Tab.incoming;
      case TicketsTab.todayInProgress:
        return TicketsV2Tab.inProgress;
      case TicketsTab.overdue:
        // Overdue uses same endpoint as inProgress, filtered client-side
        return TicketsV2Tab.inProgress;
      case TicketsTab.todayDone:
        return TicketsV2Tab.doneToday;
      case TicketsTab.backlog:
        return TicketsV2Tab.backlog;
      case TicketsTab.doneHistory:
        return TicketsV2Tab.doneHistory;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is TicketsPagedSpec &&
      other.tab == tab &&
      other.perPage == perPage &&
      other.departmentId == departmentId &&
      other.createdAtStartDate == createdAtStartDate &&
      other.createdAtEndDate == createdAtEndDate &&
      other.ticketType == ticketType;

  @override
  int get hashCode => Object.hash(
    tab,
    perPage,
    departmentId,
    createdAtStartDate,
    createdAtEndDate,
    ticketType,
  );
}

/// State for a paged ticket list. Carries the loaded items in their
/// current sort order plus pagination + loading flags.
@immutable
class TicketsPageState {
  final List<MyTicket> items;
  final int? nextPage;

  /// Total number of tickets matching the filter on the server. May be
  /// 0 before the first page lands.
  final int itemsTotal;
  final bool isLoadingMore;
  final TicketsSortOrder sortOrder;

  /// Tickets that arrived via realtime within the last few seconds.
  /// Drives the slide-in / flash animation on the card.
  final Set<String> freshlyArrivedIds;

  const TicketsPageState({
    this.items = const [],
    this.nextPage = 1,
    this.itemsTotal = 0,
    this.isLoadingMore = false,
    this.sortOrder = TicketsSortOrder.newestFirst,
    this.freshlyArrivedIds = const {},
  });

  bool get hasMore => nextPage != null;

  TicketsPageState copyWith({
    List<MyTicket>? items,
    int? nextPage,
    bool clearNextPage = false,
    int? itemsTotal,
    bool? isLoadingMore,
    TicketsSortOrder? sortOrder,
    Set<String>? freshlyArrivedIds,
  }) {
    return TicketsPageState(
      items: items ?? this.items,
      nextPage: clearNextPage ? null : (nextPage ?? this.nextPage),
      itemsTotal: itemsTotal ?? this.itemsTotal,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      sortOrder: sortOrder ?? this.sortOrder,
      freshlyArrivedIds: freshlyArrivedIds ?? this.freshlyArrivedIds,
    );
  }
}

/// Generic paged ticket list, parameterised by [TicketsPagedSpec].
class TicketsPagedNotifier
    extends FamilyAsyncNotifier<TicketsPageState, TicketsPagedSpec> {
  late TicketRepository _repo;
  late TicketsPagedSpec _spec;

  @override
  Future<TicketsPageState> build(TicketsPagedSpec arg) async {
    _spec = arg;
    _repo = ref.read(ticketRepositoryProvider);

    final hotelId = _hotelId();
    debugPrint(
      '[TicketsPagedNotifier] build: hotelId=$hotelId, tab=${_spec.tab}',
    );
    if (hotelId == null) {
      debugPrint(
        '[TicketsPagedNotifier] build: No hotelId, returning empty state',
      );
      return const TicketsPageState();
    }

    return _fetchPage(page: 1, hotelId: hotelId);
  }

  String? _hotelId() {
    final bootstrap = ref
        .read(dashboardBootstrapControllerProvider)
        .valueOrNull;
    final id = bootstrap?.userProfile?.hotelDetails.hotel.id;
    debugPrint(
      '[TicketsPagedNotifier] _hotelId: bootstrap=${bootstrap != null}, id=$id',
    );
    if (id == null || id.isEmpty) return null;
    return id;
  }

  Future<TicketsPageState> _fetchPage({
    required int page,
    required String hotelId,
  }) async {
    debugPrint(
      '[TicketsPagedNotifier] _fetchPage: tab=${_spec.tab} '
      'departmentId=${_spec.departmentId} page=$page',
    );
    final res = await _repo.fetchTicketsV2Page(
      tab: _spec.v2Tab,
      hotelId: hotelId,
      page: page,
      perPage: _spec.perPage,
      departmentId: _spec.departmentId,
      ticketType: _spec.ticketType,
      createdAtStartDate: _spec.createdAtStartDate,
      createdAtEndDate: _spec.createdAtEndDate,
    );
    debugPrint(
      '[TicketsPagedNotifier] _fetchPage: tab=${_spec.tab} '
      'departmentId=${_spec.departmentId} page=$page got=${res.items.length} total=${res.itemsTotal} '
      'nextPage=${res.nextPage}',
    );
    final current = state.valueOrNull;
    final merged = page == 1
        ? res.items
        : _mergeUniqueById(current?.items ?? const [], res.items);
    final sorted = _sort(
      merged,
      current?.sortOrder ?? TicketsSortOrder.newestFirst,
    );
    return TicketsPageState(
      items: sorted,
      nextPage: res.nextPage,
      itemsTotal: res.itemsTotal,
      isLoadingMore: false,
      sortOrder: current?.sortOrder ?? TicketsSortOrder.newestFirst,
      freshlyArrivedIds: current?.freshlyArrivedIds ?? const {},
    );
  }

  /// Force-refetch from page 1. Discards any in-memory pages and resets
  /// pagination — used for pull-to-refresh and on Today tab activation.
  Future<void> refresh() async {
    final hotelId = _hotelId();
    if (hotelId == null) return;
    state = const AsyncLoading<TicketsPageState>().copyWithPrevious(state);
    state = await AsyncValue.guard(() => _fetchPage(page: 1, hotelId: hotelId));
  }

  /// Load the next page. No-op if already loading or no more pages.
  Future<void> loadNextPage() async {
    final current = state.valueOrNull;
    if (current == null) return;
    if (current.isLoadingMore || !current.hasMore) return;
    final hotelId = _hotelId();
    if (hotelId == null) return;
    final page = current.nextPage!;
    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final next = await _fetchPage(page: page, hotelId: hotelId);
      state = AsyncData(next);
    } catch (e, st) {
      debugPrint('[TicketsPagedNotifier] loadNextPage error: $e');
      state = AsyncError<TicketsPageState>(
        e,
        st,
      ).copyWithPrevious(AsyncData(current.copyWith(isLoadingMore: false)));
    }
  }

  Future<void> setSortOrder(TicketsSortOrder order) async {
    final current = state.valueOrNull;
    if (current == null) return;
    if (current.sortOrder == order) return;
    await Future.microtask(() {});
    state = AsyncData(
      current.copyWith(sortOrder: order, items: _sort(current.items, order)),
    );
  }

  /// Apply a realtime upsert respecting this provider's v2 tab membership.
  ///
  /// Membership rules (per v2 5-tab model):
  ///   - incoming: status == 'NEW'
  ///   - todayInProgress: status == 'IN_PROGRESS'
  ///   - todayDone: status == 'DONE' AND completed today
  ///   - backlog: server-owned. NEVER add via realtime; the listener
  ///     will trigger a refetch separately.
  ///   - doneHistory: status == 'DONE' (cumulative)
  void applyRealtimeUpsert(MyTicket ticket) {
    final current = state.valueOrNull;
    if (current == null) return;

    // Backlog tab is server-owned; we cannot infer membership locally.
    // The realtime listener invalidates this provider on its own.
    if (_spec.tab == TicketsTab.backlog) return;

    final matches = _matchesFilter(ticket);
    final existingIndex = current.items.indexWhere((t) => t.id == ticket.id);

    if (!matches) {
      if (existingIndex < 0) return;
      final next = [...current.items]..removeAt(existingIndex);
      final newTotal = (current.itemsTotal > 0)
          ? current.itemsTotal - 1
          : current.itemsTotal - 1;
      state = AsyncData(current.copyWith(items: next, itemsTotal: newTotal));
      return;
    }

    final isBrandNew = existingIndex < 0;
    List<MyTicket> nextItems;
    int newItemsTotal = current.itemsTotal;

    if (isBrandNew) {
      nextItems = current.sortOrder == TicketsSortOrder.newestFirst
          ? [ticket, ...current.items]
          : [...current.items, ticket];
      newItemsTotal = current.itemsTotal + 1;
    } else {
      nextItems = [...current.items];
      final updatedTicket = ticket.copyWith(isTransitioning: false);
      nextItems[existingIndex] = updatedTicket;
      nextItems = _sort(nextItems, current.sortOrder);
    }

    final nextFresh = isBrandNew
        ? {...current.freshlyArrivedIds, ticket.id}
        : current.freshlyArrivedIds;

    state = AsyncData(
      current.copyWith(
        items: nextItems,
        freshlyArrivedIds: nextFresh,
        itemsTotal: newItemsTotal,
      ),
    );

    if (isBrandNew) _scheduleFreshClear(ticket.id);
  }

  void applyRealtimeDelete(String ticketId) {
    final current = state.valueOrNull;
    if (current == null) return;
    if (!current.items.any((t) => t.id == ticketId)) return;

    final nextFresh = current.freshlyArrivedIds.contains(ticketId)
        ? ({...current.freshlyArrivedIds}..remove(ticketId))
        : current.freshlyArrivedIds;

    final newTotal = (current.itemsTotal > 0)
        ? current.itemsTotal - 1
        : current.itemsTotal - 1;

    state = AsyncData(
      current.copyWith(
        items: current.items.where((t) => t.id != ticketId).toList(),
        freshlyArrivedIds: nextFresh,
        itemsTotal: newTotal,
      ),
    );
  }

  bool _matchesFilter(MyTicket t) {
    final status = t.status.toUpperCase();
    switch (_spec.tab) {
      case TicketsTab.incoming:
        return status == 'NEW';
      case TicketsTab.todayInProgress:
        // Fetch ALL IN_PROGRESS tickets (both active and overdue)
        // Active/Overdue filtering happens client-side via _applyTodaySubFilter
        return status == 'IN_PROGRESS';
      case TicketsTab.overdue:
        // Overdue filter for realtime updates - matches overdue IN_PROGRESS
        return status == 'IN_PROGRESS' && t.isOverdue;
      case TicketsTab.todayDone:
        return status == 'DONE' && _isDoneToday(t);
      case TicketsTab.backlog:
        // Server-curated — never matches locally.
        return false;
      case TicketsTab.doneHistory:
        return status == 'DONE';
    }
  }

  List<MyTicket> _mergeUniqueById(
    List<MyTicket> existing,
    List<MyTicket> next,
  ) {
    final seen = <String>{for (final t in existing) t.id};
    final merged = [...existing];
    for (final t in next) {
      if (seen.add(t.id)) merged.add(t);
    }
    return merged;
  }

  List<MyTicket> _sort(List<MyTicket> items, TicketsSortOrder order) {
    final out = [...items];
    out.sort((a, b) {
      final aTs = defaultStatusChangedAt(a);
      final bTs = defaultStatusChangedAt(b);
      return order == TicketsSortOrder.newestFirst
          ? bTs.compareTo(aTs)
          : aTs.compareTo(bTs);
    });
    return out;
  }

  void _scheduleFreshClear(String ticketId) {
    Future<void>.delayed(const Duration(seconds: 3), () {
      try {
        final s = state.valueOrNull;
        if (s == null || !s.freshlyArrivedIds.contains(ticketId)) return;
        final next = {...s.freshlyArrivedIds}..remove(ticketId);
        state = AsyncData(s.copyWith(freshlyArrivedIds: next));
      } catch (_) {
        // Notifier disposed — ignore.
      }
    });
  }

  void markTicketTransitioning(String ticketId) {
    final current = state.valueOrNull;
    if (current == null) return;

    final index = current.items.indexWhere((t) => t.id == ticketId);
    if (index < 0) return;

    final updatedTicket = current.items[index].copyWith(isTransitioning: true);
    final updatedItems = [...current.items];
    updatedItems[index] = updatedTicket;

    state = AsyncData(current.copyWith(items: updatedItems));
  }

  void updateTicketStatusImmediate(String ticketId, String newStatus) {
    final current = state.valueOrNull;
    if (current == null) return;

    final index = current.items.indexWhere((t) => t.id == ticketId);
    if (index < 0) return;

    final ticket = current.items[index];
    final updatedTicket = ticket.copyWith(
      status: newStatus,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
      lastTransitionAt: DateTime.now().millisecondsSinceEpoch,
      isTransitioning: true,
    );

    final matchesFilter = _matchesFilter(updatedTicket);

    if (!matchesFilter) {
      final nextItems = [...current.items]..removeAt(index);
      final newTotal = (current.itemsTotal > 0)
          ? current.itemsTotal - 1
          : current.itemsTotal - 1;
      state = AsyncData(
        current.copyWith(items: nextItems, itemsTotal: newTotal),
      );
    } else {
      final updatedItems = [...current.items];
      updatedItems[index] = updatedTicket;
      state = AsyncData(current.copyWith(items: updatedItems));
    }
  }

  void updateTabCountImmediate({required int delta}) {
    final current = state.valueOrNull;
    if (current == null) return;

    final newTotal = (current.itemsTotal + delta)
        .clamp(0, double.infinity)
        .toInt();
    state = AsyncData(current.copyWith(itemsTotal: newTotal));
  }
}

// ──────────────────────────────────────────────────────────────────────
// Specs + providers per tab
// ──────────────────────────────────────────────────────────────────────

// ─── LEGACY-V1 (2026-05-14) ──────────────────────────────────────
// Replaced by ticketsv2 5-tab model. Kept for reference.
// const _kIncomingSpec = TicketsPagedSpec(statuses: ['NEW']);
// final _kTodaySpec = TicketsPagedSpec(
//   statuses: const ['ACCEPTED', 'IN_PROGRESS'],
//   localPredicate: _isTransitionedToday,
// );
// final _kBacklogSpec = TicketsPagedSpec(
//   statuses: const ['ACCEPTED', 'IN_PROGRESS'],
//   localPredicate: _isNotTransitionedToday,
// );
// final _kDoneSpec = TicketsPagedSpec(
//   statuses: const ['DONE'],
//   localPredicate: _isDoneToday,
// );
// bool _isTransitionedToday(MyTicket t) =>
//     _isSameLocalDay(t.dueAt, DateTime.now());
// bool _isNotTransitionedToday(MyTicket t) => !_isTransitionedToday(t);
// ─────────────────────────────────────────────────────────────────

const _kIncomingSpec = TicketsPagedSpec(tab: TicketsTab.incoming);
const _kTodayInProgressSpec = TicketsPagedSpec(tab: TicketsTab.todayInProgress);
const _kOverdueSpec = TicketsPagedSpec(tab: TicketsTab.overdue);
const _kTodayDoneSpec = TicketsPagedSpec(tab: TicketsTab.todayDone);
const _kBacklogSpec = TicketsPagedSpec(tab: TicketsTab.backlog);
const _kDoneHistorySpec = TicketsPagedSpec(tab: TicketsTab.doneHistory);

/// Bucket predicate: ticket's timestamp falls on today's local calendar.
bool _isSameLocalDay(int epochMs, DateTime now) {
  if (epochMs <= 0) return false;
  final dt = DateTime.fromMillisecondsSinceEpoch(epochMs).toLocal();
  return dt.year == now.year && dt.month == now.month && dt.day == now.day;
}

/// True when [t] is a DONE ticket and was completed (confirmed) today.
/// Uses `confirmedAt` when available, falls back to `lastTransitionAt`
/// or `acknowledgedAt` to determine the completion timestamp.
/// Used for todayDone realtime routing.
bool _isDoneToday(MyTicket t) {
  if (!t.isDone) return false;
  final completedAt = t.confirmedAt > 0
      ? t.confirmedAt
      : (t.lastTransitionAt > 0 ? t.lastTransitionAt : t.acknowledgedAt);
  return _isSameLocalDay(completedAt, DateTime.now());
}

/// AsyncNotifier provider, parameterised by spec.
final ticketsPagedProvider =
    AsyncNotifierProvider.family<
      TicketsPagedNotifier,
      TicketsPageState,
      TicketsPagedSpec
    >(TicketsPagedNotifier.new);

/// Tab → spec used to look up the provider in the screen and listener.
TicketsPagedSpec specForTab(TicketsTab tab) {
  switch (tab) {
    case TicketsTab.incoming:
      return _kIncomingSpec;
    case TicketsTab.todayInProgress:
      return _kTodayInProgressSpec;
    case TicketsTab.overdue:
      return _kOverdueSpec;
    case TicketsTab.todayDone:
      return _kTodayDoneSpec;
    case TicketsTab.backlog:
      return _kBacklogSpec;
    case TicketsTab.doneHistory:
      return _kDoneHistorySpec;
  }
}

/// All v2 tabs — used by the realtime listener to broadcast events
/// into every paged provider that's currently alive.
const List<TicketsTab> kAllTicketsTabs = TicketsTab.values;

/// Creates a [TicketsPagedSpec] for the given tab with the department filter
/// applied from [departmentFilterProvider]. This ensures API requests include
/// Builds the API spec for each tab, applying the advanced filter
/// (Department + Sort + Type) from [resolvedTicketsFilterProvider].
final ticketsPagedSpecProvider = Provider.family<TicketsPagedSpec, TicketsTab>((
  ref,
  tab,
) {
  final baseSpec = specForTab(tab);
  final filter = ref.watch(resolvedTicketsFilterProvider);
  final allDeptIds = ref.watch(userAccessDepartmentsProvider).map((d) => d.id).toSet();

  // Pass a departmentId only when exactly 1 dept is selected and it's a
  // subset of the user's allowed depts. If all or none are selected the API
  // returns all depts (no filter needed).
  final String? departmentId;
  if (filter.departmentIds.length == 1) {
    departmentId = filter.departmentIds.first;
  } else if (filter.departmentIds.isNotEmpty &&
      filter.departmentIds.length < allDeptIds.length) {
    // Multiple but not all — API limitation: send first selected.
    departmentId = filter.departmentIds.first;
  } else {
    departmentId = null;
  }

  // Pass ticketType only when a single type is selected.
  final String? ticketType;
  if (filter.ticketTypes.length == 1) {
    ticketType = filter.ticketTypes.first;
  } else {
    ticketType = null;
  }

  debugPrint(
    '[ticketsPagedSpecProvider] tab=$tab '
    'deptIds=${filter.departmentIds} allDeptIds=$allDeptIds '
    '→ departmentId=$departmentId ticketType=$ticketType',
  );

  return TicketsPagedSpec(
    tab: baseSpec.tab,
    perPage: baseSpec.perPage,
    departmentId: departmentId,
    createdAtStartDate: baseSpec.createdAtStartDate,
    createdAtEndDate: baseSpec.createdAtEndDate,
    ticketType: ticketType,
  );
});
