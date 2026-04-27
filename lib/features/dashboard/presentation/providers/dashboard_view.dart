import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../tickets/domain/models/department.dart';
import '../../../tickets/domain/models/ticket.dart';
import '../../../tickets/presentation/providers/repository_providers.dart';
import '../../../tickets/presentation/providers/session_providers.dart';

/// Severity bucket for the *Needs attention* list.
enum AttentionSeverity { overdue, warning, eta }

/// One row inside *Needs attention*.
class AttentionItem {
  final Ticket ticket;
  final int waitMin;
  final AttentionSeverity severity;

  const AttentionItem({
    required this.ticket,
    required this.waitMin,
    required this.severity,
  });
}

/// Counts that drive the small breakdown line under *Incoming Now*.
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
  final int inProgressCount;
  final int overdueCount;
  final IncomingBreakdown incomingBreakdown;
  final List<AttentionItem> needsAttention;

  const DashboardView({
    required this.incomingCount,
    required this.inProgressCount,
    required this.overdueCount,
    required this.incomingBreakdown,
    required this.needsAttention,
  });

  bool get hasUnread => incomingCount > 0 || overdueCount > 0;
}

/// Reactive dashboard view bound to the repository. Recomputes whenever
/// tickets change or the operator's scope/department filter moves.
final dashboardViewProvider =
    StreamProvider.autoDispose<DashboardView>((ref) {
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
  Set<Department> filter,
) {
  Iterable<Ticket> out = all;
  if (scope == TicketScope.myDept) {
    out = out.where((t) => t.department == home);
  }
  if (filter.isNotEmpty) {
    out = out.where((t) => filter.contains(t.department));
  }
  return out.toList(growable: false);
}

DashboardView _project(List<Ticket> tickets) {
  final now = DateTime.now();

  final incoming =
      tickets.where((t) => t.status == TicketStatus.incoming).toList();
  final inProgress = tickets
      .where((t) =>
          t.status == TicketStatus.inProgress ||
          t.status == TicketStatus.accepted)
      .toList();
  final overdue = tickets.where((t) => t.isOverdue).toList();

  final breakdown = IncomingBreakdown(
    universal: incoming.where((t) => t.kind == TicketKind.universal).length,
    catalog: incoming.where((t) => t.kind == TicketKind.catalog).length,
    manual: incoming.where((t) => t.kind == TicketKind.manual).length,
  );

  final attention = <AttentionItem>[];
  for (final t in tickets) {
    if (t.isOverdue) {
      final base = t.eta ?? t.createdAt;
      final wait = now.difference(base).inMinutes;
      attention.add(AttentionItem(
        ticket: t,
        waitMin: wait < 0 ? 0 : wait,
        severity: AttentionSeverity.overdue,
      ));
      continue;
    }
    if (t.status == TicketStatus.incoming) {
      final wait = now.difference(t.createdAt).inMinutes;
      if (wait >= 5) {
        attention.add(AttentionItem(
          ticket: t,
          waitMin: wait,
          severity: AttentionSeverity.warning,
        ));
      }
      continue;
    }
    if ((t.status == TicketStatus.inProgress ||
            t.status == TicketStatus.accepted) &&
        t.eta != null) {
      final etaIn = t.eta!.difference(now).inMinutes;
      attention.add(AttentionItem(
        ticket: t,
        waitMin: etaIn < 0 ? 0 : etaIn,
        severity: AttentionSeverity.eta,
      ));
    }
  }

  attention.sort((a, b) {
    final order = {
      AttentionSeverity.overdue: 0,
      AttentionSeverity.warning: 1,
      AttentionSeverity.eta: 2,
    };
    final cmp = order[a.severity]!.compareTo(order[b.severity]!);
    if (cmp != 0) return cmp;
    return b.waitMin.compareTo(a.waitMin);
  });

  return DashboardView(
    incomingCount: incoming.length,
    inProgressCount: inProgress.length,
    overdueCount: overdue.length,
    incomingBreakdown: breakdown,
    needsAttention: attention.take(4).toList(growable: false),
  );
}
