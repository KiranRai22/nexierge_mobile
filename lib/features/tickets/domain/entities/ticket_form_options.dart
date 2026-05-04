import 'package:flutter/foundation.dart';

import '../models/department.dart';

/// A department returned by `/tickets/add/get_departnents_and_rooms`.
///
/// [id] holds the server `department_id` — the value sent back on every
/// payload that needs a department. The wrapping record id is intentionally
/// ignored. [name] is the display label and the value used for any
/// name-based comparison or fallback.
///
/// [known] is a best-effort match to the legacy [Department] enum and
/// exists only so screens still backed by mock data keep working until they
/// move to the API entity.
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HotelDepartment && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// Department options used by the create-ticket form and the filter sheet.
///
/// Rooms are NOT carried here — the create flow sources rooms from the
/// checked-in guest stays endpoint, and the filter sheet doesn't need them.
@immutable
class TicketFormOptions {
  final List<HotelDepartment> departments;

  const TicketFormOptions({required this.departments});

  static const empty = TicketFormOptions(departments: []);
}
