import 'package:flutter/material.dart';

import '../../../../../core/i18n/l10n_extension.dart';
import '../../../../../core/theme/color_palette.dart';
import '../../../../../core/theme/typography_manager.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../../domain/models/ticket.dart';

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
        _kindChip(s),
        _deptChip(s),
      ],
    );
  }

  Widget _kindChip(AppLocalizations s) {
    String label;
    Color bg;
    Color fg;
    switch (ticket.kind) {
      case TicketKind.universal:
        label = s.chipUniversal;
        bg = ColorPalette.chipUniversalBg;
        fg = ColorPalette.chipUniversalFg;
      case TicketKind.catalog:
        label = s.chipCatalog;
        bg = ColorPalette.chipCatalogBg;
        fg = ColorPalette.chipCatalogFg;
      case TicketKind.manual:
        label = s.chipManual;
        bg = ColorPalette.chipManualBg;
        fg = ColorPalette.chipManualFg;
    }
    return _Chip(label: label, bg: bg, fg: fg);
  }

  Widget _deptChip(AppLocalizations s) {
    return _Chip(
      label: ticket.department.label(s),
      bg: ColorPalette.opsSurfaceSubtle,
      fg: ColorPalette.textPrimary,
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
