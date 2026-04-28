import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/typography_manager.dart';
import '../../../../core/utils/date_utils.dart';
import '../../domain/models/ticket.dart';
import '../providers/ticket_detail_controller.dart';

/// Updated ticket card with colored kind chips and inline Start Work / Complete
/// button. Used by [TicketsScreenNew].
class TicketCardNew extends ConsumerWidget {
  final Ticket ticket;
  final VoidCallback? onTap;

  const TicketCardNew({super.key, required this.ticket, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.appColors;
    return Semantics(
      button: true,
      label: '${ticket.code} ${ticket.title}',
      child: Material(
        color: c.bgBase,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.borderBase),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title row with kind chip and optional action button
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TicketKindChip(ticket: ticket),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ticket.title,
                          style: TypographyManager.cardTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_shouldShowActionButton(ticket)) ...[
                        const SizedBox(width: 8),
                        _ActionButton(ticket: ticket),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Meta row: room · department · time
                  _MetaRow(ticket: ticket),

                  // Item preview row (if items exist)
                  if (ticket.items.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: c.bgSubtle,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: c.borderBase),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: c.bgComponent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              _itemIcon(ticket.items.first),
                              size: 16,
                              color: c.fgMuted,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  ticket.items.first.title,
                                  style: TypographyManager.bodyMedium.copyWith(
                                    color: c.fgBase,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (ticket.items.first.subtitle.isNotEmpty)
                                  Text(
                                    ticket.items.first.subtitle,
                                    style: TypographyManager.bodySmall.copyWith(
                                      color: c.fgMuted,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          if (ticket.items.length > 1)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: c.bgComponent,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '+${ticket.items.length - 1}',
                                style: TypographyManager.labelSmall.copyWith(
                                  color: c.fgMuted,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _shouldShowActionButton(Ticket ticket) {
    return ticket.status == TicketStatus.incoming ||
        ticket.status == TicketStatus.accepted ||
        ticket.status == TicketStatus.inProgress;
  }

  IconData _itemIcon(dynamic item) {
    final title = (item.title as String).toLowerCase();
    if (title.contains('towel')) return LucideIcons.droplets;
    if (title.contains('pillow')) return LucideIcons.bed;
    if (title.contains('water')) return LucideIcons.droplet;
    if (title.contains('food')) return LucideIcons.utensils;
    return LucideIcons.package;
  }
}

class _TicketKindChip extends StatelessWidget {
  final Ticket ticket;
  const _TicketKindChip({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final s = context.l10n;

    final Color bg;
    final Color fg;
    final String label;

    switch (ticket.kind) {
      case TicketKind.universal:
        bg = c.tagBlueBg;
        fg = c.tagBlueText;
        label = s.ticketKindUniversal;
      case TicketKind.catalog:
        bg = c.tagGreenBg;
        fg = c.tagGreenText;
        label = s.ticketKindCatalog;
      case TicketKind.manual:
        bg = c.tagOrangeBg;
        fg = c.tagOrangeText;
        label = s.ticketKindManual;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TypographyManager.labelSmall.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _ActionButton extends ConsumerWidget {
  final Ticket ticket;
  const _ActionButton({required this.ticket});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.appColors;
    final s = context.l10n;

    final String label;
    switch (ticket.status) {
      case TicketStatus.incoming:
      case TicketStatus.accepted:
        label = s.ticketActionStartWork;
      case TicketStatus.inProgress:
        label = s.ticketActionComplete;
      default:
        return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        if (ticket.status == TicketStatus.inProgress) {
          ref.read(ticketActionsProvider).markDone(ticket.id);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: c.tagPurpleBg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.circlePlay, size: 12, color: c.tagPurpleText),
            const SizedBox(width: 4),
            Text(
              label,
              style: TypographyManager.labelSmall.copyWith(
                color: c.tagPurpleText,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final Ticket ticket;
  const _MetaRow({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final s = context.l10n;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: c.bgComponent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            s.roomNumber(ticket.room.number),
            style: TypographyManager.labelSmall.copyWith(
              color: c.fgBase,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          ticket.department.label(s),
          style: TypographyManager.cardMeta.copyWith(color: c.fgMuted),
        ),
        const Spacer(),
        Text(
          AppDateUtils.relative(ticket.createdAt),
          style: TypographyManager.cardMeta.copyWith(color: c.fgMuted),
        ),
      ],
    );
  }
}
