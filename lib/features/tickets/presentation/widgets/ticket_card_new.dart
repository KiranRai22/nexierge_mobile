import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/theme/unified_theme_manager.dart';
import '../../../../core/theme/typography_manager.dart';
import '../../domain/models/department.dart';
import '../../domain/models/ticket.dart';

/// Ticket card matching the image design.
/// Layout: Title row → Room row → Inner card → Bottom row (tag + button)
/// Used by [TicketsScreenNew].
class TicketCardNew extends ConsumerWidget {
  final Ticket ticket;
  final VoidCallback? onTap;
  final VoidCallback? onAccept;

  const TicketCardNew({
    super.key,
    required this.ticket,
    this.onTap,
    this.onAccept,
  });

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
        child: GestureDetector(
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
                  const SizedBox(height: 6),
                  // Room row: icon + room + department
                  _RoomRow(ticket: ticket),
                  const SizedBox(height: 12),
                  // Inner card with avatar, details
                  _InnerCard(ticket: ticket),
                  const SizedBox(height: 12),
                  // Bottom row: tag (left) + action button (right)
                  _BottomRow(ticket: ticket, onAccept: onAccept),
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
        // Status dot
        _StatusDot(ticket: ticket),
        const SizedBox(width: 8),
        // Title with item count
        Expanded(
          child: Text(
            _buildTitle(ticket),
            style: TypographyManager.cardTitle.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        // Timer or Done time
        _TimeDisplay(ticket: ticket),
      ],
    );
  }

  String _buildTitle(Ticket ticket) {
    final itemCount = ticket.items.length;
    if (itemCount > 1) {
      return '${ticket.title} (x$itemCount items)';
    }
    return ticket.title;
  }
}

class _StatusDot extends StatelessWidget {
  final Ticket ticket;
  const _StatusDot({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: _getDotColor(c), shape: BoxShape.circle),
    );
  }

  Color _getDotColor(AppColors c) {
    if (ticket.department == Department.housekeeping) return c.tagPurpleIcon;
    if (ticket.department == Department.roomService) return c.tagBlueIcon;
    if (ticket.department == Department.maintenance) return c.fgMuted;
    return c.tagPurpleIcon;
  }
}

