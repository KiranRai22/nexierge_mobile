import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/services/sound_manager.dart';
import '../../../../core/theme/card_theme.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/theme/unified_theme_manager.dart';
import '../../../../core/theme/typography_manager.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/models/ticket.dart';
/// Compact 3-row ticket card — fits 4+ cards on screen vs the original 2.
///
/// Layout:
///   Row 1: [● dot] #code · title  ──spacer──  [STATUS badge]  [Accept btn?]
///   Row 2: [icon] itemType · Department · Rm X
///   Row 3: Created HH:MM  Due HH:MM  ──spacer──  Time left Xm / Overdue Xh
///
/// Backup card: ticket_card_new.dart (TicketCardNew). Revert by swapping
/// the import + widget name in tickets_screen_new.dart.
class TicketCardCompact extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback? onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onStartWork;
  final VoidCallback? onMarkDone;

  const TicketCardCompact({
    super.key,
    required this.ticket,
    this.onTap,
    this.onAccept,
    this.onStartWork,
    this.onMarkDone,
  });

  // ── stripe colour (same logic as original) ──────────────────────────────
  Color get _stripeColor {
    if (ticket.isOverdue) return ColorPalette.ticketStripeOverdue;
    switch (ticket.status) {
      case TicketStatus.done:
        return ColorPalette.ticketStripeDone;
      case TicketStatus.inProgress:
      case TicketStatus.accepted:
      case TicketStatus.onHold:
        return ColorPalette.ticketStripeInProgress;
      case TicketStatus.canceled:
      case TicketStatus.backlog:
        return ColorPalette.statusUnassigned;
      case TicketStatus.incoming:
        return ColorPalette.ticketStripeUniversal;
    }
  }

  bool get _showAccept => ticket.status == TicketStatus.incoming;
  bool get _showMarkDone => ticket.status == TicketStatus.inProgress;
  bool get _showStartWork => ticket.status == TicketStatus.accepted;

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    final radius = BorderRadius.circular(12);

    return Semantics(
      button: true,
      label: '${ticket.code} ${ticket.title}',
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: tapSound(onTap),
          borderRadius: radius,
          child: Container(
            decoration: CardDecoration.standard(
              colors: c,
              borderRadius: radius,
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Left priority stripe ──────────────────────────────
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: _stripeColor,
                      borderRadius: BorderRadius.only(
                        topLeft: radius.topLeft,
                        bottomLeft: radius.bottomLeft,
                      ),
                    ),
                  ),
                  // ── Card content ──────────────────────────────────────
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _Row1(ticket: ticket),
                          _RowTitle(ticket: ticket),
                          const SizedBox(height: 8),
                          _Row2(
                            ticket: ticket,
                            showAccept: _showAccept,
                            showMarkDone: _showMarkDone,
                            showStartWork: _showStartWork,
                            onAccept: onAccept,
                            onMarkDone: onMarkDone,
                            onStartWork: onStartWork,
                          ),
                          const SizedBox(height: 6),
                          _Row3(ticket: ticket),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Row 1: dot + #id + title + kind badge ───────────────────────────────────

class _Row1 extends StatelessWidget {
  final Ticket ticket;
  
  const _Row1({required this.ticket});
  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    // final divider = Padding(
    //     padding: const EdgeInsets.symmetric(horizontal: 5),
    //     child: Text('·', style: TypographyManager.cardMeta.copyWith(color: c.fgSubtle)),
    //   );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Status dot
        Container(
          width: 7,
          height: 7,
          margin: const EdgeInsets.only(right: 6, top: 1),
          decoration: BoxDecoration(
            color: _dotColor(ticket),
            shape: BoxShape.circle,
          ),
        ),
        // #opsTicketId or fallback
        Expanded(
          child: Text(
            ticket.opsTicketId.isNotEmpty ? '#${ticket.opsTicketId}' : '#0000',
            style: TypographyManager.labelSmall.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: c.fgMuted,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Status badge — top-right corner
        _StatusBadge(ticket: ticket),
      ],
    );
  }

  Color _dotColor(Ticket t) {
    if (t.isOverdue) return ColorPalette.ticketStripeOverdue;
    switch (t.status) {
      case TicketStatus.done:
        return ColorPalette.ticketStripeDone;
      case TicketStatus.inProgress:
      case TicketStatus.accepted:
        return ColorPalette.ticketStripeInProgress;
      default:
        return ColorPalette.ticketStripeUniversal;
    }
  }
}

