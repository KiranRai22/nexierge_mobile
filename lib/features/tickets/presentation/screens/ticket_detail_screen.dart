import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/typography_manager.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/models/department.dart';
import '../../domain/models/ticket.dart';
import '../providers/ticket_detail_controller.dart';
import '../widgets/detail/ticket_action_bar.dart';
import '../widgets/detail/ticket_activity_timeline.dart';
import '../widgets/detail/ticket_detail_app_bar.dart';
import '../widgets/detail/ticket_detail_tabs.dart';
import '../widgets/detail/ticket_hero_card.dart';
import '../widgets/detail/ticket_info_card.dart';

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
    final asyncTicket = ref.watch(ticketByIdProvider(ticketId));
    final c = context.appColors;
    return Scaffold(
      backgroundColor: c.bgBase,
      body: asyncTicket.when(
        data: (t) => t == null ? const _MissingView() : _DetailBody(ticket: t),
        loading: () => const _LoadingView(),
        error: (e, _) => _ErrorView(error: e.toString()),
      ),
    );
  }
}

class _DetailBody extends StatefulWidget {
  final Ticket ticket;
  const _DetailBody({required this.ticket});

  @override
  State<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends State<_DetailBody>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Column(
      children: [
        TicketDetailAppBar(
          ticket: widget.ticket,
          onBack: () => Navigator.of(context).pop(),
          onClose: () => Navigator.of(context).pop(),
        ),
        TicketDetailTabs(controller: _tabs),
        Expanded(
          child: Container(
            color: c.bgBase,
            child: TabBarView(
              controller: _tabs,
              children: [
                _DetailsTab(ticket: widget.ticket),
                _ActivityTab(ticket: widget.ticket),
              ],
            ),
          ),
        ),
        TicketActionBar(ticket: widget.ticket),
      ],
    );
  }
}

class _DetailsTab extends StatelessWidget {
  final Ticket ticket;
  const _DetailsTab({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
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
              value: ticket.room.type,
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
    final c = context.appColors;
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
  final Ticket ticket;
  const _ActivityTab({required this.ticket});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [TicketActivityTimeline(ticketId: ticket.id)],
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();
  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Center(child: CircularProgressIndicator(color: c.tagPurpleIcon));
  }
}

class _MissingView extends StatelessWidget {
  const _MissingView();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          context.l10n.notFoundError,
          textAlign: TextAlign.center,
          style: TypographyManager.textBody,
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  const _ErrorView({required this.error});
  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
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
