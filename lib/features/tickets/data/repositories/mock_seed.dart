import '../../../activity/domain/models/activity_event.dart';
import '../../domain/models/department.dart';
import '../../domain/models/ticket.dart';

/// Seed data used by [MockTicketsRepository]. Mirrors the rooms, tickets
/// and "today/yesterday" timeline from the hotel-ops prototype.
class MockSeedSnapshot {
  final List<Ticket> tickets;
  final List<ActivityEvent> events;
  const MockSeedSnapshot(this.tickets, this.events);
}

abstract class MockSeed {
  /// Static room list — backs the room picker.
  static final List<Room> rooms = [
    const Room(id: 'r101', number: '101', floor: 1),
    const Room(id: 'r102', number: '102', floor: 1),
    const Room(id: 'r103', number: '103', floor: 1),
    const Room(id: 'r104', number: '104', floor: 1),
    const Room(id: 'r117', number: '117', floor: 1),
    const Room(id: 'r201', number: '201', floor: 2),
    const Room(id: 'r202', number: '202', floor: 2),
    const Room(id: 'r203', number: '203', floor: 2),
    const Room(id: 'r205', number: '205', floor: 2),
    const Room(id: 'r208', number: '208', floor: 2, type: 'Deluxe'),
    const Room(id: 'r301', number: '301', floor: 3),
    const Room(id: 'r302', number: '302', floor: 3),
    const Room(id: 'r303', number: '303', floor: 3),
    const Room(id: 'r410', number: '410', floor: 4),
    const Room(id: 'r412', number: '412', floor: 4),
    const Room(id: 'r501', number: '501', floor: 5),
  ];

  static MockSeedSnapshot build() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    Room room(String number) =>
        rooms.firstWhere((r) => r.number == number);

    final t1 = Ticket(
      id: 't1',
      code: 'TKT-3002',
      title: 'Extra towels',
      kind: TicketKind.universal,
      status: TicketStatus.incoming,
      department: Department.housekeeping,
      room: room('208'),
      guest: const Guest(
        id: 'g1',
        displayName: 'Mr. Bello',
        statusLine: 'Check-out tomorrow',
      ),
      items: const [
        RequestItem(
          id: 'i1',
          title: 'Towels',
          subtitle: 'Bath',
          quantity: 2,
        ),
      ],
      createdAt: now.subtract(const Duration(minutes: 2)),
    );

    final t2 = Ticket(
      id: 't2',
      code: 'TKT-3042',
      title: 'Towels, pillow & toiletries',
      kind: TicketKind.universal,
      status: TicketStatus.incoming,
      department: Department.housekeeping,
      room: room('208'),
      guest: const Guest(
        id: 'g1',
        displayName: 'Mr. Bello',
        statusLine: 'Check-out tomorrow',
      ),
      note: 'Please leave at the door, guest is resting.',
      items: const [
        RequestItem(
          id: 'i1',
          title: 'Towels',
          subtitle: 'Bath',
          quantity: 2,
        ),
        RequestItem(
          id: 'i2',
          title: 'Pillow',
          subtitle: 'Standard',
          quantity: 1,
        ),
        RequestItem(
          id: 'i3',
          title: 'Toiletries kit',
          subtitle: 'Complete set',
          quantity: 1,
        ),
      ],
      createdAt: now.subtract(const Duration(minutes: 4)),
    );

    final t3 = Ticket(
      id: 't3',
      code: 'TKT-3005',
      title: 'Pillows (2)',
      kind: TicketKind.universal,
      status: TicketStatus.incoming,
      department: Department.housekeeping,
      room: room('117'),
      items: const [
        RequestItem(
          id: 'i4',
          title: 'Pillow',
          subtitle: 'Standard',
          quantity: 2,
        ),
      ],
      createdAt: now.subtract(const Duration(minutes: 11)),
    );

    final t4 = Ticket(
      id: 't4',
      code: 'TKT-3007',
      title: 'Toiletries kit',
      kind: TicketKind.universal,
      status: TicketStatus.inProgress,
      department: Department.housekeeping,
      room: room('205'),
      assigneeName: 'Blessing K.',
      items: const [
        RequestItem(
          id: 'i5',
          title: 'Toiletries kit',
          subtitle: 'Complete set',
          quantity: 1,
        ),
      ],
      createdAt: now.subtract(const Duration(hours: 1, minutes: 5)),
      acceptedAt: now.subtract(const Duration(minutes: 25)),
      eta: now.add(const Duration(minutes: 3)),
    );

    final t5 = Ticket(
      id: 't5',
      code: 'TKT-3009',
      title: 'Water bottles (3)',
      kind: TicketKind.universal,
      status: TicketStatus.done,
      department: Department.housekeeping,
      room: room('410'),
      assigneeName: 'Blessing K.',
      items: const [
        RequestItem(
          id: 'i6',
          title: 'Water',
          subtitle: 'Bottled',
          quantity: 3,
        ),
      ],
      createdAt: yesterday.add(const Duration(hours: 6)),
      acceptedAt: yesterday.add(const Duration(hours: 6, minutes: 5)),
      doneAt: today.subtract(const Duration(hours: 2)),
    );

    final tickets = [t1, t2, t3, t4, t5];

    final events = <ActivityEvent>[
      _ev(t1, ActivityType.created, t1.createdAt),
      _ev(t3, ActivityType.created, t3.createdAt),
      _ev(t4, ActivityType.accepted, t4.acceptedAt!,
          actor: 'Blessing K.', eta: const Duration(minutes: 3)),
      _ev(t4, ActivityType.created, t4.createdAt),
      _ev(t5, ActivityType.accepted, t5.acceptedAt!,
          actor: 'Blessing K.', eta: const Duration(minutes: 5)),
      _ev(t5, ActivityType.done, t5.doneAt!, actor: 'Blessing K.'),
      _ev(t5, ActivityType.created, t5.createdAt),
    ];

    return MockSeedSnapshot(tickets, events);
  }

  static ActivityEvent _ev(
    Ticket t,
    ActivityType type,
    DateTime at, {
    String? actor,
    Duration? eta,
  }) {
    return ActivityEvent(
      id: 'seed-${t.id}-${type.name}-${at.microsecondsSinceEpoch}',
      type: type,
      ticketId: t.id,
      ticketCode: t.code,
      ticketTitle: t.title,
      roomNumber: t.room.number,
      department: t.department,
      at: at,
      actorName: actor,
      eta: eta,
    );
  }
}
