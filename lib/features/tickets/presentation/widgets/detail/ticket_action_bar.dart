import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/i18n/l10n_extension.dart';
import '../../../../../core/theme/unified_theme_manager.dart';
import '../../../../../core/theme/typography_manager.dart';
import '../../../../../shared/widgets/app_toast.dart';
import '../../../data/repositories/ticket_repository.dart';
import '../../../domain/entities/my_ticket.dart';
import '../../../domain/models/ticket.dart';
import '../../providers/my_tickets_notifier.dart';
import '../../providers/ticket_detail_controller.dart';
import '../acknowledge_ticket_bottom_sheet.dart';
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
    if (t.status == TicketStatus.incoming) {
      await _onAcceptIncoming();
      return;
    }
    if (t.status == TicketStatus.inProgress ||
        t.status == TicketStatus.accepted) {
      await _withGuard(() => ref.read(ticketActionsProvider).markDone(t.id));
      return;
    }
    final picked = await EtaBottomSheet.show(context, ticketCode: t.code);
    if (picked == null) return;
    await _withGuard(
      () => ref.read(ticketActionsProvider).accept(t.id, picked),
    );
  }

  /// NEW → ACCEPTED flow.
  ///
  /// Opens the Acknowledge sheet (preset/custom due-time), then hits the
  /// real `/tickets/update_status` endpoint. On success we patch the
  /// realtime list locally so the ticket leaves Incoming and lands in
  /// Today immediately — the websocket frame will reconcile shortly after.
  Future<void> _onAcceptIncoming() async {
    final t = widget.ticket;
    final result = await AcknowledgeTicketBottomSheet.show(
      context: context,
      ticketCode: t.code,
      ticketTitle: t.guest?.displayName ?? '',
      hasGuest: t.guest != null,
    );
    if (result == null) return;

    await _withGuard(() async {
      try {
        await ref
            .read(ticketRepositoryProvider)
            .updateTicketStatus(ticketId: t.id);
        _patchListAccepted(t.id);
        if (!mounted) return;
        Navigator.of(context).pop();
      } catch (e) {
        if (!mounted) return;
        context.showFailure(e.toString());
      }
    });
  }

  /// Optimistically transitions the ticket to ACCEPTED in the realtime
  /// list state. `upsertFromRealtime` stamps `statusChangedAt = now` when
  /// the status actually changes, so the Today filter picks it up without
  /// any extra wiring. A fresh fetch is also kicked off as a safety net.
  void _patchListAccepted(String ticketId) {
    final notifier = ref.read(myTicketsNotifierProvider.notifier);
    final current = ref.read(myTicketsNotifierProvider).valueOrNull;
    final existing = current?.all.firstWhere(
      (x) => x.id == ticketId,
      orElse: () => _emptyTicket(ticketId),
    );
    if (existing == null || existing.id.isEmpty) {
      notifier.refresh();
      return;
    }
    notifier.upsertFromRealtime(_withStatus(existing, 'ACCEPTED'));
    notifier.refresh();
  }

  MyTicket _emptyTicket(String id) => MyTicket(
        id: '',
        createdAt: 0,
        hotelId: '',
        departmentId: '',
        createdByUserId: '',
        createdByAi: false,
        type: '',
        status: '',
        dueAt: 0,
        category: '',
        priority: '',
        issueSummary: '',
        issueDetails: '',
        isIncident: false,
        incidentNotes: '',
        room: '',
        guestName: '',
        acknowledgedAt: 0,
        resolutionCode: '',
        resolutionNotes: '',
        confirmedAt: 0,
      );

  MyTicket _withStatus(MyTicket t, String status) => MyTicket(
        id: t.id,
        createdAt: t.createdAt,
        hotelId: t.hotelId,
        departmentId: t.departmentId,
        assignedToUserId: t.assignedToUserId,
        createdByUserId: t.createdByUserId,
        createdByAi: t.createdByAi,
        type: t.type,
        status: status,
        dueAt: t.dueAt,
        category: t.category,
        priority: t.priority,
        issueSummary: t.issueSummary,
        issueDetails: t.issueDetails,
        isIncident: t.isIncident,
        incidentNotes: t.incidentNotes,
        room: t.room,
        guestName: t.guestName,
        acknowledgedByUserId: t.acknowledgedByUserId,
        acknowledgedAt: DateTime.now().millisecondsSinceEpoch,
        resolutionCode: t.resolutionCode,
        resolutionNotes: t.resolutionNotes,
        confirmedAt: t.confirmedAt,
        closedAt: t.closedAt,
        roomDetails: t.roomDetails,
      );

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
    context.showInfo(context.l10n.comingSoonNotifications);
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
      TicketStatus.incoming => s.ticketActionAccept,
      _ => s.ticketActionStartWork,
    };

    final showSecondary = t.status != TicketStatus.incoming;

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
            if (showSecondary) ...[
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
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        foregroundColor: c.fgBase,
        side: BorderSide(color: c.borderBase),
        minimumSize: const Size.fromHeight(44),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: TypographyManager.textLabel,
      ),
    );
  }
}
