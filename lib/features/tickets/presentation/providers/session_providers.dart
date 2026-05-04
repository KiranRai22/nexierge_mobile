import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/ticket_form_options.dart';
import '../../domain/models/department.dart';
import '../../../auth/presentation/providers/user_profile_controller.dart';

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

/// Real session data from user profile
final operatorSessionProvider = Provider<OperatorSession>((ref) {
  final userProfile = ref.watch(userProfileProvider);

  if (userProfile == null) {
    // Fallback to mock data while profile loads
    return const OperatorSession(
      displayName: 'Loading...',
      homeDepartment: Department.frontDesk,
    );
  }

  // Extract display name from user profile
  final displayName = '${userProfile.firstName} ${userProfile.lastName}';

  // Extract home department from user hotel status hierarchy role
  Department homeDepartment = Department.frontDesk; // default fallback
  try {
    homeDepartment = Department.values.firstWhere(
      (dept) => dept.name == userProfile.userHotelStatus.hierarchyRole,
    );
  } catch (_) {
    // If hierarchy role doesn't match any department, use default
    homeDepartment = Department.frontDesk;
  }

  return OperatorSession(
    displayName: displayName,
    homeDepartment: homeDepartment,
  );
});

/// Scope tab (My Dept / All Hotel) — shared between Tickets and Activity.
final ticketScopeProvider = StateProvider<TicketScope>(
  (ref) => TicketScope.myDept,
);

/// Department-filter selection — shared between Tickets, Activity, and the
/// dashboard. Each entry is a [HotelDepartment] (server `department_id` +
/// display name); equality is by `department_id`. Consumers that compare
/// against the legacy [Department] enum (mock-backed Ticket lists) use
/// `HotelDepartment.known`.
final departmentFilterProvider = StateProvider<Set<HotelDepartment>>(
  (ref) => const {},
);
