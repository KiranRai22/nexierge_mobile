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

/// Hero card under the tabs: tool icon · title · status pill.
///
/// Shows a status pill (New, In Progress, Overdue, etc.) with proper colors
/// and a resolution time chip in the right column.
class TicketHeroCard extends StatelessWidget {
  final Ticket ticket;
  const TicketHeroCard({super.key, required this.ticket});

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
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
              _kindIcon(ticket.department),
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
                  ticket.title,
                  style: TypographyManager.textBodyStrong.copyWith(
                    color: c.fgBase,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                _ElapsedTimeRow(ticket: ticket),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Right column: ticket kind pill (Manual/Universal/Paid)
          _KindPill(kind: ticket.kind),
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
}

/// Elapsed/overdue time row showing live timer.
/// Shows elapsed time for new, overdue time for overdue tickets.
class _ElapsedTimeRow extends StatefulWidget {
  final Ticket ticket;
  const _ElapsedTimeRow({required this.ticket});

  @override
  State<_ElapsedTimeRow> createState() => _ElapsedTimeRowState();
}

class _ElapsedTimeRowState extends State<_ElapsedTimeRow> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatElapsed(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h > 0) return '${h}h ${m}m ${s}s';
    return '${m}m ${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;

    // For overdue tickets, show overdue elapsed time with red timer
    if (widget.ticket.isOverdue && widget.ticket.eta != null) {
      final overdue = ServerClock.now().difference(widget.ticket.eta!);
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.timer, size: 12, color: c.tagRedText),
          const SizedBox(width: 4),
          Text(
            'Overdue: ${_formatElapsed(overdue)}',
            style: TypographyManager.bodySmall.copyWith(
              color: c.tagRedText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    // For all other tickets, show elapsed time from creation
    final elapsed = ServerClock.now().difference(widget.ticket.createdAt);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(LucideIcons.timer, size: 12, color: c.fgMuted),
        const SizedBox(width: 4),
        Text(
          'Elapsed Time: ${_formatElapsed(elapsed)}',
          style: TypographyManager.bodySmall.copyWith(
            color: c.fgMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Ticket kind pill showing Manual/Universal/Paid.
/// Uses the same color scheme as before.
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
