import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/theme/unified_theme_manager.dart';
import '../../../../core/theme/typography_manager.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/ticket_detail.dart';
import '../../domain/models/department.dart';
import '../../domain/models/ticket.dart';
import '../providers/my_tickets_list_controller.dart';
import '../providers/ticket_detail_api_controller.dart';
import '../providers/ticket_form_options_provider.dart';
import '../widgets/detail/ticket_action_bar.dart';
import '../widgets/detail/ticket_activity_timeline.dart';
import '../widgets/detail/ticket_detail_app_bar.dart';
import '../widgets/detail/ticket_detail_tabs.dart';
import '../widgets/detail/ticket_hero_card.dart';
import '../widgets/detail/ticket_info_card.dart';
import '../widgets/skeletons/ticket_detail_skeleton.dart';

/// Builds the [Ticket] shown on the detail screen by *merging* two sources:
///
///   1. [cachedListTicket] — the same `Ticket` object the list card rendered
///      (title, kind, source, priority, departmentName, kindData, etc.).
///      This is the trusted source for everything the list already
///      classified — the `/tickets/details` endpoint returns a much sparser
///      payload that misclassifies kind/source for manual tickets.
///   2. [detail] — the freshly-fetched `TicketDetail` from
///      `/tickets/details`. Provides authoritative current `status`,
///      `acknowledgedAt`, `issueDetails` (full body), and the activity
///      events that the list payload doesn't carry.
///
/// When [cachedListTicket] is null (deep-link cold-start, list never
/// loaded), we fall back to deriving fields from [detail] alone — using the
/// cached departments map to at least resolve the dept name from id.
Ticket _mergeTicket({
  required TicketDetail detail,
  required Ticket? cachedListTicket,
  required Map<String, String> deptNamesById,
}) {
  final p = cachedListTicket;
  final detailStatus = _mapStatus(detail.status);
  final detailAccepted = detail.acknowledgedAt > 0
      ? DateTime.fromMillisecondsSinceEpoch(detail.acknowledgedAt)
      : null;
  return Ticket(
    id: detail.id,
    code: p?.code ?? detail.id.substring(0, 8),
    title: p?.title ?? _fallbackTitle(detail, deptNamesById),
    kind: p?.kind ?? _mapKindFromType(detail.type),
    status: detailStatus,
    department: p?.department ?? Department.housekeeping,
    departmentName: p?.departmentName ?? deptNamesById[detail.departmentId],
    departmentEmoji: detail.mobileIcon.isNotEmpty ? detail.mobileIcon : p?.departmentEmoji,
    departmentIconUrl: p?.departmentIconUrl,
    room: Room(
      id: detail.room,
      number: detail.onbRoomNumber.isNotEmpty ? detail.onbRoomNumber : (p?.room.number ?? ''),
      floor: 0,
    ),
    guest:
        p?.guest ??
        (detail.guestName.isNotEmpty
            ? Guest(id: detail.room, displayName: detail.guestName)
            : null),
    items: p?.items ?? const [],
    note: detail.issueDetails.isNotEmpty ? detail.issueDetails : p?.note,
    assigneeName: p?.assigneeName,
    priority: p?.priority ?? _mapPriority(detail.priority),
    source: p?.source ?? _mapSource(detail.source),
    createdAt:
        p?.createdAt ?? DateTime.fromMillisecondsSinceEpoch(detail.createdAt),
    createdTime: detail.createdTime.isNotEmpty ? detail.createdTime : p?.createdTime,
    acceptedAt: detailAccepted ?? p?.acceptedAt,
    doneAt: p?.doneAt,
    eta: p?.eta,
    workStartedAt: p?.workStartedAt,
    isTransitioning: false,
    kindData: p?.kindData,
  );
}

/// Best-effort title when the cached list ticket isn't available
/// (deep-link). Prefers the detail's own summary, then department name from
/// the cache, then room number. Mirrors the list controller's fallback
/// chain spirit so cold-start titles look similar to warm-cache titles.
String _fallbackTitle(TicketDetail detail, Map<String, String> deptNamesById) {
  if (detail.issueSummary.isNotEmpty) return detail.issueSummary;
  final deptName = deptNamesById[detail.departmentId];
  if (deptName != null && deptName.isNotEmpty) {
    final type = detail.type.toUpperCase();
    if (type == 'REQUEST') return '$deptName request';
    if (type == 'CATALOG') return '$deptName order';
    return deptName;
  }
  if (detail.onbRoomNumber.isNotEmpty) return 'Room ${detail.onbRoomNumber}';
  if (detail.guestName.isNotEmpty) return detail.guestName;
  return '—';
}

