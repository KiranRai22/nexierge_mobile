import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/department.dart';

/// Operator scope toggle. Persisted only in memory for now.
enum TicketScope { myDept, allHotel }

/// Lightweight session info — backed by auth later. For now just the
/// current operator's display name and home department.
class OperatorSession {
  final String displayName;
  final Department homeDepartment;
  const OperatorSession({
    required this.displayName,
    required this.homeDepartment,
  });
}

/// Mock session — replace with auth-backed provider in Phase 7.
final operatorSessionProvider = Provider<OperatorSession>((ref) {
  return const OperatorSession(
    displayName: 'Fola',
    homeDepartment: Department.frontDesk,
  );
});

/// Scope tab (My Dept / All Hotel) — shared between Tickets and Activity.
final ticketScopeProvider =
    StateProvider<TicketScope>((ref) => TicketScope.myDept);

/// Department-filter selection — shared between Tickets and Activity.
final departmentFilterProvider =
    StateProvider<Set<Department>>((ref) => const {});
