import 'package:flutter/material.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/theme/card_theme.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/typography_manager.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/models/ticket.dart';
import 'start_work_confirmation_bottom_sheet.dart';

/// Card used in the dashboard list. Left coloured stripe encodes status,
/// title + meta + chips + footer follow the prototype.
class TicketCard extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback? onTap;

  const TicketCard({super.key, required this.ticket, this.onTap});

  Color _stripeColor(BuildContext context) {
    final c = context.appColors;
    if (ticket.isOverdue) return c.fgDanger;
    switch (ticket.status) {
      case TicketStatus.done:
        return c.fgSuccess;
      case TicketStatus.inProgress:
      case TicketStatus.accepted:
      case TicketStatus.onHold:
        return c.brandPrimary;
      case TicketStatus.canceled:
        return c.fgMuted;
      case TicketStatus.incoming:
        return c.brandPrimary;
      case TicketStatus.backlog:
        return c.fgMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${ticket.code} ${ticket.title}',
      child: Material(
        color: context.appColors.bgBase,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: CardDecoration.standard(
              colors: context.themeColors,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title row with small colored dot and optional price on right
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(right: 10, top: 4),
                        decoration: BoxDecoration(
                          color: _stripeColor(context),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          ticket.title,
                          style: TypographyManager.cardTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // placeholder for price/amount if showable
                      // keep space but hide if not available
                      const SizedBox(width: 8),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Meta row: room, department, time
                  _MetaRow(ticket: ticket),
                  const SizedBox(height: 8),

                  // Item preview row (avatar + item title + small subtitle)
                  if (ticket.items.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: context.appColors.bgSubtle,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.appColors.borderBase),
                      ),
                      child: Row(
                        children: [
                          // avatar / thumbnail
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: context.appColors.bgSubtle,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.restaurant_menu_rounded,
                              size: 18,
                              color: context.appColors.fgSubtle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ticket.items.first.title,
                                  style: TypographyManager.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  ticket.items.first.subtitle,
                                  style: TypographyManager.bodySmall.copyWith(
                                    color: context.appColors.fgSubtle,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () =>
                                _showStartWorkConfirmation(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.appColors.tagBlueText,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              minimumSize: const Size(96, 36),
                            ),
                            icon: Icon(
                              Icons.play_arrow,
                              size: 16,
                              color: context.appColors.fgOnBrand,
                            ),
                            label: Text(
                              context.l10n.ticketActionStartWork,
                              style: TypographyManager.labelSmall.copyWith(
                                color: context.appColors.fgOnBrand,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 10),
                  // Footer: status badge and optional ETA
                  Row(
                    children: [
                      _StatusBadge(ticket: ticket),
                      const Spacer(),
                      if (ticket.eta != null &&
                          ticket.status != TicketStatus.done)
                        _EtaBadge(eta: ticket.eta!, overdue: ticket.isOverdue),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showStartWorkConfirmation(BuildContext context) {
    showStartWorkConfirmation(context: context);
  }
}

// ignore: unused_element
class _CardBody extends StatelessWidget {
  final Ticket ticket;
  const _CardBody({required this.ticket});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _TitleRow(ticket: ticket),
        const SizedBox(height: 6),
        _MetaRow(ticket: ticket),
        const SizedBox(height: 10),
        _FooterRow(ticket: ticket),
      ],
    );
  }
}

class _TitleRow extends StatelessWidget {
  final Ticket ticket;
  const _TitleRow({required this.ticket});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            ticket.title,
            style: TypographyManager.cardTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        _KindChip(kind: ticket.kind),
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  final Ticket ticket;
  const _MetaRow({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final parts = <String>[
      s.roomNumber(ticket.room.number),
      ticket.department.label(s),
      AppDateUtils.relative(ticket.createdAt),
    ];
    return Text(
      parts.join('  ·  '),
      style: TypographyManager.cardMeta,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _FooterRow extends StatelessWidget {
  final Ticket ticket;
  const _FooterRow({required this.ticket});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatusBadge(ticket: ticket),
        const Spacer(),
        if (ticket.eta != null && ticket.status != TicketStatus.done)
          _EtaBadge(eta: ticket.eta!, overdue: ticket.isOverdue),
      ],
    );
  }
}

class _KindChip extends StatelessWidget {
  final TicketKind kind;
  const _KindChip({required this.kind});

  ({String label, Color bg, Color fg}) _spec(BuildContext context, AppLocalizations s) {
    final c = context.appColors;
    switch (kind) {
      case TicketKind.universal:
        return (
          label: s.chipUniversal,
          bg: c.brandPrimaryTint,
          fg: c.brandPrimaryHover,
        );
      case TicketKind.catalog:
        return (
          label: s.chipCatalog,
          bg: c.tagBlueBg,
          fg: c.tagBlueText,
        );
      case TicketKind.manual:
        return (
          label: s.chipManual,
          bg: c.tagOrangeBg,
          fg: c.tagOrangeText,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final spec = _spec(context, context.l10n);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: spec.bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        spec.label,
        style: TypographyManager.labelSmall.copyWith(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: spec.fg,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final Ticket ticket;
  const _StatusBadge({required this.ticket});

  ({String label, Color color}) _spec(BuildContext context, AppLocalizations s) {
    final c = context.appColors;
    if (ticket.isOverdue) {
      return (label: s.statusOverdue, color: c.fgDanger);
    }
    switch (ticket.status) {
      case TicketStatus.incoming:
        return (
          label: ticket.assigneeName == null ? s.statusUnassigned : s.statusNew,
          color: c.fgMuted,
        );
      case TicketStatus.accepted:
        return (label: s.statusAccepted, color: c.brandPrimary);
      case TicketStatus.inProgress:
        return (label: s.statusInProgress, color: c.brandPrimary);
      case TicketStatus.done:
        return (label: s.statusDone, color: c.fgSuccess);
      case TicketStatus.canceled:
        return (label: s.statusCancelled, color: c.fgMuted);
      case TicketStatus.onHold:
        return (label: s.ticketStatusBadgeOnHold, color: c.brandPrimary);
      case TicketStatus.backlog:
        return (label: s.subTabBacklog, color: c.fgMuted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final spec = _spec(context, context.l10n);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: spec.color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          spec.label,
          style: TypographyManager.labelSmall.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: spec.color,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class _EtaBadge extends StatelessWidget {
  final DateTime eta;
  final bool overdue;
  const _EtaBadge({required this.eta, required this.overdue});

  String _label(AppLocalizations s) {
    final delta = eta.difference(DateTime.now());
    if (delta.isNegative) return s.etaShortNow;
    if (delta.inMinutes < 60) return s.etaShortMinutes(delta.inMinutes);
    final hours = delta.inMinutes ~/ 60;
    return s.etaShortHours(hours);
  }

  @override
  Widget build(BuildContext context) {
    final color = overdue
        ? context.appColors.fgDanger
        : context.appColors.brandPrimary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.schedule_rounded, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          _label(context.l10n),
          style: TypographyManager.labelSmall.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}
