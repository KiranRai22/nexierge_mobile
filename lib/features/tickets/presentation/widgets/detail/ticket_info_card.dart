import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/typography_manager.dart';

/// One row inside `TicketInfoCard`: left label, right value (text or chip).
///
/// Trailing can be a plain string (rendered as muted body) or a custom
/// [Widget] (e.g. status pill, leading-dot department label).
class TicketInfoRow {
  final String label;
  final String? value;
  final Widget? trailing;

  const TicketInfoRow({required this.label, this.value, this.trailing})
    : assert(
        value != null || trailing != null,
        'Either value or trailing must be provided',
      );
}

/// Card containing a vertical list of `TicketInfoRow`s separated by hairline
/// dividers — used for both "GUEST & ROOM" and "TICKET INFORMATION".
///
/// Padding, divider, typography are theme-driven so the card stays in lock
/// step with the design tokens.
class TicketInfoCard extends StatelessWidget {
  final List<TicketInfoRow> rows;
  const TicketInfoCard({super.key, required this.rows});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      decoration: BoxDecoration(
        color: c.bgSubtle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.borderBase),
      ),
      child: Column(children: [for (final row in rows) _Row(row: row)]),
    );
  }
}

class _Row extends StatelessWidget {
  final TicketInfoRow row;
  const _Row({required this.row});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              row.label,
              style: TypographyManager.textBody.copyWith(color: c.fgBase),
            ),
          ),
          const SizedBox(width: 12),
          if (row.trailing != null)
            row.trailing!
          else
            Text(
              row.value ?? '—',
              textAlign: TextAlign.right,
              style: TypographyManager.textBody.copyWith(color: c.fgMuted),
            ),
        ],
      ),
    );
  }
}

/// Section overline ("GUEST & ROOM" / "TICKET INFORMATION").
class TicketSectionLabel extends StatelessWidget {
  final String label;
  const TicketSectionLabel({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 0, 2, 8),
      child: Text(
        label,
        style: TypographyManager.textMicro.copyWith(
          color: c.fgMuted,
          letterSpacing: 1.0,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Department row trailing widget: small coloured dot + department name.
class DepartmentValue extends StatelessWidget {
  final Color dotColor;
  final String label;
  const DepartmentValue({
    super.key,
    required this.dotColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TypographyManager.textBody.copyWith(color: c.fgBase),
        ),
      ],
    );
  }
}

/// Status pill used inside the info card (right-aligned trailing).
class TicketInfoStatusPill extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const TicketInfoStatusPill({
    super.key,
    required this.label,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TypographyManager.textMicro.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
