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
import '../acknowledge_ticket_bottom_sheet.dart';
import '../cancel_ticket_bottom_sheet.dart';
import '../change_due_time_bottom_sheet.dart';
import '../mark_done_bottom_sheet.dart';
import '../reset_acknowledgement_bottom_sheet.dart';
import '../start_work_confirmation_bottom_sheet.dart';

/// Persistent bottom action bar for the ticket detail screen.
///
/// Layout:
///   [ ▶ Start Work / ✓ Mark as Done ]   <- primary, full-width, dark
///   [ Change Due ] [ Cancel ] [ Reset ]  <- secondary outline row
///
/// Primary action label is driven by [Ticket.status]:
///   - incoming  -> Accept (opens Acknowledge sheet)
///   - accepted  -> Start Work
///   - inProgress -> Mark as Done
///   - done/cancelled -> hidden
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

  // ────────── PRIMARY ACTION ──────────

  Future<void> _onPrimary() async {
    final t = widget.ticket;
    switch (t.status) {
      case TicketStatus.incoming:
        await _onAcceptIncoming();
      case TicketStatus.accepted:
        await _onStartWork();
      case TicketStatus.inProgress:
        await _onMarkDone();
      default:
        break;
    }
  }

  // ────────── ACCEPT (NEW → ACCEPTED) ──────────

  Future<void> _onAcceptIncoming() async {
    final t = widget.ticket;
    final failureMsg = context.l10n.ticketActionFailedAccept;
    final result = await AcknowledgeTicketBottomSheet.show(
      context: context,
      ticketCode: t.code,
      ticketTitle: t.guest?.displayName ?? '',
      hasGuest: t.guest != null,
    );
    if (result == null) return;
    await _withGuard(() => _runOptimistic(
          newStatus: 'ACCEPTED',
          apiCall: () => ref
              .read(ticketRepositoryProvider)
              .updateTicketStatus(ticketId: t.id),
          failureMessage: failureMsg,
        ));
  }

  // ────────── START WORK (ACCEPTED → IN_PROGRESS) ──────────

  Future<void> _onStartWork() async {
    final t = widget.ticket;
    final failureMsg = context.l10n.ticketActionFailedStartWork;
    final confirmed = await showStartWorkConfirmation(
      context: context,
      etaLabel: _etaLabel(t),
    );
    if (confirmed != true) return;
    await _withGuard(() => _runOptimistic(
          newStatus: 'IN_PROGRESS',
          apiCall: () => ref
              .read(ticketRepositoryProvider)
              .updateTicketStatus(ticketId: t.id),
          failureMessage: failureMsg,
        ));
  }

  // ────────── MARK DONE (IN_PROGRESS → DONE) ──────────

  Future<void> _onMarkDone() async {
    final t = widget.ticket;
    final failureMsg = context.l10n.ticketActionFailedMarkDone;
    final note = await MarkDoneBottomSheet.show(context);
    // null = dismissed, '' or string = confirmed (note is optional)
    if (note == null) return;
    await _withGuard(() => _runOptimistic(
          newStatus: 'DONE',
          apiCall: () => ref
              .read(ticketRepositoryProvider)
              .markDoneWithNote(ticketId: t.id, resolutionNote: note),
          failureMessage: failureMsg,
        ));
  }

  /// Optimistic transition: patch local state, pop the detail screen, then
  /// fire the API. On failure, restore the snapshot and surface a toast on
  /// the root overlay (this widget is unmounted by then). Falls back to a
  /// server-first path when no baseline ticket exists in state.
  Future<void> _runOptimistic({
    required String newStatus,
    required Future<void> Function() apiCall,
    required String failureMessage,
  }) async {
    final t = widget.ticket;
    final notifier = ref.read(myTicketsNotifierProvider.notifier);
    final snap = notifier.snapshot();
    final existing = snap?.all.firstWhere(
      (x) => x.id == t.id,
      orElse: () => _emptyTicket(t.id),
    );
    if (existing == null || existing.id.isEmpty) {
      try {
        await apiCall();
        notifier.refresh();
        if (mounted) Navigator.of(context).pop();
      } catch (_) {
        if (mounted) context.showFailure(failureMessage);
      }
      return;
    }
    final rootCtx = Navigator.of(context, rootNavigator: true).context;
    notifier.upsertFromRealtime(_withStatus(existing, newStatus));
    Navigator.of(context).pop();
    try {
      await apiCall();
    } catch (_) {
      if (snap != null) notifier.restore(snap);
      if (rootCtx.mounted) rootCtx.showFailure(failureMessage);
    }
  }

  // ────────── CHANGE DUE ──────────

  Future<void> _onChangeDue() async {
    final t = widget.ticket;
    final result = await ChangeDueTimeBottomSheet.show(context);
    if (result == null) return;

    await _withGuard(() async {
      try {
        await ref.read(ticketRepositoryProvider).changeDueTime(
              ticketId: t.id,
              newDueAt: result.newDueAt,
              reason: result.reason,
            );
        ref.read(myTicketsNotifierProvider.notifier).refresh();
      } catch (e) {
        if (!mounted) return;
        context.showFailure(e.toString());
      }
    });
  }

  // ────────── CANCEL ──────────

  Future<void> _onCancel() async {
    final t = widget.ticket;
    final reason = await CancelTicketBottomSheet.show(context);
    if (reason == null) return;

    await _withGuard(() async {
      try {
        await ref
            .read(ticketRepositoryProvider)
            .cancelTicket(ticketId: t.id, reason: reason);
        _patchStatus(t.id, 'CANCELLED');
        if (!mounted) return;
        Navigator.of(context).pop();
      } catch (e) {
        if (!mounted) return;
        context.showFailure(e.toString());
      }
    });
  }

  // ────────── RESET ──────────

  Future<void> _onReset() async {
    final t = widget.ticket;
    final confirmed = await ResetAcknowledgementBottomSheet.show(context);
    if (confirmed != true) return;

    await _withGuard(() async {
      try {
        await ref
            .read(ticketRepositoryProvider)
            .resetTicket(ticketId: t.id);
        _patchStatus(t.id, 'NEW');
        if (!mounted) return;
        Navigator.of(context).pop();
      } catch (e) {
        if (!mounted) return;
        context.showFailure(e.toString());
      }
    });
  }

  // ────────── HELPERS ──────────

  /// Optimistically patches the ticket status in the realtime list.
  void _patchStatus(String ticketId, String status) {
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
    notifier.upsertFromRealtime(_withStatus(existing, status));
    notifier.refresh();
  }

  String _etaLabel(Ticket t) {
    final eta = t.eta;
    if (eta == null) return '—';
    final diff = eta.difference(DateTime.now());
    if (diff.isNegative) return '—';
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    return '${diff.inMinutes}m';
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
        dueAt: status == 'NEW' ? 0 : t.dueAt,
        category: t.category,
        priority: t.priority,
        issueSummary: t.issueSummary,
        issueDetails: t.issueDetails,
        isIncident: t.isIncident,
        incidentNotes: t.incidentNotes,
        room: t.room,
        guestName: t.guestName,
        acknowledgedByUserId: t.acknowledgedByUserId,
        acknowledgedAt: status == 'ACCEPTED'
            ? DateTime.now().millisecondsSinceEpoch
            : t.acknowledgedAt,
        resolutionCode: t.resolutionCode,
        resolutionNotes: t.resolutionNotes,
        confirmedAt: status == 'DONE'
            ? DateTime.now().millisecondsSinceEpoch
            : t.confirmedAt,
        closedAt: t.closedAt,
        roomDetails: t.roomDetails,
      );

  // ────────── BUILD ──────────

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

    final isIncoming = t.status == TicketStatus.incoming;
    // Change Due is valid both before and after acceptance; Cancel/Reset
    // only make sense once the ticket has moved past NEW.
    final showCancelReset = !isIncoming;

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
                if (showCancelReset) ...[
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
