import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/theme/card_theme.dart';
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
    opsTicketId: p?.opsTicketId ?? detail.opsTicketId,
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
    if (type == 'REQUEST') return deptName;
    if (type == 'CATALOG') return deptName;
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
    _tabs = TabController(length: 4, vsync: this);
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
            child: switch (_selectedTab) {
              0 => _OverviewTab(ticket: widget.mappedTicket),
              1 => _OrdersTab(ticket: widget.mappedTicket),
              2 => _GuestTab(ticket: widget.mappedTicket),
              _ => _ActivityTab(ticket: widget.ticket),
            },
          ),
          TicketActionBar(ticket: widget.mappedTicket),
        ],
      ),
    );
  }
}

/// Overview tab: hero card + ticket information only (no guest/room).
class _OverviewTab extends StatelessWidget {
  final Ticket ticket;
  const _OverviewTab({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        TicketHeroCard(ticket: ticket),
        const SizedBox(height: 20),
        CollapsibleTicketSection(
          label: s.ticketSectionInformation,
          rows: [
            TicketInfoRow(
              label: s.ticketFieldId,
              value: ticket.opsTicketId,
            ),
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
              value: ticket.source == null ? '—' : _sourceLabel(s, ticket.source!),
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
}

/// Orders tab: hero card + order details for catalog or universal tickets.
class _OrdersTab extends StatelessWidget {
  final Ticket ticket;
  const _OrdersTab({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        TicketHeroCard(ticket: ticket),
        const SizedBox(height: 20),
        if (ticket.kindData is CatalogKindData)
          _CatalogOrderSection(ticket: ticket, data: ticket.kindData as CatalogKindData)
        else if (ticket.kindData is UniversalKindData)
          _UniversalOrderSection(ticket: ticket, data: ticket.kindData as UniversalKindData)
        else
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Text(s.ticketOrdersEmpty, style: TypographyManager.textMeta),
            ),
          ),
      ],
    );
  }
}

class _CatalogOrderSection extends StatelessWidget {
  final Ticket ticket;
  final CatalogKindData data;
  const _CatalogOrderSection({required this.ticket, required this.data});
  String _formatMoney(double amount, String currency) {
    final upper = currency.toUpperCase();
    final formatted = amount.toStringAsFixed(2);
    if (upper == 'USD' || upper.isEmpty) return '\$$formatted';
    return '$formatted $upper';
  }
  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    final s = context.l10n;