class _TimeDisplay extends StatelessWidget {
  final Ticket ticket;
  const _TimeDisplay({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    // Show done time for done tickets, otherwise show timer/age
    String timeText;
    if (ticket.status == TicketStatus.done) {
      timeText = 'Done ${_formatTime(ticket.doneAt)}';
    } else {
      timeText = _formatDuration(ticket.createdAt);
    }

    return Text(
      timeText,
      style: TypographyManager.bodySmall.copyWith(
        color: c.fgMuted,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '--:--';
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatDuration(DateTime createdAt) {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays > 0) return '${diff.inDays}d ${diff.inHours % 24}h';
    if (diff.inHours > 0) return '${diff.inHours}h ${diff.inMinutes % 60}m';
    return '${diff.inMinutes}m';
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
        Icon(LucideIcons.doorOpen, size: 14, color: c.fgMuted),
        const SizedBox(width: 4),
        Text(
          'Room ${ticket.room.number} · ${ticket.department.label(s)}',
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

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.bgSubtle,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar stack (for multiple items)
          _AvatarStack(ticket: ticket),
          const SizedBox(width: 12),
          // Details column
          Expanded(child: _InnerCardContent(ticket: ticket)),
        ],
      ),
    );
  }
}

class _AvatarStack extends StatelessWidget {
  final Ticket ticket;
  const _AvatarStack({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    final items = ticket.items;

    if (items.isEmpty) {
      return _buildFallbackAvatar(c);
    }

    if (items.length == 1) {
      return _buildAvatar(c, items.first.emoji);
    }

    // Multiple items - show overlapping avatars
    return SizedBox(
      width: 52,
      height: 40,
      child: Stack(
        children: [
          for (var i = 0; i < items.length && i < 3; i++)
            Positioned(
              left: i * 16.0,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: c.bgBase,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.borderBase, width: 2),
                ),
                child: ClipOval(
                  child: Center(
                    child: Text(
                      items[i].emoji ?? '•',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar(AppColors c, String? emoji) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: c.bgBase,
        shape: BoxShape.circle,
        border: Border.all(color: c.borderBase),
      ),
      child: ClipOval(
        child: emoji != null
            ? Center(child: Text(emoji, style: const TextStyle(fontSize: 20)))
            : Center(
                child: Icon(LucideIcons.package, size: 18, color: c.fgMuted),
              ),
      ),
    );
  }

  Widget _buildFallbackAvatar(AppColors c) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: c.bgBase,
        shape: BoxShape.circle,
        border: Border.all(color: c.borderBase),
      ),
      child: ClipOval(
        child: Center(
          child: Icon(LucideIcons.package, size: 18, color: c.fgMuted),
        ),
      ),
    );
  }
}

class _InnerCardContent extends StatelessWidget {
  final Ticket ticket;
  const _InnerCardContent({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    final items = ticket.items;

    // Row 1: Title + item count + price
    final title = items.isEmpty
        ? 'Universal request'
        : (items.length == 1 ? items.first.title : items.first.title);

    final itemCountText =
        '${items.length} ${items.length == 1 ? 'item' : 'items'}';
    final priceText = _formatPrice(ticket);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Row 1: Title · count · price
        Row(
          children: [
            Expanded(
              child: RichText(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  style: TypographyManager.bodyMedium.copyWith(
                    color: c.fgBase,
                    fontWeight: FontWeight.w600,
                  ),
                  children: [
                    TextSpan(text: title),
                    TextSpan(
                      text: ' · $itemCountText',
                      style: TypographyManager.bodyMedium.copyWith(
                        color: c.fgMuted,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (priceText.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                priceText,
                style: TypographyManager.bodyMedium.copyWith(
                  color: c.fgBase,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        // Row 2: Item names (comma separated) or department
        Text(
          _buildSubtitle(context, ticket),
          style: TypographyManager.bodySmall.copyWith(color: c.fgMuted),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  String _formatPrice(Ticket ticket) {
    if (ticket.kind != TicketKind.catalog) return '';
    final total = ticket.items.fold<double>(
      0,
      (sum, item) => sum + (item.lineTotal),
    );
    if (total <= 0) return '';
    return '\$${total.toStringAsFixed(2)}';
  }

  String _buildSubtitle(BuildContext context, Ticket ticket) {
    final items = ticket.items;
    if (items.isEmpty) {
      return ticket.department.label(context.l10n);
    }
    if (items.length == 1) {
      return items.first.subtitle;
    }
    // Multiple items - join names with comma
    return items.map((i) => i.title).join(', ');
  }
}

class _BottomRow extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback? onAccept;
  const _BottomRow({required this.ticket, this.onAccept});

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    return Row(
      children: [
        // Type tag on left
        _TypeTag(kind: ticket.kind),
        const Spacer(),
        // Action button on right
        _ActionButton(ticket: ticket, onAccept: onAccept),
      ],
    );
  }
}

class _TypeTag extends StatelessWidget {
  final TicketKind kind;
  const _TypeTag({required this.kind});

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    final s = context.l10n;

    final (bg, fg, label) = switch (kind) {
      TicketKind.universal => (
        c.tagPurpleBg,
        c.tagPurpleText,
        s.ticketKindUniversal,
      ),
      TicketKind.catalog => (c.tagBlueBg, c.tagBlueText, 'Paid'),
      TicketKind.manual => (c.tagOrangeBg, c.tagOrangeText, s.ticketKindManual),
    };

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

class _ActionButton extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback? onAccept;
  const _ActionButton({required this.ticket, this.onAccept});

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;

    return switch (ticket.status) {
      TicketStatus.done => _buildDoneBadge(c),
      TicketStatus.inProgress => _buildStartWorkButton(c),
      _ => _buildAcceptButton(c, onAccept),
    };
  }

  Widget _buildAcceptButton(AppColors c, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: c.tagPurpleIcon,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.check, size: 14, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              'Accept',
              style: TypographyManager.labelSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartWorkButton(AppColors c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: c.tagBlueIcon,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.play, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            'Start Work',
            style: TypographyManager.labelSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoneBadge(AppColors c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.tagGreenBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.check, size: 14, color: c.tagGreenText),
          const SizedBox(width: 4),
          Text(
            'Done',
            style: TypographyManager.labelSmall.copyWith(
              color: c.tagGreenText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
