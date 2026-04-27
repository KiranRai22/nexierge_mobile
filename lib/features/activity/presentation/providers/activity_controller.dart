import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../tickets/presentation/providers/repository_providers.dart';
import '../../../tickets/presentation/providers/session_providers.dart';
import '../../domain/models/activity_event.dart';

/// Subset of types the activity feed knows about. `all` is the default.
enum ActivityFilter {
  all,
  created,
  accepted,
  done,
  overdue,
  cancelled,
  notes,
  reassigned,
}

extension ActivityFilterMatch on ActivityFilter {
  bool matches(ActivityType t) {
    switch (this) {
      case ActivityFilter.all:
        return true;
      case ActivityFilter.created:
        return t == ActivityType.created;
      case ActivityFilter.accepted:
        return t == ActivityType.accepted;
      case ActivityFilter.done:
        return t == ActivityType.done;
      case ActivityFilter.overdue:
        return t == ActivityType.overdue;
      case ActivityFilter.cancelled:
        return t == ActivityType.cancelled;
      case ActivityFilter.notes:
        return t == ActivityType.note;
      case ActivityFilter.reassigned:
        return t == ActivityType.reassigned;
    }
  }
}

final activityFilterProvider =
    StateProvider.autoDispose<ActivityFilter>((ref) => ActivityFilter.all);

/// Reactive feed — listens to the activity repository, applies scope/filter.
final activityFeedProvider =
    StreamProvider.autoDispose<List<ActivityEvent>>((ref) {
  final repo = ref.watch(activityRepositoryProvider);
  final scope = ref.watch(ticketScopeProvider);
  final session = ref.watch(operatorSessionProvider);
  final dept = ref.watch(departmentFilterProvider);
  final filter = ref.watch(activityFilterProvider);

  return repo.watchEvents().map((events) {
    return events.where((e) {
      if (!filter.matches(e.type)) return false;
      if (scope == TicketScope.myDept &&
          e.department != session.homeDepartment) {
        return false;
      }
      if (dept.isNotEmpty && !dept.contains(e.department)) return false;
      return true;
    }).toList(growable: false);
  });
});
