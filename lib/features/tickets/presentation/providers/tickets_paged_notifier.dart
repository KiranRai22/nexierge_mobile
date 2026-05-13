import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dashboard/presentation/providers/dashboard_bootstrap_controller.dart';
import '../../data/repositories/ticket_repository.dart';
import '../../domain/entities/my_ticket.dart';

/// Sort direction for the ticket list. Newest-first is the default; the
/// "Oldest" filter chip flips this to oldest-first.
enum TicketsSortOrder { newestFirst, oldestFirst }

/// Identifier for one of the four logical ticket lists. Used by the
/// realtime listener to pick which provider to push events into.
enum TicketsTab { incoming, today, backlog, done }

/// Configuration for a paged ticket list — turns each tab into a
/// declarative spec the notifier uses to call the API and decide whether
/// realtime events match.
@immutable
class TicketsPagedSpec {
  /// Server-side `status[]=` filter values.
  final List<String> statuses;

  /// Optional in-memory predicate applied after fetch and on realtime
  /// upserts. Today tab uses this to require created_at AND
  /// last_transition_at to fall within today.
  final bool Function(MyTicket t)? localPredicate;

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

  const TicketsPagedSpec({
    required this.statuses,
    this.localPredicate,
    this.perPage = 10,
    this.departmentId,
    this.createdAtStartDate,
    this.createdAtEndDate,
    this.ticketType,
  });
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
///
/// Page 1 is loaded eagerly when the hotel id becomes available. The
/// notifier exposes [loadNextPage], [refresh], and [applyRealtimeUpsert]
/// for the realtime listener to call.
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
      '[TicketsPagedNotifier] build: hotelId=$hotelId, spec=${_spec.statuses}',
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
    final res = await _repo.fetchTicketsPage(
      hotelId: hotelId,
      statuses: _spec.statuses,
      page: page,
      perPage: _spec.perPage,
      departmentId: _spec.departmentId,
      createdAtStartDate: _spec.createdAtStartDate,
      createdAtEndDate: _spec.createdAtEndDate,
      ticketType: _spec.ticketType,
    );
    final filtered = _spec.localPredicate == null
        ? res.items
        : res.items.where(_spec.localPredicate!).toList(growable: false);
    final current = state.valueOrNull;
    final merged = page == 1
        ? filtered
        : _mergeUniqueById(current?.items ?? const [], filtered);
    final sorted = _sort(
      merged,
      current?.sortOrder ?? TicketsSortOrder.newestFirst,
    );
    // When client-side filtering is applied, use filtered count for itemsTotal
    // so the UI count matches the actual displayed items.
    final effectiveTotal = _spec.localPredicate != null && page == 1
        ? filtered.length
        : res.itemsTotal;
    return TicketsPageState(
      items: sorted,
      nextPage: res.nextPage,
      itemsTotal: effectiveTotal,
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

  /// Switch the sort order and re-sort in memory. Doesn't refetch — the
  /// next paged fetch will return server-sorted data anyway, and the
  /// merge keeps order consistent.
  Future<void> setSortOrder(TicketsSortOrder order) async {
    final current = state.valueOrNull;
    if (current == null) return;
    if (current.sortOrder == order) return;
    // Defer to avoid modifying state during build.
    await Future.microtask(() {});
    state = AsyncData(
      current.copyWith(sortOrder: order, items: _sort(current.items, order)),
    );
  }

  /// Apply a realtime upsert respecting this provider's filter and sort.
  ///
  /// - If the ticket no longer matches the filter (e.g. status moved on),
  ///   it is removed from the list.
  /// - If it matches and is already loaded, it is updated in place and
  ///   re-sorted.
  /// - If it matches and is new, it is inserted at the top (newest-first)
  ///   or bottom (oldest-first). The next paged fetch will re-sort.
  void applyRealtimeUpsert(MyTicket ticket) {
    final current = state.valueOrNull;
    if (current == null) return;

    final matches = _matchesFilter(ticket);
    final existingIndex = current.items.indexWhere((t) => t.id == ticket.id);

    if (!matches) {
      if (existingIndex < 0) return;
      final next = [...current.items]..removeAt(existingIndex);
      // Decrease itemsTotal since ticket no longer matches this tab's filter
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
      // Increase itemsTotal since this is a new ticket for this tab
      newItemsTotal = current.itemsTotal + 1;
    } else {
      nextItems = [...current.items];
      // Ensure transitioning state is cleared when socket confirmation arrives
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

  /// Apply a realtime delete — drops the ticket from the loaded items
  /// if present.
  void applyRealtimeDelete(String ticketId) {
    final current = state.valueOrNull;
    if (current == null) return;
    if (!current.items.any((t) => t.id == ticketId)) return;

    final nextFresh = current.freshlyArrivedIds.contains(ticketId)
        ? ({...current.freshlyArrivedIds}..remove(ticketId))
        : current.freshlyArrivedIds;

    // Decrease itemsTotal since ticket was deleted
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
    final statusOk = _spec.statuses.any(
      (s) => s.toUpperCase() == t.status.toUpperCase(),
    );
    if (!statusOk) return false;
    if (_spec.localPredicate == null) return true;
    return _spec.localPredicate!(t);
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

  /// Mark a ticket as transitioning (for shimmer effect)
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

  /// Update ticket status immediately (optimistic update)
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
      isTransitioning: true, // Keep shimmer effect until socket confirmation
    );

    // Check if ticket still matches this tab's filter
    final matchesFilter = _matchesFilter(updatedTicket);

    if (!matchesFilter) {
      // Ticket no longer belongs to this tab, remove it and update count
      final nextItems = [...current.items]..removeAt(index);
      final newTotal = (current.itemsTotal > 0)
          ? current.itemsTotal - 1
          : current.itemsTotal - 1;
      state = AsyncData(
        current.copyWith(items: nextItems, itemsTotal: newTotal),
      );
    } else {
      // Update ticket in place
      final updatedItems = [...current.items];
      updatedItems[index] = updatedTicket;
      state = AsyncData(current.copyWith(items: updatedItems));
    }
  }

  /// Update tab count immediately when ticket moves between tabs
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

const _kIncomingSpec = TicketsPagedSpec(statuses: ['NEW']);

/// Today server spec: status IN [ACCEPTED, IN_PROGRESS]. Date filtering is
/// applied client-side using `last_transition_at` semantics — see
/// `MyTicketsState._changedToday`. We deliberately don't filter by
/// `created_at` server-side since "today" means "something happened today
/// on this ticket", not "created today".
final _kTodaySpec = TicketsPagedSpec(
  statuses: const ['ACCEPTED', 'IN_PROGRESS'],
  localPredicate: _isTransitionedToday,
);

/// Backlog server spec: same statuses as Today (still active work) but the
/// inverse date predicate — `last_transition_at` is NOT today. Carryover
/// from previous days. Server-side same status filter; the date split is
/// purely client-side so a single `/get_my_tickets` page covers both tabs.
final _kBacklogSpec = TicketsPagedSpec(
  statuses: const ['ACCEPTED', 'IN_PROGRESS'],
  localPredicate: _isNotTransitionedToday,
);

/// Done server spec: status DONE with client-side date filter so only
/// tickets completed today are shown. Uses `confirmedAt` (when available)
/// or falls back to `lastTransitionAt` / `acknowledgedAt` to determine
/// the completion timestamp.
final _kDoneSpec = TicketsPagedSpec(
  statuses: const ['DONE'],
  localPredicate: _isDoneToday,
);

/// Bucket predicate: ticket's `due_at` falls on today's local calendar.
/// Mirrors [MyTicketsState._changedToday] so badge counts match paged list
/// contents. Tickets with no due_at (`dueAt == 0`) are never Today —
/// they fall into Backlog when active.
bool _isSameLocalDay(int epochMs, DateTime now) {
  if (epochMs <= 0) return false;
  final dt = DateTime.fromMillisecondsSinceEpoch(epochMs).toLocal();
  return dt.year == now.year && dt.month == now.month && dt.day == now.day;
}

bool _isTransitionedToday(MyTicket t) =>
    _isSameLocalDay(t.dueAt, DateTime.now());

bool _isNotTransitionedToday(MyTicket t) => !_isTransitionedToday(t);

/// True when [t] is a DONE ticket and was completed (confirmed) today.
/// Uses `confirmedAt` when available, falls back to `lastTransitionAt`
/// or `acknowledgedAt` to determine the completion timestamp.
bool _isDoneToday(MyTicket t) {
  if (!t.isDone) return false;
  final completedAt = t.confirmedAt > 0
      ? t.confirmedAt
      : (t.lastTransitionAt > 0 ? t.lastTransitionAt : t.acknowledgedAt);
  return _isSameLocalDay(completedAt, DateTime.now());
}

/// AsyncNotifier provider, parameterised by spec. Each tab uses its own
/// const spec so Riverpod gives back a stable instance.
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
    case TicketsTab.today:
      return _kTodaySpec;
    case TicketsTab.backlog:
      return _kBacklogSpec;
    case TicketsTab.done:
      return _kDoneSpec;
  }
}

/// All four specs — used by the realtime listener to broadcast events
/// into every paged provider that's currently alive.
const List<TicketsTab> kAllTicketsTabs = TicketsTab.values;
