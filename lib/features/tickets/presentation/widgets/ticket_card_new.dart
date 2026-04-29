import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/theme/unified_theme_manager.dart';
import '../../../../core/theme/typography_manager.dart';
import '../../../../core/utils/date_utils.dart';
import '../../domain/models/department.dart';
import '../../domain/models/ticket.dart';
import '../providers/ticket_detail_controller.dart';

/// Ticket card matching image design with dot indicator, timer, inner card.
/// Used by [TicketsScreenNew].
class TicketCardNew extends ConsumerWidget {
  final Ticket ticket;
  final VoidCallback? onTap;

  const TicketCardNew({super.key, required this.ticket, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.themeColors;
    return Semantics(
      button: true,
      label: '${ticket.code} ${ticket.title}',
      child: Material(
        color: c.bgBase,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.borderBase),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title row: dot + title + timer
                  _TitleRow(ticket: ticket),
                  const SizedBox(height: 8),
                  // Room row: icon + room · department
                  _RoomRow(ticket: ticket),
                  const SizedBox(height: 12),
                  // Inner card with avatar, details, tag, Accept button
                  _InnerCard(ticket: ticket),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TitleRow extends StatelessWidget {
  final Ticket ticket;
  const _TitleRow({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    return Row(
      children: [
        // Status dot - color based on department
        _StatusDot(ticket: ticket),
        const SizedBox(width: 8),
        // Title
        Expanded(
          child: Text(
            ticket.title,
            style: TypographyManager.cardTitle.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // Timer
        Text(
          '20h 14m 52s',
          style: TypographyManager.bodySmall.copyWith(
            color: c.fgMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _StatusDot extends StatelessWidget {
  final Ticket ticket;
  const _StatusDot({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    // Color based on department
    final dotColor = _getDotColor(c);
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
    );
  }

  Color _getDotColor(AppColors c) {
    if (ticket.department == Department.housekeeping) return c.tagPurpleIcon;
    if (ticket.department == Department.roomService) return c.tagBlueIcon;
    if (ticket.department == Department.maintenance) return c.fgMuted;
    return c.tagPurpleIcon;
  }
}

class _RoomRow extends StatelessWidget {
  final Ticket ticket;
  const _RoomRow({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    final s = context.l10n;
    return Row(
      children: [
        Icon(LucideIcons.building2, size: 14, color: c.fgMuted),
        const SizedBox(width: 4),
        Text(
          '${ticket.room.number} · ${ticket.department.label(s)}',
          style: TypographyManager.bodySmall.copyWith(color: c.fgMuted),
        ),
      ],
    );
  }
}

class _InnerCard extends StatelessWidget {
  final Ticket ticket;
  const _InnerCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    final s = context.l10n;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.bgSubtle,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Avatar
          _ItemAvatar(ticket: ticket),
          const SizedBox(width: 12),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title line: "Universal request · 1 item"
                RichText(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: TypographyManager.bodyMedium.copyWith(
                      color: c.fgBase,
                      fontWeight: FontWeight.w600,
                    ),
                    children: [
                      TextSpan(text: _getItemTitle(ticket)),
                      TextSpan(
                        text:
                            ' · ${ticket.items.length} ${ticket.items.length == 1 ? 'item' : 'items'}',
                        style: TypographyManager.bodyMedium.copyWith(
                          color: c.fgMuted,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                // Department
                Text(
                  ticket.department.label(s),
                  style: TypographyManager.bodySmall.copyWith(color: c.fgMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Tag pill
          _TagPill(ticket: ticket),
          const SizedBox(width: 8),
          // Accept button
          _AcceptButton(),
        ],
      ),
    );
  }

  String _getItemTitle(Ticket ticket) {
    if (ticket.items.isEmpty) return 'Request';
    // Use first item title or truncate if multiple
    final firstTitle = ticket.items.first.title;
    if (ticket.items.length == 1) return firstTitle;
    // For multiple items, show "Item (x items)" format like image
    return firstTitle;
  }
}

class _ItemAvatar extends StatelessWidget {
  final Ticket ticket;
  const _ItemAvatar({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: c.bgBase,
        shape: BoxShape.circle,
        border: Border.all(color: c.borderBase),
      ),
      child: ClipOval(child: _buildFallback(c)),
    );
  }

  Widget _buildFallback(AppColors c) {
    return Center(child: Icon(LucideIcons.package, size: 18, color: c.fgMuted));
  }
}

class _TagPill extends StatelessWidget {
  final Ticket ticket;
  const _TagPill({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    final s = context.l10n;

    // Tag based on ticket kind
    Color bg;
    Color fg;
    String label;

    switch (ticket.kind) {
      case TicketKind.universal:
        bg = c.tagPurpleBg;
        fg = c.tagPurpleText;
        label = s.ticketKindUniversal;
      case TicketKind.catalog:
        bg = c.tagBlueBg;
        fg = c.tagBlueText;
        label = 'Paid'; // Image shows "Paid" for orders
      case TicketKind.manual:
        bg = c.tagOrangeBg;
        fg = c.tagOrangeText;
        label = s.ticketKindManual;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TypographyManager.labelSmall.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _AcceptButton extends StatelessWidget {
  const _AcceptButton();

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: c.tagPurpleIcon,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.check, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            'Accept',
            style: TypographyManager.bodyMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
