import 'package:flutter/material.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/theme/typography_manager.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/models/ticket.dart';

/// Card used in the dashboard list. Left coloured stripe encodes status,
/// title + meta + chips + footer follow the prototype.
class TicketCard extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback? onTap;

  const TicketCard({super.key, required this.ticket, this.onTap});

  Color get _stripeColor {
    if (ticket.isOverdue) return ColorPalette.ticketStripeOverdue;
    switch (ticket.status) {
      case TicketStatus.done:
        return ColorPalette.ticketStripeDone;
      case TicketStatus.inProgress:
      case TicketStatus.accepted:
        return ColorPalette.ticketStripeInProgress;
      case TicketStatus.cancelled:
        return ColorPalette.statusUnassigned;
      case TicketStatus.incoming:
        return ColorPalette.ticketStripeUniversal;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${ticket.code} ${ticket.title}',
      child: Material(
        color: ColorPalette.opsSurface,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: ColorPalette.opsBorder),
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
                          color: _stripeColor,
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: ColorPalette.opsSurfaceSubtle,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: ColorPalette.opsBorder),
                      ),
                      child: Row(
                        children: [
                          // avatar / thumbnail
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: ColorPalette.grey100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.restaurant_menu_rounded,
                              size: 18,
                              color: ColorPalette.textSecondary,
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
                                    color: ColorPalette.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ColorPalette.chipCatalogFg,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              minimumSize: const Size(96, 36),
                            ),
                            icon: const Icon(Icons.play_arrow, size: 16, color: Colors.white),
                            label: Text(
                              'Start Work',
                              style: TypographyManager.labelSmall.copyWith(
                                color: ColorPalette.white,
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

  ({String label, Color bg, Color fg}) _spec(AppLocalizations s) {
    switch (kind) {
      case TicketKind.universal:
        return (
          label: s.chipUniversal,
          bg: ColorPalette.chipUniversalBg,
          fg: ColorPalette.chipUniversalFg,
        );
      case TicketKind.catalog:
        return (
          label: s.chipCatalog,
          bg: ColorPalette.chipCatalogBg,
          fg: ColorPalette.chipCatalogFg,
        );
      case TicketKind.manual:
        return (
          label: s.chipManual,
          bg: ColorPalette.chipManualBg,
          fg: ColorPalette.chipManualFg,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final spec = _spec(context.l10n);
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

  ({String label, Color color}) _spec(AppLocalizations s) {
    if (ticket.isOverdue) {
      return (label: s.statusOverdue, color: ColorPalette.statusOverdue);
    }
    switch (ticket.status) {
      case TicketStatus.incoming:
        return (
          label: ticket.assigneeName == null ? s.statusUnassigned : s.statusNew,
          color: ColorPalette.statusUnassigned,
        );
      case TicketStatus.accepted:
        return (label: s.statusAccepted, color: ColorPalette.statusInProgress);
      case TicketStatus.inProgress:
        return (
          label: s.statusInProgress,
          color: ColorPalette.statusInProgress,
        );
      case TicketStatus.done:
        return (label: s.statusDone, color: ColorPalette.statusDone);
      case TicketStatus.cancelled:
        return (label: s.statusCancelled, color: ColorPalette.statusUnassigned);
    }
  }

  @override
  Widget build(BuildContext context) {
    final spec = _spec(context.l10n);
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
        ? ColorPalette.statusOverdue
        : ColorPalette.statusInProgress;
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
