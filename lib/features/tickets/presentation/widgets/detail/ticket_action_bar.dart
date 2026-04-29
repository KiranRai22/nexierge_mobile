import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/i18n/l10n_extension.dart';
import '../../../../../core/theme/unified_theme_manager.dart';
import '../../../../../core/theme/typography_manager.dart';
import '../../../domain/models/ticket.dart';
import '../../providers/ticket_detail_controller.dart';
import 'eta_bottom_sheet.dart';

/// Persistent bottom action bar for the ticket detail screen.
///
/// Layout:
///   [ ▶ Start Work / Resume / Complete ]   <- primary, full-width, dark
///   [ Change Due ] [ Cancel ] [ Reset ]    <- secondary outline row
///
/// Primary action label is driven by [Ticket.status]:
///   - incoming/accepted -> Start Work (Accept & start)
///   - inProgress        -> Complete   (Mark done)
///   - done/cancelled    -> hidden
class TicketActionBar extends ConsumerStatefulWidget {
  final Ticket ticket;
  const TicketActionBar({super.key, required this.ticket});

  @override
  ConsumerState<TicketActionBar> createState() => _TicketActionBarState();
}

class _TicketActionBarState extends ConsumerState<TicketActionBar> {
  bool _busy = false;

  Future<void> _withGuard(Future<void> Function() task) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await task();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onPrimary() async {
    final t = widget.ticket;
    if (t.status == TicketStatus.inProgress ||
        t.status == TicketStatus.accepted) {
      await _withGuard(
        () => ref.read(ticketActionsProvider).markDone(t.id),
      );
      return;
    }
    final picked = await EtaBottomSheet.show(context, ticketCode: t.code);
    if (picked == null) return;
    await _withGuard(
      () => ref.read(ticketActionsProvider).accept(t.id, picked),
    );
  }

  Future<void> _onCancel() async {
    await _withGuard(
      () => ref.read(ticketActionsProvider).cancel(widget.ticket.id),
    );
  }

  void _onChangeDue() {
    // Reuses the ETA picker — extending due time is the same domain action.
    EtaBottomSheet.show(context, ticketCode: widget.ticket.code).then((d) {
      if (d == null) return;
      ref.read(ticketActionsProvider).accept(widget.ticket.id, d);
    });
  }

  void _onReset() {
    // Soft reset: hide for now; backend wiring lands when status reset is
    // exposed by the repository. Avoids dead UI by giving feedback.
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.comingSoonNotifications)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    final s = context.l10n;
    final t = widget.ticket;
    final isFinal =
        t.status == TicketStatus.done || t.status == TicketStatus.cancelled;
    if (isFinal) return const SizedBox.shrink();

    final primaryLabel = switch (t.status) {
      TicketStatus.inProgress => s.ticketActionComplete,
      TicketStatus.accepted => s.ticketActionStartWork,
      _ => s.ticketActionStartWork,
    };

    return Material(
      color: c.bgBase,
      elevation: 0,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _busy ? null : _onPrimary,
                icon: const Icon(LucideIcons.circlePlay, size: 18),
                label: Text(primaryLabel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.buttonInverted,
                  foregroundColor: c.fgOnInverted,
                  disabledBackgroundColor: c.bgDisabled,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: TypographyManager.textBodyStrong,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _SecondaryButton(
                    icon: LucideIcons.calendarClock,
                    label: s.ticketActionChangeDue,
                    onTap: _busy ? null : _onChangeDue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SecondaryButton(
                    icon: LucideIcons.circleX,
                    label: s.ticketActionCancel,
                    onTap: _busy ? null : _onCancel,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SecondaryButton(
                    icon: LucideIcons.rotateCcw,
                    label: s.ticketActionReset,
                    onTap: _busy ? null : _onReset,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _SecondaryButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: c.fgBase,
        side: BorderSide(color: c.borderBase),
        minimumSize: const Size.fromHeight(44),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: TypographyManager.textLabel,
      ),
    );
  }
}
