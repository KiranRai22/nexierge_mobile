import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/i18n/l10n_extension.dart';
import '../../../../../core/theme/unified_theme_manager.dart';
import '../../../../../core/theme/typography_manager.dart';
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
    return s != TicketStatus.done && s != TicketStatus.cancelled;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  DateTime get _start => widget.ticket.acceptedAt ?? widget.ticket.createdAt;

  DateTime get _end => widget.ticket.doneAt ?? DateTime.now();

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    final s = context.l10n;
    final elapsed = _end.difference(_start);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.bgSubtle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.borderBase),
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
