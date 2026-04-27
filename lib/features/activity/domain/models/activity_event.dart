import '../../../tickets/domain/models/department.dart';

enum ActivityType {
  created,
  accepted,
  done,
  overdue,
  cancelled,
  note,
  reassigned,
}

/// One row in the activity feed. Derived from ticket lifecycle events;
/// every mutation in the tickets repo produces zero or more of these.
///
/// Locale-sensitive fields (department labels, status names) are NEVER
/// stored as strings here — only as their canonical enum values, so the
/// row can re-render in any language without re-fetch.
class ActivityEvent {
  final String id;
  final ActivityType type;
  final String ticketId;
  final String ticketCode; // e.g. TKT-3042
  final String ticketTitle;
  final String roomNumber;
  final Department department;
  final String? actorName;
  final Duration? eta; // for accepted
  /// For [ActivityType.reassigned]: the department the ticket was moved TO.
  /// Stored as the enum (locale-independent) and resolved to a label at
  /// render time via `Department.label(AppLocalizations)`.
  final Department? targetDepartment;
  final String? extra; // free-form non-localized text (e.g. note body)
  final DateTime at;

  const ActivityEvent({
    required this.id,
    required this.type,
    required this.ticketId,
    required this.ticketCode,
    required this.ticketTitle,
    required this.roomNumber,
    required this.department,
    required this.at,
    this.actorName,
    this.eta,
    this.targetDepartment,
    this.extra,
  });
}
