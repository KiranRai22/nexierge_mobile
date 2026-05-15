// ─── V2 TICKET ACTION BAR (2026-05-14) ──────────────────────────
// Implements v2 ticket status transitions: NEW → IN_PROGRESS → DONE,
// plus hold/resume, cancel, and reset actions. Replaces v1 separate
// acknowledge and start paths with unified "Start" action.
// See internal LEGACY-V1 markers for removed v1 paths.
// ─────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/i18n/l10n_extension.dart';
import '../../../../../core/services/sound_manager.dart';
import '../../../../../core/theme/unified_theme_manager.dart';
import '../../../../../core/theme/typography_manager.dart';
import '../../../../../core/time/server_clock.dart';
import '../../../../../shared/widgets/app_toast.dart';
import '../../../../dashboard/presentation/providers/dashboard_bootstrap_controller.dart';
import '../../../data/repositories/ticket_repository.dart';
import '../../../domain/entities/my_ticket.dart';
import '../../../domain/models/ticket.dart';
import '../../providers/my_tickets_notifier.dart';
import '../../providers/ticket_busy_provider.dart';
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
///   - incoming  -> Accept & Start (direct, no sheet)
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
    final ticketId = widget.ticket.id;
    final busy = ref.read(ticketBusyProvider.notifier)..mark(ticketId);
    setState(() => _busy = true);
    try {
      await task();
    } finally {
      busy.clear(ticketId);
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
      case TicketStatus.onHold:
        await _onResume();
      default:
        break;
    }
  }

  // ────────── HOLD (ACCEPTED|IN_PROGRESS → ON_HOLD) ──────────

  Future<void> _onHold() async {
    final t = widget.ticket;
    final s = context.l10n;
    final failureMsg = s.ticketActionFailedHold;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.ticketActionHoldConfirmTitle),
        content: Text(s.ticketActionHoldConfirmMessage),
        actions: [
          TextButton(
            onPressed: tapSound(() => Navigator.of(ctx).pop(false), SoundCategory.back),
            child: Text(s.ticketActionCancel),
          ),
          ElevatedButton(
            onPressed: tapSound(() => Navigator.of(ctx).pop(true)),
            child: Text(s.ticketActionHold),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _withGuard(
      () => _runOptimistic(
        newStatus: 'ON_HOLD',
        apiCall: () => ref
            .read(ticketRepositoryProvider)
            .changeTicketStatus(ticketId: t.id, newStatus: 'ON_HOLD'),
        failureMessage: failureMsg,
      ),
    );
  }

  // ────────── RESUME (ON_HOLD → IN_PROGRESS) ──────────

  Future<void> _onResume() async {
    final t = widget.ticket;
    final failureMsg = context.l10n.ticketActionFailedResume;
    await _withGuard(
      () => _runOptimistic(
        newStatus: 'IN_PROGRESS',
        apiCall: () => ref
            .read(ticketRepositoryProvider)
            .changeTicketStatus(ticketId: t.id, newStatus: 'IN_PROGRESS'),
        failureMessage: failureMsg,
      ),
    );
  }

  // ────────── ACCEPT (NEW → IN_PROGRESS) ──────────
  // Direct accept-and-start flow: no bottom sheet, immediate action with
  // default 15-minute due time. Matches the quick card accept-and-start behavior.

  Future<void> _onAcceptIncoming() async {
    final t = widget.ticket;
    final failureMsg = context.l10n.ticketActionFailedAccept;
    // V2: single "Start" action → IN_PROGRESS via /ticketsv2/start/{id}.
    // Use 15-minute default due time like the card quick action.
    final dueAt = ServerClock.now().add(const Duration(minutes: 15));
    await _withGuard(
      () => _runOptimistic(
        newStatus: 'IN_PROGRESS',
        apiCall: () => ref
            .read(ticketRepositoryProvider)
            .startTicketV2(ticketId: t.id, dueAt: dueAt),
        failureMessage: failureMsg,
      ),
    );
  }

  // ─── LEGACY-V1 (2026-05-14) ──────────────────────────────────────
  // Replaced by ticketsv2 5-tab model. Kept for reference.
  // Accept-only / Accept-and-Start were two separate paths from NEW. V2
  // collapses them into a single Start action (handled in
  // _onAcceptIncoming above via startTicketV2).
  // ─────────────────────────────────────────────────────────────────
  // ignore: unused_element
  Future<void> _onAcceptOnly() async {
    /*
    final t = widget.ticket;
    final failureMsg = context.l10n.ticketActionFailedAccept;
    final dueTime = ServerClock.now().add(const Duration(minutes: 15));
    await _withGuard(
      () => _runOptimistic(
        newStatus: 'ACCEPTED',
        apiCall: () => ref
            .read(ticketRepositoryProvider)
            .acknowledgeTicket(
              ticketId: t.id,
              dueAt: dueTime.millisecondsSinceEpoch,
              notes: null,
            ),
        failureMessage: failureMsg,
      ),
    );
    */
  }

  // ignore: unused_element
  Future<void> _onAcceptAndStart() async {
    /*
    final t = widget.ticket;
    final failureMsg = context.l10n.ticketActionFailedAccept;
    final dueTime = ServerClock.now().add(const Duration(minutes: 15));
    await _withGuard(
      () => _runOptimistic(
        newStatus: 'IN_PROGRESS',
        apiCall: () => ref
            .read(ticketRepositoryProvider)
            .acknowledgeAndStartTicket(
              ticketId: t.id,
              dueAt: dueTime.millisecondsSinceEpoch,
              notes: null,
            ),
        failureMessage: failureMsg,
      ),
    );
    */
  }

  // ────────── START WORK (ACCEPTED → IN_PROGRESS) ──────────
  // ─── LEGACY-V1 (2026-05-14) ──────────────────────────────────────
  // V2 has no ACCEPTED state — this branch is unreachable. Kept for
  // safety in case a legacy ACCEPTED ticket is opened.
  // ─────────────────────────────────────────────────────────────────
  Future<void> _onStartWork() async {
    final t = widget.ticket;
    final failureMsg = context.l10n.ticketActionFailedStartWork;
    final confirmed = await showStartWorkConfirmation(context: context);
    if (confirmed != true) return;
    await _withGuard(
      () => _runOptimistic(
        newStatus: 'IN_PROGRESS',
        apiCall: () => ref
            .read(ticketRepositoryProvider)
            .changeTicketStatus(ticketId: t.id, newStatus: 'IN_PROGRESS'),
        failureMessage: failureMsg,
      ),
    );
  }

  // ────────── MARK DONE (IN_PROGRESS → DONE) ──────────

  Future<void> _onMarkDone() async {
    final t = widget.ticket;
    final failureMsg = context.l10n.ticketActionFailedMarkDone;
    final note = await MarkDoneBottomSheet.show(context);
    if (note == null) return;
    await _withGuard(
      () => _runOptimistic(
        newStatus: 'DONE',
        // V2: /ticketsv2/done/{id} with resolution_notes body.
        apiCall: () => ref
            .read(ticketRepositoryProvider)
            .completeTicketV2(ticketId: t.id, resolutionNote: note),
        failureMessage: failureMsg,
      ),
    );
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

    final hotelId = ref
        .read(dashboardBootstrapControllerProvider)
        .valueOrNull
        ?.userProfile
        ?.hotelDetails
        .hotel
        .id;
    if (hotelId == null || hotelId.isEmpty) {
      if (!mounted) return;
      context.showFailure(context.l10n.unauthorizedError);
      return;
    }

    await _withGuard(() async {
      try {
        await ref
            .read(ticketRepositoryProvider)
            .changeDueTime(
              ticketId: t.id,
              hotelId: hotelId,
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
        await ref.read(ticketRepositoryProvider).changeTicketStatus(
              ticketId: t.id,
              newStatus: 'CANCELED',
              resolutionNote: reason,
            );
        _patchStatus(t.id, 'CANCELED');
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
            .changeTicketStatus(ticketId: t.id, newStatus: 'NEW');
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
    updatedAt: DateTime.now().millisecondsSinceEpoch,
    slaBreached: t.slaBreached,
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
    acknowledgedAt: (status == 'ACCEPTED' || status == 'IN_PROGRESS')
        ? (t.acknowledgedAt > 0
              ? t.acknowledgedAt
              : DateTime.now().millisecondsSinceEpoch)
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
        t.status == TicketStatus.done || t.status == TicketStatus.canceled;
    if (isFinal) return const SizedBox.shrink();

    // Cancel: live tickets only (accepted/inProgress/onHold).
    final showCancel =
        t.status == TicketStatus.accepted ||
        t.status == TicketStatus.inProgress ||
        t.status == TicketStatus.onHold;
    // Reset: any non-NEW, non-final ticket can be sent back to NEW. Excludes
    // NEW itself (already there) and DONE/CANCELED (handled by `isFinal`
    // early return above).
    final showReset =
        t.status == TicketStatus.accepted ||
        t.status == TicketStatus.inProgress ||
        t.status == TicketStatus.onHold;
    // Hold: while the ticket is being worked on. Not for NEW (must accept
    // first) and not from ON_HOLD (use Resume instead).
    final showHold =
        t.status == TicketStatus.accepted ||
        t.status == TicketStatus.inProgress;

    // Prepare primary button data for non-NEW tickets
    final primaryLabel = switch (t.status) {
      TicketStatus.inProgress => s.ticketActionComplete,
      TicketStatus.accepted => s.ticketActionStartWork,
      TicketStatus.onHold => s.ticketActionResume,
      _ => s.ticketActionStartWork,
    };
    final primaryIcon = t.status == TicketStatus.onHold
        ? LucideIcons.play
        : LucideIcons.circlePlay;

    return Material(
      color: c.bgBase,
      elevation: 0,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // NEW tickets: a single full-width "Accept & Start" button.
            // Direct flow: no bottom sheet, immediately starts the ticket
            // with a default 15-minute due time (matches card quick action).
            if (t.status == TicketStatus.incoming) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _busy ? null : tapSound(_onAcceptIncoming),
                  icon: const Icon(LucideIcons.play, size: 18),
                  // TODO(i18n): consider a dedicated "Start" key; reusing
                  // existing AcceptAndStart label until l10n catalog is updated.
                  label: Text(s.ticketActionAcceptAndStart),
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
            ] else ...[
              // Show single primary button for other statuses
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _busy ? null : tapSound(_onPrimary),
                  icon: Icon(primaryIcon, size: 18),
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
            ],
            // Secondary actions row (Change Due / Cancel / Reset) is hidden
            // for NEW tickets — those choices belong inside the acknowledge
            // sheet's date picker, not here.
            if (t.status != TicketStatus.incoming) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _SecondaryButton(
                      icon: LucideIcons.calendar,
                      label: s.ticketActionChangeDue,
                      onTap: _busy ? null : tapSound(_onChangeDue, SoundCategory.preference),
                    ),
                  ),
                  if (showCancel) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SecondaryButton(
                      icon: LucideIcons.circleX,
                      label: s.ticketActionCancel,
                      onTap: _busy ? null : tapSound(_onCancel, SoundCategory.back),
                    ),
                  ),
                ],
                if (showReset) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SecondaryButton(
                      icon: LucideIcons.rotateCcw,
                      label: s.ticketActionReset,
                      onTap: _busy ? null : tapSound(_onReset),
                    ),
                  ),
                ],
              ],
            ),
            ],
            // if (showHold) ...[
            //   const SizedBox(height: 8),
            //   SizedBox(
            //     width: double.infinity,
            //     child: _SecondaryButton(
            //       icon: LucideIcons.pause,
            //       label: s.ticketActionHold,
            //       onTap: _busy ? null : _onHold,
            //     ),
            //   ),
            // ],
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
