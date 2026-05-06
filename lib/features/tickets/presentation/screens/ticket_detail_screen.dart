import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/theme/unified_theme_manager.dart';
import '../../../../core/theme/typography_manager.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/ticket_detail.dart';
import '../../domain/models/department.dart';
import '../../domain/models/ticket.dart';
import '../providers/ticket_detail_api_controller.dart';
import '../widgets/detail/ticket_action_bar.dart';
import '../widgets/detail/ticket_activity_timeline.dart';
import '../widgets/detail/ticket_detail_app_bar.dart';
import '../widgets/detail/ticket_detail_tabs.dart';
import '../widgets/detail/ticket_hero_card.dart';
import '../widgets/detail/ticket_info_card.dart';

Ticket _mapToTicket(TicketDetail detail) {
  return Ticket(
    id: detail.id,
    code: detail.id.substring(0, 8),
    title: detail.guestName,
    kind: TicketKind.manual,
    status: _mapStatus(detail.status),
    department: _mapDepartment(detail.departmentId),
    room: Room(id: detail.room, number: detail.onbRoomNumber, floor: 0),
    guest: Guest(id: detail.room, displayName: detail.guestName),
    items: const [],
    note: detail.issueDetails.isNotEmpty ? detail.issueDetails : null,
    assigneeName: null,
    priority: _mapPriority(detail.priority),
    source: _mapSource(detail.source),
    createdAt: DateTime.fromMillisecondsSinceEpoch(detail.createdAt),
    acceptedAt: detail.acknowledgedAt > 0
        ? DateTime.fromMillisecondsSinceEpoch(detail.acknowledgedAt)
        : null,
    doneAt: null,
    eta: null,
  );
}

Department _mapDepartment(String deptId) {
  return Department.housekeeping;
}

TicketStatus _mapStatus(String status) {
  switch (status) {
    case 'ACCEPTED':
      return TicketStatus.accepted;
    case 'NEW':
      return TicketStatus.incoming;
    case 'IN_PROGRESS':
      return TicketStatus.inProgress;
    case 'DONE':
      return TicketStatus.done;
    case 'CANCELLED':
      return TicketStatus.cancelled;
    default:
      return TicketStatus.incoming;
  }
}

TicketPriority _mapPriority(String priority) {
  switch (priority) {
    case 'P1':
      return TicketPriority.p1;
    case 'P2':
      return TicketPriority.p2;
    case 'P3':
      return TicketPriority.p3;
    default:
      return TicketPriority.p3;
  }
}

TicketSource _mapSource(String source) {
  switch (source) {
    case 'Manual':
      return TicketSource.frontDesk;
    case 'System':
      return TicketSource.system;
    default:
      return TicketSource.guestApp;
  }
}

/// Ticket detail screen — port of the Lovable prototype.
///
/// Layout:
///   - Custom top bar (back · TKT-####  [status][priority] · close)
///   - Tabs (Details / Activity)
///   - Tab body
///       Details : hero card + Guest&Room card + Ticket Info card
///       Activity: vertical timeline of `ActivityEvent`s for this ticket
///   - Persistent action bar (Start Work + Change Due / Cancel / Reset)
///
/// Stays reactive: `ticketByIdProvider` re-emits whenever the repository
/// mutates, so the screen automatically reflects accept / start / done /
/// cancel without explicit refreshes.
class TicketDetailScreen extends ConsumerWidget {
  final String ticketId;
  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future.microtask(
      () => ref.read(ticketIdProvider.notifier).state = ticketId,
    );
    final asyncTicket = ref.watch(ticketDetailApiControllerProvider);
    final c = context.themeColors;
    return Scaffold(
      backgroundColor: c.bgBase,
      body: asyncTicket.when(
        data: (t) => _DetailBody(ticket: t),
        loading: () => const _LoadingView(),
        error: (e, _) => _ErrorView(error: e.toString()),
      ),
    );
  }
}

