import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/i18n/l10n_extension.dart';
import '../../../../../core/theme/card_theme.dart';
import '../../../../../core/theme/color_palette.dart';
import '../../../../../core/theme/unified_theme_manager.dart';
import '../../../../../core/theme/typography_manager.dart';
import '../../../../../core/time/server_clock.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../../domain/models/department.dart';
import '../../../domain/models/ticket.dart';

/// Hero card under the tabs: tool icon · title · live elapsed timer.
///
/// The elapsed counter ticks every second and is computed from the most
/// meaningful "started" timestamp (`acceptedAt` if present, else
/// `createdAt`). Stops ticking on done/cancelled.
class TicketHeroCard extends StatefulWidget {
  final Ticket ticket;
  const TicketHeroCard({super.key, required this.ticket});

  @override
  State<TicketHeroCard> createState() => _TicketHeroCardState();
}

class _TicketHeroCardState extends State<TicketHeroCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _maybeStartTimer();
  }

  @override
  void didUpdateWidget(covariant TicketHeroCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeStartTimer();
  }

  void _maybeStartTimer() {
    _timer?.cancel();
    if (_isLive) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  bool get _isLive {
    final s = widget.ticket.status;
    return s != TicketStatus.done && s != TicketStatus.canceled;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  DateTime get _start => widget.ticket.acceptedAt ?? widget.ticket.createdAt;

  DateTime get _end => widget.ticket.doneAt ?? ServerClock.now();

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    final s = context.l10n;
    final elapsed = _end.difference(_start);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: CardDecoration.standard(
        colors: c,
        borderRadius: BorderRadius.circular(12),
        backgroundColor: c.bgSubtle,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: c.bgBase,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: c.borderBase),
            ),
            alignment: Alignment.center,
            child: Icon(
              _kindIcon(widget.ticket.department),
              size: 20,
              color: c.fgBase,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.ticket.title,
                  style: TypographyManager.textBodyStrong.copyWith(
                    color: c.fgBase,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(LucideIcons.clock, size: 14, color: c.fgMuted),
                    const SizedBox(width: 4),
                    Text(
                      s.ticketElapsed(_format(elapsed)),
                      style: TypographyManager.textMeta.copyWith(
                        color: c.fgMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Right column: ticket-kind chip on top, status chip below.
          // Vertically centered via parent Row's CrossAxisAlignment.center.
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              _KindPill(kind: widget.ticket.kind),
              const SizedBox(height: 4),
              _StatusPill(status: widget.ticket.status),
            ],
          ),
        ],
      ),
    );
  }

  /// Picks a representative icon per department. Falls back to a wrench.
  IconData _kindIcon(Department d) {
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

  String _format(Duration d) {
    if (d.isNegative) d = Duration.zero;
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final sec = d.inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m}m ${sec}s';
    if (m > 0) return '${m}m ${sec}s';
    return '${sec}s';
  }
}

/// Kind chip — same visual language as the list-card `_KindChip`
/// (universal / catalog="Paid" / manual). Colours come from
/// [ColorPalette.chip*Bg/Fg] so list and detail render identically.
class _KindPill extends StatelessWidget {
  final TicketKind kind;
  const _KindPill({required this.kind});

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

/// Status chip — colour-mapped to status. Sits under [_KindPill] in the
/// hero card's right column. Uses the same theme tokens as the inline
/// status pill in the Ticket Information section so the two pills match.
class _StatusPill extends StatelessWidget {
  final TicketStatus status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    final s = context.l10n;
    final ({Color bg, Color fg, String label}) data;
    switch (status) {
      case TicketStatus.accepted:
        data = (
          bg: c.tagGreenBg,
          fg: c.tagGreenText,
          label: s.ticketStatusBadgeAccepted,
        );
      case TicketStatus.inProgress:
        data = (
          bg: c.tagGreenBg,
          fg: c.tagGreenText,
          label: s.ticketStatusBadgeInProgress,
        );
      case TicketStatus.incoming:
        data = (
          bg: c.tagBlueBg,
          fg: c.tagBlueText,
          label: s.ticketStatusBadgeNew,
        );
      case TicketStatus.done:
        data = (
          bg: c.tagNeutralBg,
          fg: c.tagNeutralText,
          label: s.ticketStatusBadgeDone,
        );
      case TicketStatus.canceled:
        data = (
          bg: c.tagRedBg,
          fg: c.tagRedText,
          label: s.ticketStatusBadgeCancelled,
        );
      case TicketStatus.onHold:
        data = (
          bg: c.tagPurpleBg,
          fg: c.tagPurpleText,
          label: s.ticketStatusBadgeOnHold,
        );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: data.bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        data.label,
        style: TypographyManager.labelSmall.copyWith(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: data.fg,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
