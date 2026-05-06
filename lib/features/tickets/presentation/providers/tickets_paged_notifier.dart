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
enum TicketsTab { incoming, today, scheduled, done }

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

  const TicketsPagedSpec({
    required this.statuses,
    this.localPredicate,
    this.perPage = 10,
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
    if (hotelId == null) {
      return const TicketsPageState();
    }

    return _fetchPage(page: 1, hotelId: hotelId);
  }

  String? _hotelId() {
    final bootstrap = ref
        .read(dashboardBootstrapControllerProvider)
        .valueOrNull;
    final id = bootstrap?.userProfile?.hotelDetails.hotel.id;
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
      state = AsyncData(current.copyWith(items: next));
      return;
    }

    final isBrandNew = existingIndex < 0;
    List<MyTicket> nextItems;
    if (isBrandNew) {
      nextItems = current.sortOrder == TicketsSortOrder.newestFirst
          ? [ticket, ...current.items]
          : [...current.items, ticket];
    } else {
      nextItems = [...current.items];
      nextItems[existingIndex] = ticket;
      nextItems = _sort(nextItems, current.sortOrder);
    }

    final nextFresh = isBrandNew
        ? {...current.freshlyArrivedIds, ticket.id}
        : current.freshlyArrivedIds;

    state = AsyncData(
      current.copyWith(items: nextItems, freshlyArrivedIds: nextFresh),
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
    state = AsyncData(
      current.copyWith(
        items: current.items.where((t) => t.id != ticketId).toList(),
        freshlyArrivedIds: nextFresh,
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
}

// ──────────────────────────────────────────────────────────────────────
// Specs + providers per tab
// ──────────────────────────────────────────────────────────────────────

bool _isToday(int epochMs) {
  if (epochMs <= 0) return false;
  final dt = DateTime.fromMillisecondsSinceEpoch(epochMs).toLocal();
  final now = DateTime.now();
  return dt.year == now.year && dt.month == now.month && dt.day == now.day;
}

const _kIncomingSpec = TicketsPagedSpec(statuses: ['NEW']);

final TicketsPagedSpec _kTodaySpec = TicketsPagedSpec(
  statuses: const ['ACCEPTED', 'IN_PROGRESS', 'ON_HOLD'],
  localPredicate: (t) {
    // Today = created today AND last transition today.
    return _isToday(t.createdAt) &&
        _isToday(t.lastTransitionAt > 0 ? t.lastTransitionAt : t.createdAt);
  },
);

const _kScheduledSpec = TicketsPagedSpec(statuses: ['ON_HOLD']);

const _kDoneSpec = TicketsPagedSpec(statuses: ['DONE']);

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
    case TicketsTab.scheduled:
      return _kScheduledSpec;
    case TicketsTab.done:
      return _kDoneSpec;
  }
}

/// All four specs — used by the realtime listener to broadcast events
/// into every paged provider that's currently alive.
const List<TicketsTab> kAllTicketsTabs = TicketsTab.values;
