import 'package:flutter/foundation.dart';

import '../models/department.dart';
import '../models/ticket.dart';

/// A department returned by the form-options API. Identity is the server id;
/// [known] is a best-effort match to the legacy [Department] enum so existing
/// code paths keep working.
@immutable
class HotelDepartment {
  final String id;
  final String name;
  final Department? known;

  const HotelDepartment({
    required this.id,
    required this.name,
    this.known,
  });

  factory HotelDepartment.fromName({required String id, required String name}) {
    return HotelDepartment(
      id: id,
      name: name,
      known: _matchEnum(name),
    );
  }

  static Department? _matchEnum(String name) {
    final n = name.toLowerCase().trim();
    if (n.contains('housekeep')) return Department.housekeeping;
    if (n.contains('front')) return Department.frontDesk;
    if (n.contains('mainten')) return Department.maintenance;
    if (n.contains('concierge')) return Department.concierge;
    if (n.contains('room service') || n == 'rs') return Department.roomService;
    if (n.contains('f&b') ||
        n.contains('food') ||
        n.contains('beverage') ||
        n.contains('restaurant')) {
      return Department.fnb;
    }
    return null;
  }
}

/// Bundle of room + department options used to populate the create-ticket
/// form. Cached per hotel for the duration of the create flow.
@immutable
class TicketFormOptions {
  final List<HotelDepartment> departments;
  final List<Room> rooms;

  const TicketFormOptions({
    required this.departments,
    required this.rooms,
  });

  static const empty =
      TicketFormOptions(departments: [], rooms: []);
}
