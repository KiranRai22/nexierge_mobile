import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/services/sound_manager.dart';
import '../../../../../core/theme/card_theme.dart';
import '../../../../../core/theme/unified_theme_manager.dart';
import '../../../../../core/theme/typography_manager.dart';

/// One row inside `TicketInfoCard`: left label, right value (text or chip).
///
/// Trailing can be a plain string (rendered as muted body) or a custom
/// [Widget] (e.g. status pill, leading-dot department label).
///
/// [compactValue] is the plain-text representation used by
/// [CollapsibleTicketSection] when the section is collapsed. Required for
/// rows that use a custom [trailing] (status pill, department dot) since
/// the collapsed summary can't render arbitrary widgets. Falls back to
/// [value] when omitted.
class TicketInfoRow {
  final String label;
  final String? value;
  final Widget? trailing;
  final String? compactValue;

  const TicketInfoRow({
    required this.label,
    this.value,
    this.trailing,
    this.compactValue,
  }) : assert(
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
    final c = context.themeColors;
    return Container(
      decoration: CardDecoration.standard(
        colors: c,
        borderRadius: BorderRadius.circular(12),
        backgroundColor: c.bgSubtle,
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
    final c = context.themeColors;
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

/// Section overline ("GUEST & ROOM" / "TICKET INFORMATION"). When wired up
/// to a [CollapsibleTicketSection], a chevron sits at the trailing edge.
class TicketSectionLabel extends StatelessWidget {
  final String label;

  /// When non-null, a chevron is rendered at the trailing edge that toggles
  /// section expansion. Null = static label (legacy callers).
  final bool? expanded;
  final VoidCallback? onToggle;

  const TicketSectionLabel({
    super.key,
    required this.label,
    this.expanded,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    final labelText = Text(
      label,
      style: TypographyManager.textMicro.copyWith(
        color: c.fgMuted,
        letterSpacing: 1.0,
        fontWeight: FontWeight.w600,
      ),
    );
    if (expanded == null || onToggle == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(2, 0, 2, 8),
        child: labelText,
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 0, 2, 8),
      child: Row(
        children: [
          Expanded(child: labelText),
          InkWell(
            onTap: tapSound(onToggle, SoundCategory.card),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                expanded! ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                size: 16,
                color: c.fgMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Collapsible info section. Header shows the section label + chevron at
/// the trailing edge. Tap to toggle.
///
/// Expanded → renders the rows in a [TicketInfoCard].
/// Collapsed → renders a single-line summary built from each row's
/// `compactValue` (or `value` if not provided), formatted as
/// `Label: value` joined by ` · `. Rows with empty/dash values are
/// omitted so the summary only carries information that's actually filled
/// in (e.g. `Room: #8 · Department: Front Desk` when the rest are empty).
class CollapsibleTicketSection extends StatefulWidget {
  final String label;
  final List<TicketInfoRow> rows;
  final bool initiallyExpanded;

  const CollapsibleTicketSection({
    super.key,
    required this.label,
    required this.rows,
    this.initiallyExpanded = true,
  });

  @override
  State<CollapsibleTicketSection> createState() =>
      _CollapsibleTicketSectionState();
}

class _CollapsibleTicketSectionState extends State<CollapsibleTicketSection> {
  late bool _expanded = widget.initiallyExpanded;

  String _summary() {
    final parts = <String>[];
    for (final row in widget.rows) {
      final raw = row.compactValue ?? row.value;
      final v = _normalize(raw);
      if (v == null) continue;
      parts.add('${row.label}: $v');
    }
    return parts.isEmpty ? '—' : parts.join(' · ');
  }

  String? _normalize(String? v) {
    if (v == null) return null;
    final trimmed = v.trim();
    if (trimmed.isEmpty || trimmed == '—') return null;
    return trimmed;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TicketSectionLabel(
          label: widget.label,
          expanded: _expanded,
          onToggle: () => setState(() => _expanded = !_expanded),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: _expanded
              ? TicketInfoCard(rows: widget.rows)
              : _CollapsedSummaryCard(text: _summary()),
        ),
      ],
    );
  }
}

class _CollapsedSummaryCard extends StatelessWidget {
  final String text;
  const _CollapsedSummaryCard({required this.text});

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    return Container(
      decoration: CardDecoration.standard(
        colors: c,
        borderRadius: BorderRadius.circular(12),
        backgroundColor: c.bgSubtle,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Text(
        text,
        style: TypographyManager.textBody.copyWith(color: c.fgMuted),
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
    final c = context.themeColors;
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
