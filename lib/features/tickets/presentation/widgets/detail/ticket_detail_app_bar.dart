import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/i18n/l10n_extension.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/typography_manager.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../../domain/models/ticket.dart';

/// Top bar of the ticket detail screen.
///
/// Visual:
///   ( ◀ )  TKT-0008  [ACCEPTED] [P2]                ( ✕ )
///
/// Both action buttons are circular with a subtle filled background. The
/// status pill is colour-mapped from `TicketStatus`; the priority pill is
/// colour-mapped from `TicketPriority`.
class TicketDetailAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final Ticket ticket;
  final VoidCallback onBack;
  final VoidCallback onClose;

  const TicketDetailAppBar({
    super.key,
    required this.ticket,
    required this.onBack,
    required this.onClose,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final s = context.l10n;
    return Material(
      color: c.bgBase,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            children: [
              _CircleIconButton(icon: LucideIcons.chevronLeft, onTap: onBack),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      ticket.code,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TypographyManager.textHeading.copyWith(
                        color: c.fgBase,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _StatusPill(status: ticket.status),
                        const SizedBox(width: 6),
                        _PriorityPill(priority: ticket.priority),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _CircleIconButton(
                icon: LucideIcons.x,
                onTap: onClose,
                tooltip: s.cancel,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final btn = InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: c.bgSubtle,
          shape: BoxShape.circle,
          border: Border.all(color: c.borderBase),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: c.fgBase),
      ),
    );
    return tooltip == null ? btn : Tooltip(message: tooltip!, child: btn);
  }
}

class _StatusPill extends StatelessWidget {
  final TicketStatus status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final s = context.l10n;
    final ({Color bg, Color fg, String label}) data = _resolve(c, s);
    return _Pill(bg: data.bg, fg: data.fg, label: data.label);
  }

  ({Color bg, Color fg, String label}) _resolve(
    AppColors c,
    AppLocalizations s,
  ) {
    switch (status) {
      case TicketStatus.accepted:
      case TicketStatus.inProgress:
        return (
          bg: c.tagGreenBg,
          fg: c.tagGreenText,
          label: status == TicketStatus.accepted
              ? s.ticketStatusBadgeAccepted
              : s.ticketStatusBadgeInProgress,
        );
      case TicketStatus.incoming:
        return (
          bg: c.tagBlueBg,
          fg: c.tagBlueText,
          label: s.ticketStatusBadgeIncoming,
        );
      case TicketStatus.done:
        return (
          bg: c.tagNeutralBg,
          fg: c.tagNeutralText,
          label: s.ticketStatusBadgeDone,
        );
      case TicketStatus.cancelled:
        return (
          bg: c.tagRedBg,
          fg: c.tagRedText,
          label: s.ticketStatusBadgeCancelled,
        );
    }
  }
}

class _PriorityPill extends StatelessWidget {
  final TicketPriority priority;
  const _PriorityPill({required this.priority});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final s = context.l10n;
    late Color bg;
    late Color fg;
    late String label;
    switch (priority) {
      case TicketPriority.p1:
        bg = c.tagRedBg;
        fg = c.tagRedText;
        label = s.ticketPriorityP1;
      case TicketPriority.p2:
        bg = c.tagOrangeBg;
        fg = c.tagOrangeText;
        label = s.ticketPriorityP2;
      case TicketPriority.p3:
        bg = c.tagBlueBg;
        fg = c.tagBlueText;
        label = s.ticketPriorityP3;
    }
    return _Pill(bg: bg, fg: fg, label: label);
  }
}

class _Pill extends StatelessWidget {
  final Color bg;
  final Color fg;
  final String label;
  const _Pill({required this.bg, required this.fg, required this.label});

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
