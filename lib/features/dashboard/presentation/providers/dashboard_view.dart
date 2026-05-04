import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../tickets/domain/entities/ticket_form_options.dart';
import '../../../tickets/domain/models/department.dart';
import '../../../tickets/domain/models/ticket.dart';
import '../../../tickets/presentation/providers/repository_providers.dart';
import '../../../tickets/presentation/providers/session_providers.dart';

/// Severity bucket for the *Needs attention* list. Mirrors the four cases in
/// the React HotelOps dashboard so the UI rendering can stay 1:1 with the
/// design — see `docs/ai_prompts/Dashboard.tsx`.
enum AttentionSeverity { overdue, dueSoon, notStarted, needsAck }

/// One row inside *Needs attention*.
class AttentionItem {
  final Ticket ticket;

  /// Minutes value used both for chip display and secondary sort. Semantics
  /// vary by severity:
  /// * `overdue` / `notStarted` / `needsAck` → minutes elapsed (longest first)
  /// * `dueSoon` → minutes until the ETA (smallest first = most urgent)
  final int minutes;
  final AttentionSeverity severity;

  const AttentionItem({
    required this.ticket,
    required this.minutes,
    required this.severity,
  });
}

/// Counts that drive the small breakdown line under *Needs acknowledgment*.
class IncomingBreakdown {
  final int universal;
  final int catalog;
  final int manual;

  const IncomingBreakdown({
    required this.universal,
    required this.catalog,
    required this.manual,
  });

  bool get hasAny => universal > 0 || catalog > 0 || manual > 0;
}

/// Aggregated view-model the dashboard renders. Independent of the tickets
/// list sub-tab and search query — the dashboard is its own surface.
class DashboardView {
  final int incomingCount;
  final int acceptedCount;
  final int inProgressCount;
  final int overdueCount;
  final IncomingBreakdown incomingBreakdown;
  final List<AttentionItem> needsAttention;

  const DashboardView({
    required this.incomingCount,
    required this.acceptedCount,
    required this.inProgressCount,
    required this.overdueCount,
    required this.incomingBreakdown,
    required this.needsAttention,
  });

  bool get hasUnread => incomingCount > 0 || overdueCount > 0;
}

// Thresholds (minutes) for the attention classifier. Matches the React
// constants in `Dashboard.tsx` so behaviour stays in sync across platforms.
const int _needsAckAfterMin = 5;
const int _notStartedAfterMin = 5;
const int _dueSoonWithinMin = 10;

/// Reactive dashboard view bound to the repository. Recomputes whenever
/// tickets change or the operator's scope/department filter moves.
final dashboardViewProvider = StreamProvider.autoDispose<DashboardView>((
  ref,
) {
  final repo = ref.watch(ticketsRepositoryProvider);
  final scope = ref.watch(ticketScopeProvider);
  final dept = ref.watch(departmentFilterProvider);
  final session = ref.watch(operatorSessionProvider);

  return repo.watchAll().map((all) {
    final scoped = _applyScope(all, scope, session.homeDepartment, dept);
    return _project(scoped);
  });
});

List<Ticket> _applyScope(
  List<Ticket> all,
  TicketScope scope,
  Department home,
  Set<HotelDepartment> filter,
) {
  Iterable<Ticket> out = all;
  if (scope == TicketScope.myDept) {
    out = out.where((t) => t.department == home);
  }
  if (filter.isNotEmpty) {
    // Mock Tickets carry the legacy [Department] enum, so we match via the
    // picked HotelDepartment's `known` mapping until tickets move to API.
    final knownEnums =
        filter.map((d) => d.known).whereType<Department>().toSet();
    out = out.where((t) => knownEnums.contains(t.department));
  }
  return out.toList(growable: false);
}

DashboardView _project(List<Ticket> tickets) {
  final now = DateTime.now();

  final incoming = tickets
      .where((t) => t.status == TicketStatus.incoming)
      .toList();
  final accepted = tickets
      .where((t) => t.status == TicketStatus.accepted)
      .toList();
  final inProgress = tickets
      .where((t) => t.status == TicketStatus.inProgress)
      .toList();
  final overdue = inProgress
      .where((t) => t.eta != null && now.isAfter(t.eta!))
      .toList();

  final breakdown = IncomingBreakdown(
    universal: incoming.where((t) => t.kind == TicketKind.universal).length,
    catalog: incoming.where((t) => t.kind == TicketKind.catalog).length,
    manual: incoming.where((t) => t.kind == TicketKind.manual).length,
  );

  final attention = <AttentionItem>[];
  for (final t in tickets) {
    final item = _classify(t, now);
    if (item != null) attention.add(item);
  }
  attention.sort(_compareAttention);

  return DashboardView(
    incomingCount: incoming.length,
    acceptedCount: accepted.length,
    inProgressCount: inProgress.length,
    overdueCount: overdue.length,
    incomingBreakdown: breakdown,
    needsAttention: attention.take(5).toList(growable: false),
  );
}

AttentionItem? _classify(Ticket t, DateTime now) {
  switch (t.status) {
    case TicketStatus.inProgress:
      final eta = t.eta;
      if (eta == null) return null;
      if (!now.isBefore(eta)) {
        return AttentionItem(
          ticket: t,
          minutes: now.difference(eta).inMinutes,
          severity: AttentionSeverity.overdue,
        );
      }
      final remaining = eta.difference(now).inMinutes;
      if (remaining <= _dueSoonWithinMin) {
        return AttentionItem(
          ticket: t,
          minutes: remaining < 0 ? 0 : remaining,
          severity: AttentionSeverity.dueSoon,
        );
      }
      return null;
    case TicketStatus.accepted:
      final accAt = t.acceptedAt ?? t.createdAt;
      final since = now.difference(accAt).inMinutes;
      if (since >= _notStartedAfterMin) {
        return AttentionItem(
          ticket: t,
          minutes: since,
          severity: AttentionSeverity.notStarted,
        );
      }
      return null;
    case TicketStatus.incoming:
      final since = now.difference(t.createdAt).inMinutes;
      if (since >= _needsAckAfterMin) {
        return AttentionItem(
          ticket: t,
          minutes: since,
          severity: AttentionSeverity.needsAck,
        );
      }
      return null;
    case TicketStatus.done:
    case TicketStatus.cancelled:
      return null;
  }
}

int _compareAttention(AttentionItem a, AttentionItem b) {
  const order = {
    AttentionSeverity.overdue: 0,
    AttentionSeverity.dueSoon: 1,
    AttentionSeverity.notStarted: 2,
    AttentionSeverity.needsAck: 3,
  };
  final cmp = order[a.severity]!.compareTo(order[b.severity]!);
  if (cmp != 0) return cmp;
  // dueSoon: smallest minutes first (most urgent). Others: largest first.
  if (a.severity == AttentionSeverity.dueSoon) {
    return a.minutes.compareTo(b.minutes);
  }
  return b.minutes.compareTo(a.minutes);
}