    // Extract rich items from kindData if available via the cached MyTicket items
    // The itemNames/itemThumbnails are parallel lists — zip them for display.
    final itemCount = data.itemNames.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Items section
        Text(
          s.ticketOrderItems(itemCount),
          style: TypographyManager.textMeta.copyWith(color: c.fgMuted, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: CardDecoration.standard(
            colors: c,
            borderRadius: BorderRadius.circular(12),
            backgroundColor: c.bgSubtle,
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: itemCount,
            separatorBuilder: (_, __) => Divider(height: 1, color: c.borderBase),
            itemBuilder: (context, i) {
              final name = data.itemNames[i];
              final quantity = data.itemCount;

              final thumb = i < data.itemThumbnails.length ? data.itemThumbnails[i] : null;
              return _CatalogItemRow(
                name: name,
                quantity: quantity.toString(),
                imageUrl: thumb,
                lineIndex: i + 1,
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        // Order header card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: CardDecoration.standard(
            colors: c,
            borderRadius: BorderRadius.circular(12),
            backgroundColor: c.bgSubtle,
          ),
          child: Column(
            children: [
              // Catalog name + logo row
              Row(
                children: [
                  if (data.logoUrl != null && data.logoUrl!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        data.logoUrl!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    )
                  else
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: c.bgHover,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(LucideIcons.shoppingBag, size: 20, color: c.fgMuted),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      data.catalogName,
                      style: TypographyManager.textBodyStrong.copyWith(color: c.fgBase),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _OrderInfoRow(label: s.ticketFieldDepartment, value: ticket.departmentName ?? ticket.department.label(s)),
              _OrderInfoRow(label: s.ticketFieldRoom, value: s.ticketRoomNumber(ticket.room.number)),
              _OrderInfoRow(label: s.ticketFieldGuest, value: ticket.guest?.displayName ?? '—'),
              if (ticket.source != null)
                _OrderInfoRow(label: s.ticketFieldSource, value: _sourceLabel(s, ticket.source!)),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(s.ticketOrderTotal,
                      style: TypographyManager.textBodyStrong.copyWith(color: c.fgBase, fontWeight: FontWeight.w700)),
                  Text(
                    _formatMoney(data.grandTotal, data.currency),
                    style: TypographyManager.textBodyStrong.copyWith(color: c.fgBase, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CatalogItemRow extends StatelessWidget {
  final String name;
  final String quantity;
  final String? imageUrl;
  final int lineIndex;
  const _CatalogItemRow({required this.name, required this.quantity, this.imageUrl, required this.lineIndex});

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Thumbnail
          if (imageUrl != null && imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl!,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _ItemPlaceholder(c: c),
              ),
            )
          else
            _ItemPlaceholder(c: c),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#$lineIndex',
                  style: TypographyManager.textMeta.copyWith(color: c.fgMuted),
                ),
                Text(name,
                    style: TypographyManager.textBodyStrong.copyWith(
                      color: c.fgBase,
                      fontWeight: FontWeight.w600,
                    )),
                Text('Quantity: $quantity',
                  style: TypographyManager.textMeta.copyWith(color: c.fgMuted),),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemPlaceholder extends StatelessWidget {
  final AppColors c;
  const _ItemPlaceholder({required this.c});
  @override
  Widget build(BuildContext context) => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(color: c.bgHover, borderRadius: BorderRadius.circular(8)),
    child: Icon(LucideIcons.package, size: 20, color: c.fgMuted),
  );
}

class _UniversalOrderSection extends StatelessWidget {
  final Ticket ticket;
  final UniversalKindData data;
  const _UniversalOrderSection({required this.ticket, required this.data});

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    final s = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: CardDecoration.standard(
            colors: c,
            borderRadius: BorderRadius.circular(12),
            backgroundColor: c.bgSubtle,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  if (data.emoji != null && data.emoji!.isNotEmpty)
                    Text(data.emoji!, style: const TextStyle(fontSize: 32))
                  else if (data.thumbnailUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        data.thumbnailUrl!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    )
                  else
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: c.bgHover, borderRadius: BorderRadius.circular(8)),
                      child: Icon(LucideIcons.bell, size: 20, color: c.fgMuted),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      data.displayName,
                      style: TypographyManager.textBodyStrong.copyWith(color: c.fgBase),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _OrderInfoRow(label: s.ticketFieldDepartment, value: ticket.departmentName ?? ticket.department.label(s)),
              _OrderInfoRow(label: s.ticketFieldRoom, value: s.ticketRoomNumber(ticket.room.number)),
              _OrderInfoRow(label: s.ticketFieldGuest, value: ticket.guest?.displayName ?? '—'),
              if (ticket.source != null)
                _OrderInfoRow(label: s.ticketFieldSource, value: _sourceLabel(s, ticket.source!)),
            ],
          ),
        ),
        if (ticket.note != null && ticket.note!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            s.ticketFieldConversation,
            style: TypographyManager.textMeta.copyWith(color: c.fgMuted, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: CardDecoration.standard(
              colors: c,
              borderRadius: BorderRadius.circular(12),
              backgroundColor: c.bgSubtle,
            ),
            child: Text(ticket.note!, style: TypographyManager.textBody.copyWith(color: c.fgBase)),
          ),
        ],
      ],
    );
  }
}

/// A simple label/value row used inside order cards.
class _OrderInfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _OrderInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TypographyManager.textMeta.copyWith(color: c.fgMuted)),
          Text(value,
              style: TypographyManager.textMeta.copyWith(color: c.fgBase, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

/// Guest tab: hero card + guest & room section.
class _GuestTab extends StatelessWidget {
  final Ticket ticket;
  const _GuestTab({required this.ticket});

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
      ],
    );
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