TicketStatus _mapStatus(String status) {
  switch (status.toUpperCase()) {
    case 'ACCEPTED':
      return TicketStatus.accepted;
    case 'NEW':
      return TicketStatus.incoming;
    case 'IN_PROGRESS':
      return TicketStatus.inProgress;
    case 'DONE':
      return TicketStatus.done;
    case 'CANCELED':
    case 'CANCELLED':
      return TicketStatus.canceled;
    case 'ON_HOLD':
      return TicketStatus.onHold;
    case 'BACKLOG':
      return TicketStatus.backlog;
    case 'EXPIRED':
      return TicketStatus.canceled;
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

/// Coarse fallback used only when there's no cached list ticket. The list
/// controller's `_mapKind` is richer (uses `ticketType` if present) — this
/// only fires on deep-link cold-starts where TicketDetail is all we have.
TicketKind _mapKindFromType(String type) {
  switch (type.toUpperCase()) {
    case 'REQUEST':
      return TicketKind.universal;
    case 'CATALOG':
      return TicketKind.catalog;
    default:
      return TicketKind.manual;
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

  /// The list-built Ticket forwarded from the calling screen (when the
  /// caller has it on hand). Skips the cache-lookup race entirely so the
  /// detail header renders with the right kind/source/title from the first
  /// frame. Other callers (notifications, activity row, dashboard tap) can
  /// omit this and rely on `cachedTicketByIdProvider` to find the ticket.
  final Ticket? presetTicket;

  const TicketDetailScreen({
    super.key,
    required this.ticketId,
    this.presetTicket,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future.microtask(
      () => ref.read(ticketIdProvider.notifier).state = ticketId,
    );
    final asyncTicket = ref.watch(ticketDetailApiControllerProvider);
    // Reuse the SAME Ticket object the list card rendered. Preset (passed
    // from list nav) wins; otherwise look it up across legacy + paged
    // caches. This carries the already-classified kind / source / title /
    // priority / kindData — none of which the sparse `/tickets/details`
    // payload reliably carries.
    final cachedListTicket =
        presetTicket ?? ref.watch(cachedTicketByIdProvider(ticketId));
    // Department name lookup: detail API only returns department_id, so we
    // resolve the human name from the cached departments list (populated by
    // ticketFormOptionsProvider) for cold-start deep-links where the list
    // ticket isn't cached.
    final deptNamesById = {
      for (final d in ref.watch(apiDepartmentsProvider)) d.id: d.name,
    };
    final c = context.themeColors;
    return Scaffold(
      backgroundColor: c.bgBase,
      body: asyncTicket.when(
        data: (t) => _DetailBody(
          ticket: t,
          cachedListTicket: cachedListTicket,
          deptNamesById: deptNamesById,
        ),
        loading: () => const TicketDetailSkeleton(),
        error: (e, _) => _ErrorView(error: e.toString()),
      ),
    );
  }
}

class _DetailBody extends StatefulWidget {
  final TicketDetail ticket;
  final Ticket? cachedListTicket;
  final Map<String, String> deptNamesById;
  const _DetailBody({
    required this.ticket,
    required this.cachedListTicket,
    required this.deptNamesById,
  });

  Ticket get mappedTicket => _mergeTicket(
    detail: ticket,
    cachedListTicket: cachedListTicket,
    deptNamesById: deptNamesById,
  );

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
        CollapsibleTicketSection(
          label: s.ticketSectionGuestRoom,
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
              compactValue: ticket.department.label(s),
            ),
            TicketInfoRow(
              label: s.ticketFieldConversation,
              value: ticket.note ?? '—',
            ),
          ],
        ),
        const SizedBox(height: 20),
        CollapsibleTicketSection(
          label: s.ticketSectionInformation,
          rows: [
            TicketInfoRow(
              label: s.ticketFieldStatus,
              trailing: _statusPill(context, ticket.status),
              compactValue: _statusLabel(s, ticket.status),
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

  /// Plain-text status label used in collapsed-section summaries (status
  /// pill is a custom widget, can't be flattened to a string by itself).
  String _statusLabel(AppLocalizations s, TicketStatus st) {
    switch (st) {
      case TicketStatus.accepted:
        return s.ticketStatusBadgeAccepted;
      case TicketStatus.inProgress:
        return s.ticketStatusBadgeInProgress;
      case TicketStatus.incoming:
        return s.ticketStatusBadgeNew;
      case TicketStatus.done:
        return s.ticketStatusBadgeDone;
      case TicketStatus.canceled:
        return s.ticketStatusBadgeCancelled;
      case TicketStatus.onHold:
        return s.ticketStatusBadgeOnHold;
      case TicketStatus.backlog:
        return 'Backlog';
    }
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
        label = s.ticketStatusBadgeNew;
      case TicketStatus.done:
        bg = c.tagNeutralBg;
        fg = c.tagNeutralText;
        label = s.ticketStatusBadgeDone;
      case TicketStatus.canceled:
        bg = c.tagRedBg;
        fg = c.tagRedText;
        label = s.ticketStatusBadgeCancelled;
      case TicketStatus.onHold:
        bg = c.tagPurpleBg;
        fg = c.tagPurpleText;
        label = s.ticketStatusBadgeOnHold;
      case TicketStatus.backlog:
        bg = c.tagNeutralBg;
        fg = c.tagNeutralText;
        label = 'Backlog';
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
            Icon(LucideIcons.triangleAlert, size: 56, color: c.fgError),
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
