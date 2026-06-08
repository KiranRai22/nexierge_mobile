import 'package:flutter/material.dart';

import '../../../../../core/i18n/l10n_extension.dart';
import '../../../../../core/theme/typography_manager.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../../domain/models/ticket.dart';
import '../../../../../core/theme/app_colors.dart';

/// Top-of-detail chips row: kind, department.
class HeaderChips extends StatelessWidget {
  final Ticket ticket;
  const HeaderChips({super.key, required this.ticket});

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _kindChip(context, s),
        _deptChip(context, s),
      ],
    );
  }

  Widget _kindChip(BuildContext context, AppLocalizations s) {
    final c = context.appColors;
    String label;
    Color bg;
    Color fg;
    switch (ticket.kind) {
      case TicketKind.universal:
        label = s.chipUniversal;
        bg = c.brandPrimaryTint;
        fg = c.brandPrimaryHover;
      case TicketKind.catalog:
        label = s.chipCatalog;
        bg = c.tagBlueBg;
        fg = c.tagBlueText;
      case TicketKind.manual:
        label = s.chipManual;
        bg = c.tagOrangeBg;
        fg = c.tagOrangeText;
    }
    return _Chip(label: label, bg: bg, fg: fg);
  }

  Widget _deptChip(BuildContext context, AppLocalizations s) {
    final c = context.appColors;
    return _Chip(
      label: ticket.department.label(s),
      bg: c.bgSubtle,
      fg: c.fgBase,
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _Chip({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TypographyManager.labelSmall.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