class _DetailBody extends StatefulWidget {
  final TicketDetail ticket;
  const _DetailBody({required this.ticket});

  Ticket get mappedTicket => _mapToTicket(ticket);

  @override
  State<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends State<_DetailBody>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() {
      if (_tabs.indexIsChanging) {
        setState(() => _selectedTab = _tabs.index);
      }
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    return Scaffold(
      backgroundColor: c.bgBase,
      body: Column(
        children: [
          TicketDetailAppBar(
            ticket: widget.mappedTicket,
            onBack: () => Navigator.of(context).pop(),
            onClose: () => Navigator.of(context).pop(),
          ),
          TicketDetailTabs(controller: _tabs),
          Expanded(
            child: _selectedTab == 0
                ? _DetailsTab(ticket: widget.mappedTicket)
                : _ActivityTab(ticket: widget.ticket),
          ),
          TicketActionBar(ticket: widget.mappedTicket),
        ],
      ),
    );
  }
}

class _DetailsTab extends StatelessWidget {
  final Ticket ticket;
  const _DetailsTab({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    final s = context.l10n;
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        TicketHeroCard(ticket: ticket),
        const SizedBox(height: 20),
        TicketSectionLabel(label: s.ticketSectionGuestRoom),
        TicketInfoCard(
          rows: [
            TicketInfoRow(
              label: s.ticketFieldGuest,
              value: ticket.guest?.displayName ?? '—',
            ),
            TicketInfoRow(
              label: s.ticketFieldRoom,
              value: s.ticketRoomNumber(ticket.room.number),
            ),
            TicketInfoRow(
              label: s.ticketFieldRoomType,
              value: ticket.room.type ?? '—',
            ),
            TicketInfoRow(
              label: s.ticketFieldDepartment,
              trailing: DepartmentValue(
                dotColor: _departmentDot(c, ticket.department),
                label: ticket.department.label(s),
              ),
            ),
            TicketInfoRow(
              label: s.ticketFieldConversation,
              value: ticket.note ?? '—',
            ),
          ],
        ),
        const SizedBox(height: 20),
        TicketSectionLabel(label: s.ticketSectionInformation),
        TicketInfoCard(
          rows: [
            TicketInfoRow(
              label: s.ticketFieldStatus,
              trailing: _statusPill(context, ticket.status),
            ),
            TicketInfoRow(
              label: s.ticketFieldTicketType,
              value: _kindLabel(s, ticket.kind),
            ),
            TicketInfoRow(
              label: s.ticketFieldSource,
              value: ticket.source == null
                  ? '—'
                  : _sourceLabel(s, ticket.source!),
            ),
            TicketInfoRow(
              label: s.ticketFieldDepartment,
              value: ticket.department.label(s),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statusPill(BuildContext context, TicketStatus st) {
    final c = context.themeColors;
    final s = context.l10n;
    late Color bg;
    late Color fg;
    late String label;
    switch (st) {
      case TicketStatus.accepted:
        bg = c.tagGreenBg;
        fg = c.tagGreenText;
        label = s.ticketStatusBadgeAccepted;
      case TicketStatus.inProgress:
        bg = c.tagGreenBg;
        fg = c.tagGreenText;
        label = s.ticketStatusBadgeInProgress;
      case TicketStatus.incoming:
        bg = c.tagBlueBg;
        fg = c.tagBlueText;
        label = s.ticketStatusBadgeIncoming;
      case TicketStatus.done:
        bg = c.tagNeutralBg;
        fg = c.tagNeutralText;
        label = s.ticketStatusBadgeDone;
      case TicketStatus.cancelled:
        bg = c.tagRedBg;
        fg = c.tagRedText;
        label = s.ticketStatusBadgeCancelled;
      case TicketStatus.scheduled:
        bg = c.tagPurpleBg;
        fg = c.tagPurpleText;
        label = s.subTabScheduled;
    }
    return TicketInfoStatusPill(label: label, bg: bg, fg: fg);
  }

  String _kindLabel(AppLocalizations s, TicketKind k) {
    switch (k) {
      case TicketKind.universal:
        return s.chipUniversal;
      case TicketKind.catalog:
        return s.chipCatalog;
      case TicketKind.manual:
        return s.chipManual;
    }
  }

  String _sourceLabel(AppLocalizations s, TicketSource src) {
    switch (src) {
      case TicketSource.whatsApp:
        return s.createSourceWhatsApp;
      case TicketSource.guestApp:
        return s.ticketSourceGuestApp;
      case TicketSource.frontDesk:
        return s.ticketSourceFrontDesk;
      case TicketSource.phone:
        return s.ticketSourcePhone;
      case TicketSource.walkIn:
        return s.ticketSourceWalkIn;
      case TicketSource.system:
        return s.ticketSourceSystem;
    }
  }

  Color _departmentDot(AppColors c, Department d) {
    switch (d) {
      case Department.maintenance:
        return c.tagOrangeIcon;
      case Department.housekeeping:
        return c.tagBlueIcon;
      case Department.fnb:
      case Department.roomService:
        return c.tagAmberIcon;
      case Department.frontDesk:
        return c.tagPurpleIcon;
      case Department.concierge:
        return c.tagGreenIcon;
    }
  }
}

class _ActivityTab extends StatelessWidget {
  final TicketDetail ticket;
  const _ActivityTab({required this.ticket});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [TicketActivityTimeline(ticket: ticket)],
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();
  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    return Scaffold(
      backgroundColor: c.bgBase,
      body: Column(
        children: [
          _AppBarShimmer(c: c),
          _TabsShimmer(c: c),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _HeroShimmer(c: c),
                const SizedBox(height: 16),
                _InfoShimmer(c: c),
              ],
            ),
          ),
          _ActionBarShimmer(c: c),
        ],
      ),
    );
  }
}

class _AppBarShimmer extends StatelessWidget {
  final AppColors c;
  const _AppBarShimmer({required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: c.bgBase,
        border: Border(bottom: BorderSide(color: c.borderBase, width: 1)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: c.borderBase.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 20,
              width: 100,
              decoration: BoxDecoration(
                color: c.borderBase.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: c.borderBase.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabsShimmer extends StatelessWidget {
  final AppColors c;
  const _TabsShimmer({required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: c.bgBase,
        border: Border(bottom: BorderSide(color: c.borderBase, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 24,
              width: 60,
              decoration: BoxDecoration(
                color: c.borderBase.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Container(
              height: 24,
              width: 60,
              decoration: BoxDecoration(
                color: c.borderBase.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroShimmer extends StatelessWidget {
  final AppColors c;
  const _HeroShimmer({required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: c.bgBase,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.borderBase, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 20,
              width: 80,
              decoration: BoxDecoration(
                color: c.borderBase.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 16,
              width: 120,
              decoration: BoxDecoration(
                color: c.borderBase.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 16,
              width: 100,
              decoration: BoxDecoration(
                color: c.borderBase.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoShimmer extends StatelessWidget {
  final AppColors c;
  const _InfoShimmer({required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: c.bgBase,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.borderBase, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (var i = 0; i < 4; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    height: 14,
                    width: 80,
                    decoration: BoxDecoration(
                      color: c.borderBase.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    height: 14,
                    width: 100,
                    decoration: BoxDecoration(
                      color: c.borderBase.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionBarShimmer extends StatelessWidget {
  final AppColors c;
  const _ActionBarShimmer({required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: c.bgBase,
        border: Border(top: BorderSide(color: c.borderBase, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: c.borderBase.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: c.borderBase.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  const _ErrorView({required this.error});
  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 56, color: c.fgError),
            const SizedBox(height: 12),
            Text(
              context.l10n.unknownError,
              style: TypographyManager.textBody,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              error,
              style: TypographyManager.textMeta,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
