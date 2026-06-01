import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/entities/department.dart';
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

// ─── Advanced ticket filter (Department + Sort + Type) ───────────────

/// Unified filter state for the tickets screen.
@immutable
class TicketsAdvancedFilter {
  /// Selected dept IDs from user's accessible departments.
  /// Empty = all accessible departments.
  final Set<String> departmentIds;

  /// true = newest first (default), false = oldest first.
  final bool newestFirst;

  /// Ticket types to include: 'universal', 'catalog'. Empty = all.
  final Set<String> ticketTypes;

  const TicketsAdvancedFilter({
    required this.departmentIds,
    required this.newestFirst,
    required this.ticketTypes,
  });

  /// Number of active filter selections shown on the filter badge.
  int get activeCount =>
      departmentIds.length + 1 + ticketTypes.length;

  TicketsAdvancedFilter copyWith({
    Set<String>? departmentIds,
    bool? newestFirst,
    Set<String>? ticketTypes,
  }) =>
      TicketsAdvancedFilter(
        departmentIds: departmentIds ?? this.departmentIds,
        newestFirst: newestFirst ?? this.newestFirst,
        ticketTypes: ticketTypes ?? this.ticketTypes,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TicketsAdvancedFilter &&
          setEquals(other.departmentIds, departmentIds) &&
          other.newestFirst == newestFirst &&
          setEquals(other.ticketTypes, ticketTypes));

  @override
  int get hashCode => Object.hash(
        Object.hashAllUnordered(departmentIds),
        newestFirst,
        Object.hashAllUnordered(ticketTypes),
      );
}

/// Returns the departments the current user has access to (from auth/me).
final userAccessDepartmentsProvider = Provider<List<AuthDepartment>>((ref) {
  final profile = ref.watch(userProfileProvider);
  final depts = profile?.accessControl.departments ?? const [];
  //debugPrint(
  //   '[userAccessDepartmentsProvider] ${depts.length} dept(s): '
  //   '${depts.map((d) => '${d.id}/${d.name}').join(', ')}',
  // );
  return depts;
});

/// Persisted advanced filter state. null = use defaults derived from
/// [userAccessDepartmentsProvider].
final ticketsAdvancedFilterProvider =
    StateProvider<TicketsAdvancedFilter?>((ref) => null);

/// Resolved filter — falls back to "all user depts + newest + all types"
/// when no explicit filter has been applied yet.
final resolvedTicketsFilterProvider = Provider<TicketsAdvancedFilter>((ref) {
  final stored = ref.watch(ticketsAdvancedFilterProvider);
  if (stored != null) return stored;
  final depts = ref.watch(userAccessDepartmentsProvider);
  return TicketsAdvancedFilter(
    departmentIds: depts.map((d) => d.id).toSet(),
    newestFirst: true,
    ticketTypes: const {'universal_request', 'service_catalog'},
  );
});
