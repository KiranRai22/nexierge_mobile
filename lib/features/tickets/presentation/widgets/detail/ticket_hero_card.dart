import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/i18n/l10n_extension.dart';
import '../../../../../core/theme/card_theme.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/typography_manager.dart';
import '../../../../../core/time/server_clock.dart';
import '../../../../../core/utils/date_utils.dart';
import '../../../domain/models/department.dart';
import '../../../domain/models/ticket.dart';

/// Hero card shown at the top of every detail tab.
///
/// Layout:
///   ┌───────────┬──────────────────────────────────────┐
///   │ full-bleed│ Title                      [Status]  │
///   │  image    │ Created at  Due at   Overdue by      │
///   └───────────┴──────────────────────────────────────┘
/// The image column fills the card height with BoxFit.cover.
/// No inner padding or border on the image — the card clips it.
class TicketHeroCard extends StatelessWidget {
  final Ticket ticket;
  const TicketHeroCard({super.key, required this.ticket});

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    final radius = BorderRadius.circular(12);
    // Fixed height gives the Row bounded cross-axis constraints, avoiding the
    // CrossAxisAlignment.stretch + ListView unbounded-height crash, and prevents
    // the semantics.parentDataDirty assertion triggered by Image.network async
    // loads inside an intrinsic-height measurement context.
    return SizedBox(
      height: 110,
      child: ClipRRect(
        borderRadius: radius,
        child: Container(
          decoration: CardDecoration.standard(
            colors: c,
            borderRadius: radius,
            backgroundColor: c.bgSubtle,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Column 1: full-bleed image ─────────────────────────────
              SizedBox(
                width: 88,
                child: _HeroThumbnail(ticket: ticket),
              ),
              // ── Column 2: title + status + time row ────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              ticket.title,
                              style: TypographyManager.textBodyStrong.copyWith(
                                color: c.fgBase,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StatusPill(ticket: ticket),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _HeroTimeRow(ticket: ticket),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Thumbnail (full-bleed, fills the SizedBox parent) ────────────────────────

class _HeroThumbnail extends StatelessWidget {
  final Ticket ticket;
  const _HeroThumbnail({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;

    String? imageUrl;
    String? emojiText;

    if (ticket.kind == TicketKind.universal && ticket.kindData is UniversalKindData) {
      final u = ticket.kindData as UniversalKindData;
      imageUrl = u.thumbnailUrl;
      emojiText = (u.emoji?.isNotEmpty == true) ? u.emoji : null;
    } else if (ticket.kind == TicketKind.catalog && ticket.kindData is CatalogKindData) {
      imageUrl = (ticket.kindData as CatalogKindData).logoUrl;
    }

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(ticket, emojiText, c),
      );
    }
    return _fallback(ticket, emojiText, c);
  }

  Widget _fallback(Ticket ticket, String? emojiText, AppColors c) {
    final emoji = emojiText ?? ticket.departmentEmoji;
    return Container(
      color: c.bgBase,
      alignment: Alignment.center,
      child: emoji != null && emoji.isNotEmpty
          ? Text(emoji, style: const TextStyle(fontSize: 32))
          : Icon(_deptIcon(ticket.department), size: 28, color: c.fgMuted),
    );
  }

  IconData _deptIcon(Department d) {
    switch (d) {
      case Department.maintenance:
        return LucideIcons.wrench;
      case Department.housekeeping:
        return LucideIcons.bedDouble;
      case Department.fnb:
      case Department.roomService:
        return LucideIcons.utensils;
      case Department.frontDesk:
        return LucideIcons.bellRing;
      case Department.concierge:
        return LucideIcons.bell;
    }
  }
}

// ── Status pill ────────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  final Ticket ticket;
  const _StatusPill({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    final s = context.l10n;
    late Color bg;
    late Color fg;
    late String label;

    // isOverdue takes priority over the raw API status
    if (ticket.isOverdue) {
      bg = c.tagRedBg;
      fg = c.tagRedText;
      label = s.statusOverdue;
    } else {
      switch (ticket.status) {
        case TicketStatus.incoming:
          bg = c.tagBlueBg;
          fg = c.tagBlueText;
          label = s.ticketStatusBadgeNew;
        case TicketStatus.accepted:
          bg = c.tagGreenBg;
          fg = c.tagGreenText;
          label = s.ticketStatusBadgeAccepted;
        case TicketStatus.inProgress:
          bg = c.tagGreenBg;
          fg = c.tagGreenText;
          label = s.ticketStatusBadgeInProgress;
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
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TypographyManager.labelSmall.copyWith(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: fg,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ── Live time row ──────────────────────────────────────────────────────────────
//
// Mirrors the compact-card Row 3 format:
//   Created at    Due at        Overdue by / Time left / Grace Period
//   08:00 AM     09:15 PM      15m 20s

class _HeroTimeRow extends StatefulWidget {
  final Ticket ticket;
  const _HeroTimeRow({required this.ticket});

  @override
  State<_HeroTimeRow> createState() => _HeroTimeRowState();
}

class _HeroTimeRowState extends State<_HeroTimeRow> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final s = widget.ticket.status;
    if (s != TicketStatus.done && s != TicketStatus.canceled) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    final s = context.l10n;
    final ticket = widget.ticket;
    final now = ServerClock.now();

    final isOverdue = ticket.isOverdue;
    final isDone = ticket.status == TicketStatus.done ||
        ticket.status == TicketStatus.canceled;
    final isInProgress = ticket.status == TicketStatus.inProgress ||
        ticket.status == TicketStatus.accepted;

    final displayDue = ticket.eta ?? ticket.dueAtWithGrace;
    final dueColor = (!isDone && isOverdue) ? context.appColors.fgDanger : c.fgMuted;

    Widget? indicator;
    if (!isDone) {
      if (!isOverdue) {
        final deadline = ticket.dueAtWithGrace ?? ticket.eta;
        if (deadline != null) {
          final timeLeft = deadline.difference(now);
          indicator = _TwoLineTime(
            label: s.ticketTimeLeftLabel,
            value: _fmt(timeLeft.isNegative ? Duration.zero : timeLeft),
            color: context.appColors.brandPrimary,
            alignEnd: true,
          );
        }
      } else if (isInProgress) {
        indicator = _TwoLineTime(
          label: s.ticketTimeLeftLabel,
          value: s.ticketGracePeriod,
          color: c.tagOrangeIcon,
          alignEnd: true,
        );
      } else {
        final overdueRef = ticket.dueAtWithGrace ?? ticket.eta;
        final overdueBy = overdueRef != null ? now.difference(overdueRef) : Duration.zero;
        indicator = _TwoLineTime(
          label: s.ticketOverdueByLabel,
          value: _fmt(overdueBy.isNegative ? Duration.zero : overdueBy),
          color: context.appColors.fgDanger,
          alignEnd: true,
        );
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: c.bgBase,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TwoLineTime(
            label: s.ticketCreatedAt,
            value: AppDateUtils.clock(ticket.createdAt),
            color: c.fgMuted,
          ),
          if (displayDue != null) ...[
            const SizedBox(width: 14),
            _TwoLineTime(
              label: s.ticketDueAt,
              value: AppDateUtils.clock(displayDue),
              color: dueColor,
            ),
          ],
          const Spacer(),
          if (indicator != null) indicator,
        ],
      ),
    );
  }

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final sec = d.inSeconds % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m ${sec}s';
  }
}

class _TwoLineTime extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool alignEnd;
  const _TwoLineTime({
    required this.label,
    required this.value,
    required this.color,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TypographyManager.cardMeta.copyWith(
            fontSize: 9.5,
            color: c.fgSubtle,
          ),
        ),
        Text(
          value,
          style: TypographyManager.labelSmall.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