class _RowTitle extends StatelessWidget {
  final Ticket ticket;
  const _RowTitle({required this.ticket});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Title
        Expanded(
          child: Text(
            ticket.title,
            style: TypographyManager.cardTitle.copyWith(fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
// ─── Row 2: [kind badge] | dept (expanded) | [door] #room | action button ────
//
//   Col 1: kind badge (fixed)
//   Col 2: department name (Expanded, ellipsis)
//   Col 3: door icon + room number (fixed)
//   Col 4: action button — Accept / Start Work / Mark Done (fixed)

class _Row2 extends StatelessWidget {
  final Ticket ticket;
  final bool showAccept;
  final bool showMarkDone;
  final bool showStartWork;
  final VoidCallback? onAccept;
  final VoidCallback? onMarkDone;
  final VoidCallback? onStartWork;
  const _Row2({
    required this.ticket,
    this.showAccept = false,
    this.showMarkDone = false,
    this.showStartWork = false,
    this.onAccept,
    this.onMarkDone,
    this.onStartWork,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    final s = context.l10n;

    final deptLabel = ticket.departmentName ?? ticket.department.label(s);

    final metaStyle = TypographyManager.cardMeta.copyWith(fontSize: 11.5, color: c.fgMuted);
    final divider = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Text('·', style: TypographyManager.cardMeta.copyWith(color: c.fgSubtle)),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Col 1: kind badge
        _KindBadge(kind: ticket.kind),
        divider,
        // Col 2: room icon + number
        Icon(LucideIcons.doorOpen, size: 12, color: c.fgMuted),
        Text(
          ticket.room.number,
          style: metaStyle,
          maxLines: 1,
        ),
        divider,
        // Col 3: department — takes all remaining space
        Expanded(
          child: Text(
            deptLabel,
            style: metaStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 3),
        // Col 4: action button
        if (showAccept) ...[
          _AcceptButton(onAccept: onAccept),
        ] else if (showMarkDone) ...[
          _MarkDoneButton(onMarkDone: onMarkDone),
        ] else if (showStartWork) ...[
          _StartWorkButton(onStartWork: onStartWork),
        ],
      ],
    );
  }
}

// ─── Row 3: created · due · time left ────────────────────────────────────────

class _Row3 extends StatelessWidget {
  final Ticket ticket;
  const _Row3({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    final s = context.l10n;
    final overdue = ticket.isOverdue;
    final due = ticket.eta ?? ticket.dueAtWithGrace;
    final isDone = ticket.status == TicketStatus.done;

    final timeColor = overdue
        ? ColorPalette.statusOverdue
        : ColorPalette.statusInProgress;

    return Row(
      children: [
        // Created at
        _TimeChip(
          label: s.ticketCreatedAt,
          time: AppDateUtils.clock(ticket.createdAt),
          color: c.fgMuted,
        ),
        _dot(c),
        // Due at
        if (due != null) ...[
          _TimeChip(
            label: s.ticketDueAt,
            time: AppDateUtils.clock(due),
            color: overdue ? ColorPalette.statusOverdue : c.fgMuted,
          ),
        ],
        const Spacer(),
        // Time left / Overdue by — hidden on done tickets
        if (due != null && !isDone) _TimeLeftChip(eta: due, overdue: overdue, color: timeColor, s: s),
      ],
    );
  }

  Widget _dot(AppColors c) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Text(
          '·',
          style: TypographyManager.cardMeta.copyWith(color: c.fgSubtle),
        ),
      );
}

class _TimeChip extends StatelessWidget {
  final String label;
  final String time;
  final Color color;
  const _TimeChip({required this.label, required this.time, required this.color});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$label ',
            style: TypographyManager.cardMeta.copyWith(
              fontSize: 10.5,
              color: context.themeColors.fgSubtle,
            ),
          ),
          TextSpan(
            text: time,
            style: TypographyManager.cardMeta.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeLeftChip extends StatelessWidget {
  final DateTime eta;
  final bool overdue;
  final Color color;
  final AppLocalizations s;
  const _TimeLeftChip({
    required this.eta,
    required this.overdue,
    required this.color,
    required this.s,
  });

  String _label() {
    final delta = eta.difference(DateTime.now());
    if (overdue) {
      final abs = delta.abs();
      if (abs.inMinutes < 60) return s.overdueByMinutes(abs.inMinutes);
      final h = abs.inHours;
      final m = abs.inMinutes % 60;
      return m > 0 ? s.overdueByHoursMinutes(h, m) : s.overdueByHours(h);
    }
    if (delta.inMinutes < 1) return s.timeLeftNow;
    if (delta.inMinutes < 60) return s.timeLeftMinutes(delta.inMinutes);
    return s.timeLeftHours(delta.inHours);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          overdue ? LucideIcons.alertCircle : LucideIcons.clock,
          size: 12,
          color: color,
        ),
        const SizedBox(width: 3),
        Text(
          _label(),
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

// ─── Kind badge (top-right of Row 1) ─────────────────────────────────────────

class _KindBadge extends StatelessWidget {
  final TicketKind kind;
  const _KindBadge({required this.kind});

  ({IconData icon, Color bg, Color fg, String Function(AppLocalizations) label}) _spec() {
    switch (kind) {
      case TicketKind.catalog:
        return (
          icon: LucideIcons.shoppingBag,
          bg: ColorPalette.chipCatalogBg,
          fg: ColorPalette.chipCatalogFg,
          label: (s) => s.chipCatalog,
        );
      case TicketKind.universal:
        return (
          icon: LucideIcons.zap,
          bg: ColorPalette.chipUniversalBg,
          fg: ColorPalette.chipUniversalFg,
          label: (s) => s.chipUniversal,
        );
      case TicketKind.manual:
        return (
          icon: LucideIcons.pencilLine,
          bg: ColorPalette.chipManualBg,
          fg: ColorPalette.chipManualFg,
          label: (s) => s.chipManual,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final spec = _spec();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: spec.bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(spec.icon, size: 11, color: spec.fg),
          const SizedBox(width: 3),
          Text(
            spec.label(context.l10n),
            style: TypographyManager.labelSmall.copyWith(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: spec.fg,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Status badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final Ticket ticket;
  const _StatusBadge({required this.ticket});

  ({String label, Color bg, Color fg}) _spec(AppLocalizations s) {
    if (ticket.isOverdue) {
      return (
        label: s.statusOverdue,
        bg: ColorPalette.statusOverdue.withValues(alpha: 0.12),
        fg: ColorPalette.statusOverdue,
      );
    }
    switch (ticket.status) {
      case TicketStatus.incoming:
        return (
          label: s.statusNew,
          bg: ColorPalette.ticketStripeUniversal.withValues(alpha: 0.12),
          fg: ColorPalette.ticketStripeUniversal,
        );
      case TicketStatus.accepted:
        return (
          label: s.statusAccepted,
          bg: ColorPalette.statusInProgress.withValues(alpha: 0.12),
          fg: ColorPalette.statusInProgress,
        );
      case TicketStatus.inProgress:
        return (
          label: s.statusInProgress,
          bg: ColorPalette.statusInProgress.withValues(alpha: 0.12),
          fg: ColorPalette.statusInProgress,
        );
      case TicketStatus.done:
        return (
          label: s.statusDone,
          bg: ColorPalette.ticketStripeDone.withValues(alpha: 0.12),
          fg: ColorPalette.ticketStripeDone,
        );
      case TicketStatus.canceled:
        return (
          label: s.statusCancelled,
          bg: ColorPalette.statusUnassigned.withValues(alpha: 0.12),
          fg: ColorPalette.statusUnassigned,
        );
      case TicketStatus.onHold:
        return (
          label: s.ticketStatusBadgeOnHold,
          bg: ColorPalette.statusInProgress.withValues(alpha: 0.12),
          fg: ColorPalette.statusInProgress,
        );
      case TicketStatus.backlog:
        return (
          label: 'Backlog',
          bg: ColorPalette.statusUnassigned.withValues(alpha: 0.12),
          fg: ColorPalette.statusUnassigned,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final spec = _spec(context.l10n);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: spec.bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        spec.label,
        style: TypographyManager.labelSmall.copyWith(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: spec.fg,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

// ─── Action buttons ───────────────────────────────────────────────────────────

class _AcceptButton extends StatelessWidget {
  final VoidCallback? onAccept;
  const _AcceptButton({this.onAccept});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onAccept != null ? tapSound(onAccept!) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: ColorPalette.chipCatalogFg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.play_arrow_rounded, size: 13, color: Colors.white),
            const SizedBox(width: 3),
            Text(
              context.l10n.actionAcceptShort,
              style: TypographyManager.labelSmall.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarkDoneButton extends StatelessWidget {
  final VoidCallback? onMarkDone;
  const _MarkDoneButton({this.onMarkDone});

  @override
  Widget build(BuildContext context) {
    final green = context.themeColors.tagGreenIcon;
    return GestureDetector(
      onTap: onMarkDone != null ? tapSound(onMarkDone!) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: green,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.circleCheck, size: 13, color: Colors.white),
            const SizedBox(width: 3),
            Text(
              context.l10n.ticketActionMarkDone,
              style: TypographyManager.labelSmall.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StartWorkButton extends StatelessWidget {
  final VoidCallback? onStartWork;
  const _StartWorkButton({this.onStartWork});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onStartWork != null ? tapSound(onStartWork!) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: ColorPalette.chipCatalogFg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.play, size: 13, color: Colors.white),
            const SizedBox(width: 3),
            Text(
              context.l10n.ticketActionStartWork,
              style: TypographyManager.labelSmall.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
