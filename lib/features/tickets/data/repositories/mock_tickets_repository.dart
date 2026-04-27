import 'dart:async';

import '../../../activity/domain/models/activity_event.dart';
import '../../../activity/domain/repositories/activity_repository.dart';
import '../../domain/models/department.dart';
import '../../domain/models/ticket.dart';
import '../../domain/repositories/tickets_repository.dart';
import 'mock_seed.dart';

/// In-memory tickets store used until the real backend lands.
///
/// Also implements [ActivityRepository] so the activity feed reads from the
/// same source of truth without a separate seed. When the real backend
/// arrives this class is replaced by `RemoteTicketsRepository` and a
/// matching `RemoteActivityRepository` — UI screens are unchanged because
/// they only ever talk to the abstract interfaces.
class MockTicketsRepository
    implements TicketsRepository, ActivityRepository {
  MockTicketsRepository() {
    final seed = MockSeed.build();
    _tickets = [...seed.tickets];
    _events = [...seed.events];
    _emitTickets();
    _emitActivity();
  }

  late List<Ticket> _tickets;
  late List<ActivityEvent> _events;

  final _ticketsCtl = StreamController<List<Ticket>>.broadcast();
  final _activityCtl = StreamController<List<ActivityEvent>>.broadcast();
  final Map<String, StreamController<Ticket?>> _detailCtls = {};

  // ---------------------------------------------------------------------------
  // TicketsRepository
  // ---------------------------------------------------------------------------

  @override
  Stream<List<Ticket>> watchAll() {
    // Replay current snapshot to new subscribers immediately.
    return _ticketsCtl.stream
        .transform(_StartWith<List<Ticket>>(_sortedTickets()));
  }

  @override
  Stream<Ticket?> watch(String id) {
    final ctl = _detailCtls.putIfAbsent(
      id,
      () => StreamController<Ticket?>.broadcast(),
    );
    return ctl.stream.transform(_StartWith<Ticket?>(_findOrNull(id)));
  }

  @override
  List<Ticket> snapshot() => List.unmodifiable(_sortedTickets());

  @override
  List<Room> rooms() => MockSeed.rooms;

  @override
  Future<Ticket> create(NewTicketDraft draft) async {
    await _simulateLatency();
    final now = DateTime.now();
    final code = _nextCode();
    final id = 't${now.microsecondsSinceEpoch}';
    final ticket = Ticket(
      id: id,
      code: code,
      title: draft.title,
      kind: draft.kind,
      status: TicketStatus.incoming,
      department: draft.department,
      room: MockSeed.rooms.firstWhere((r) => r.id == draft.roomId),
      items: draft.items,
      note: draft.note,
      createdAt: now,
    );
    _tickets.add(ticket);
    _emitTickets();
    _pushEvent(_eventFromCreate(ticket));
    _emitDetail(ticket.id);
    return ticket;
  }

  @override
  Future<void> accept(String id, {required Duration etaIn}) async {
    await _simulateLatency();
    final now = DateTime.now();
    _mutate(id, (t) => t.copyWith(
          status: TicketStatus.inProgress,
          acceptedAt: now,
          eta: now.add(etaIn),
          assigneeName: 'You',
        ));
    final t = _findOrNull(id);
    if (t != null) {
      _pushEvent(_eventFromAccept(t, etaIn));
    }
  }

  @override
  Future<void> markDone(String id) async {
    await _simulateLatency();
    final now = DateTime.now();
    _mutate(id, (t) => t.copyWith(status: TicketStatus.done, doneAt: now));
    final t = _findOrNull(id);
    if (t != null) _pushEvent(_eventFromDone(t));
  }

  @override
  Future<void> cancel(String id) async {
    await _simulateLatency();
    _mutate(id, (t) => t.copyWith(status: TicketStatus.cancelled));
    final t = _findOrNull(id);
    if (t != null) _pushEvent(_eventFromCancel(t));
  }

  @override
  Future<void> changeDepartment(String id, Department newDept) async {
    await _simulateLatency();
    _mutate(id, (t) => t.copyWith(department: newDept));
    final t = _findOrNull(id);
    if (t != null) _pushEvent(_eventFromReassign(t, newDept));
  }

  @override
  Future<void> addNote(String id, String note) async {
    await _simulateLatency();
    _mutate(id, (t) => t.copyWith(note: note));
    final t = _findOrNull(id);
    if (t != null) _pushEvent(_eventFromNote(t, note));
  }

  @override
  Future<void> remove(String id) async {
    _tickets.removeWhere((t) => t.id == id);
    _events.removeWhere((e) => e.ticketId == id);
    _emitTickets();
    _emitActivity();
    _emitDetail(id);
  }

  // ---------------------------------------------------------------------------
  // ActivityRepository
  // ---------------------------------------------------------------------------

  @override
  Stream<List<ActivityEvent>> watchEvents() => _activityCtl.stream
      .transform(_StartWith<List<ActivityEvent>>(_sortedEvents()));

  @override
  List<ActivityEvent> eventsSnapshot() =>
      List.unmodifiable(_sortedEvents());

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  Future<void> _simulateLatency() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
  }

  void _mutate(String id, Ticket Function(Ticket) update) {
    final idx = _tickets.indexWhere((t) => t.id == id);
    if (idx == -1) return;
    _tickets[idx] = update(_tickets[idx]);
    _emitTickets();
    _emitDetail(id);
  }

  Ticket? _findOrNull(String id) =>
      _tickets.cast<Ticket?>().firstWhere(
            (t) => t?.id == id,
            orElse: () => null,
          );

  List<Ticket> _sortedTickets() {
    final copy = [..._tickets];
    copy.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return copy;
  }

  List<ActivityEvent> _sortedEvents() {
    final copy = [..._events];
    copy.sort((a, b) => b.at.compareTo(a.at));
    return copy;
  }

  void _emitTickets() {
    if (!_ticketsCtl.isClosed) {
      _ticketsCtl.add(_sortedTickets());
    }
  }

  void _emitDetail(String id) {
    final ctl = _detailCtls[id];
    if (ctl != null && !ctl.isClosed) {
      ctl.add(_findOrNull(id));
    }
  }

  void _emitActivity() {
    if (!_activityCtl.isClosed) {
      _activityCtl.add(_sortedEvents());
    }
  }

  void _pushEvent(ActivityEvent e) {
    _events.add(e);
    _emitActivity();
  }

  int _seq = 4000;
  String _nextCode() {
    _seq += 1;
    return 'TKT-$_seq';
  }

  // ---------------------------------------------------------------------------
  // Event factories
  // ---------------------------------------------------------------------------

  ActivityEvent _eventFromCreate(Ticket t) => ActivityEvent(
        id: 'e${DateTime.now().microsecondsSinceEpoch}-c',
        type: ActivityType.created,
        ticketId: t.id,
        ticketCode: t.code,
        ticketTitle: t.title,
        roomNumber: t.room.number,
        department: t.department,
        at: t.createdAt,
      );

  ActivityEvent _eventFromAccept(Ticket t, Duration etaIn) => ActivityEvent(
        id: 'e${DateTime.now().microsecondsSinceEpoch}-a',
        type: ActivityType.accepted,
        ticketId: t.id,
        ticketCode: t.code,
        ticketTitle: t.title,
        roomNumber: t.room.number,
        department: t.department,
        at: t.acceptedAt ?? DateTime.now(),
        actorName: t.assigneeName,
        eta: etaIn,
      );

  ActivityEvent _eventFromDone(Ticket t) => ActivityEvent(
        id: 'e${DateTime.now().microsecondsSinceEpoch}-d',
        type: ActivityType.done,
        ticketId: t.id,
        ticketCode: t.code,
        ticketTitle: t.title,
        roomNumber: t.room.number,
        department: t.department,
        at: t.doneAt ?? DateTime.now(),
        actorName: t.assigneeName,
      );

  ActivityEvent _eventFromCancel(Ticket t) => ActivityEvent(
        id: 'e${DateTime.now().microsecondsSinceEpoch}-x',
        type: ActivityType.cancelled,
        ticketId: t.id,
        ticketCode: t.code,
        ticketTitle: t.title,
        roomNumber: t.room.number,
        department: t.department,
        at: DateTime.now(),
        actorName: t.assigneeName,
      );

  ActivityEvent _eventFromReassign(Ticket t, Department dept) => ActivityEvent(
        id: 'e${DateTime.now().microsecondsSinceEpoch}-r',
        type: ActivityType.reassigned,
        ticketId: t.id,
        ticketCode: t.code,
        ticketTitle: t.title,
        roomNumber: t.room.number,
        department: t.department,
        at: DateTime.now(),
        actorName: t.assigneeName,
        // Locale-independent — display side resolves via Department.label.
        targetDepartment: dept,
      );

  ActivityEvent _eventFromNote(Ticket t, String note) => ActivityEvent(
        id: 'e${DateTime.now().microsecondsSinceEpoch}-n',
        type: ActivityType.note,
        ticketId: t.id,
        ticketCode: t.code,
        ticketTitle: t.title,
        roomNumber: t.room.number,
        department: t.department,
        at: DateTime.now(),
        actorName: t.assigneeName,
        extra: note,
      );

  void dispose() {
    _ticketsCtl.close();
    _activityCtl.close();
    for (final c in _detailCtls.values) {
      c.close();
    }
  }
}

/// StreamTransformer that prepends a single value to the underlying stream so
/// late subscribers see the latest snapshot before the next push.
class _StartWith<T> extends StreamTransformerBase<T, T> {
  final T initial;
  const _StartWith(this.initial);

  @override
  Stream<T> bind(Stream<T> stream) async* {
    yield initial;
    yield* stream;
  }
}
