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
import '../../../../../l10n/generated/app_localizations.dart';
import '../../../../../core/services/sound_manager.dart';
import '../../../../../core/theme/unified_theme_manager.dart';
import '../../../../../core/theme/typography_manager.dart';
import '../../../../../core/time/server_clock.dart';
import '../../../../../shared/widgets/app_toast.dart';
import '../../../data/repositories/ticket_repository.dart';
import '../../../domain/entities/my_ticket.dart';
import '../../../domain/models/ticket.dart';
import '../../providers/my_tickets_notifier.dart';
import '../../providers/ticket_busy_provider.dart';
import '../../providers/tickets_paged_notifier.dart';
import '../cancel_ticket_bottom_sheet.dart';
import '../change_due_time_bottom_sheet.dart';
import '../mark_done_bottom_sheet.dart';
import '../move_to_backlog_bottom_sheet.dart';
import '../reset_acknowledgement_bottom_sheet.dart';
import '../resume_to_in_progress_bottom_sheet.dart';
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

  // ────────── HOLD (ACCEPTED|IN_PROGRESS → ON_HOLD) ──────────


  // ────────── START FROM BACKLOG (BACKLOG → IN_PROGRESS) ──────────

  Future<void> _onStartFromBacklog() async {
    final t = widget.ticket;
    await showResumeToInProgressBottomSheet(
      context: context,
      onConfirm: (reason) async {
        await _withGuard(
          () => _runOptimistic(
            newStatus: 'IN_PROGRESS',
            apiCall: () => ref
                .read(ticketRepositoryProvider)
                .moveToInProgressV2(ticketId: t.id, reason: reason),
            failureMessage: context.l10n.ticketActionFailedAccept,
          ),
        );
      },
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

  // ────────── MOVE TO BACKLOG (→ BACKLOG) ──────────

  Future<void> _onMoveToBacklog() async {
    final t = widget.ticket;

    await showMoveToBacklogBottomSheet(
      context: context,
      onConfirm: (reason) async {
        await _withGuard(() async {
          try {
            await ref
                .read(ticketRepositoryProvider)
                .moveToBacklogV2(ticketId: t.id, reason: reason);
            // Refresh the backlog tab (server-curated, cannot infer locally)
            // and the source tab so removed ticket disappears.
            ref
                .read(ticketsPagedProvider(specForTab(TicketsTab.backlog)).notifier)
                .refresh();
            ref
                .read(ticketsPagedProvider(specForTab(TicketsTab.incoming)).notifier)
                .refresh();
            ref
                .read(ticketsPagedProvider(specForTab(TicketsTab.todayInProgress)).notifier)
                .refresh();
            if (mounted) Navigator.of(context).pop();
          } catch (e) {
            if (mounted) context.showFailure('Failed to move ticket to backlog');
          }
        });
      },
    );
  }

  // ────────── ACCEPT (NEW → IN_PROGRESS) ──────────
  // Shows confirmation bottom sheet before starting work.

  Future<void> _onAcceptIncoming() async {
    final t = widget.ticket;
    final failureMsg = context.l10n.ticketActionFailedAccept;
    // V2: single "Start" action → IN_PROGRESS via /ticketsv2/start/{id}.
    // Use 15-minute default due time like the card quick action.
    final dueAt = ServerClock.now().add(const Duration(minutes: 15));

    await showStartWorkConfirmation(
      context: context,
      onConfirm: () async {
        await _withGuard(
          () => _runOptimistic(
            newStatus: 'IN_PROGRESS',
            apiCall: () => ref
                .read(ticketRepositoryProvider)
                .startTicketV2(ticketId: t.id, dueAt: dueAt),
            failureMessage: failureMsg,
          ),
        );
      },
    );
  }

  // ────────── START WORK (ACCEPTED → IN_PROGRESS) ──────────
  // LEGACY-V1: V2 has no ACCEPTED state — this branch is unreachable.
  // Kept for safety in case a legacy ACCEPTED ticket is opened.
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
    final result = await ChangeDueTimeBottomSheet.show(
      context,
      ticketId: t.id,
      currentDueAtMs: t.eta?.millisecondsSinceEpoch ?? 0,
      roomId: t.room.id,
    );
    if (result == null) return;

    await _withGuard(() async {
      try {
        await ref
            .read(ticketRepositoryProvider)
            .addTimeV2(
              ticketId: t.id,
              reason: result.reason,
              extensionMinutes: result.extensionMinutes,
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
    await CancelTicketBottomSheet.showWithCallback(
      context,
      onConfirm: (reason) async {
        await _withGuard(() async {
          try {
            await ref
                .read(ticketRepositoryProvider)
                .cancelTicketV2(ticketId: t.id, reason: reason);
            _patchStatus(t.id, 'CANCELED');
            if (!mounted) return;
            Navigator.of(context).pop();
          } catch (e) {
            if (!mounted) return;
            context.showFailure(e.toString());
            rethrow;
          }
        });
      },
    );
  }

  // ────────── RESET ──────────
  // V2: POST /ticketsv2/reset_acknowledge/{id} with reason.

  Future<void> _onReset() async {
    final t = widget.ticket;
    final confirmed = await ResetAcknowledgementBottomSheet.show(context);
    if (confirmed != true) return;

    await _withGuard(() async {
      try {
        await ref
            .read(ticketRepositoryProvider)
            .resetAcknowledgeV2(
              ticketId: t.id,
              reason: 'Reset by user',
            );
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

    final overdue = t.isOverdue;

    return Material(
      color: c.bgBase,
      elevation: 0,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: switch (t.status) {
          // ───── NEW / INCOMING ─────
          TicketStatus.incoming => overdue
              ? _buildOverdueLayout(context, s, c)
              : _buildNewLayout(context, s, c),
          // ───── IN PROGRESS ─────
          TicketStatus.inProgress => overdue
              ? _buildOverdueLayout(context, s, c)
              : _buildInProgressLayout(context, s, c),
          // ───── BACKLOG ─────
          TicketStatus.backlog => overdue
              ? _buildBacklogOverdueLayout(context, s, c)
              : _buildBacklogLayout(context, s, c),
          // ───── ACCEPTED ───── (legacy v1 path)
          TicketStatus.accepted => _buildAcceptedLayout(context, s, c),
          // ───── ON HOLD ─────
          TicketStatus.onHold => _buildOnHoldLayout(context, s, c),
          _ => const SizedBox.shrink(),
        },
      ),
    );
  }

  // ───── Layout Builders ─────

  /// INCOMING healthy: Accept & Start (primary) + Add Time | Backlog | Cancel
  Widget _buildNewLayout(BuildContext context, AppLocalizations s, AppColors c) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _busy ? null : tapSound(_onAcceptIncoming),
            icon: const Icon(LucideIcons.play, size: 18),
            label: Text(s.ticketActionAcceptAndStart),
            style: _primaryStyle(c),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _SecondaryButton(
                icon: LucideIcons.circlePlus,
                label: s.ticketActionChangeDue,
                onTap: _busy ? null : tapSound(_onChangeDue, SoundCategory.preference),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SecondaryButton(
                icon: LucideIcons.archive,
                label: s.ticketActionMoveToBacklog,
                onTap: _busy ? null : tapSound(_onMoveToBacklog),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SecondaryButton(
                icon: LucideIcons.x,
                label: s.ticketActionCancel,
                isDestructive: true,
                onTap: _busy ? null : tapSound(_onCancel),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// IN_PROGRESS healthy: Mark Done (primary) + Add Time | Reset | Backlog | Cancel
  Widget _buildInProgressLayout(BuildContext context, AppLocalizations s, AppColors c) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _busy ? null : tapSound(_onMarkDone),
            icon: const Icon(LucideIcons.check, size: 18),
            label: Text(s.ticketActionMarkDone),
            style: _primaryStyle(c),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _SecondaryButton(
                icon: LucideIcons.circlePlus,
                label: s.ticketActionChangeDue,
                onTap: _busy ? null : tapSound(_onChangeDue, SoundCategory.preference),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SecondaryButton(
                icon: LucideIcons.rotateCcw,
                label: s.ticketActionResetOwnership,
                onTap: _busy ? null : tapSound(_onReset),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _SecondaryButton(
                icon: LucideIcons.archive,
                label: s.ticketActionMoveToBacklog,
                onTap: _busy ? null : tapSound(_onMoveToBacklog),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SecondaryButton(
                icon: LucideIcons.x,
                label: s.ticketActionCancel,
                isDestructive: true,
                onTap: _busy ? null : tapSound(_onCancel),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Shared overdue layout for INCOMING + IN_PROGRESS:
  /// Force Done (primary) + Move to Backlog | Cancel
  Widget _buildOverdueLayout(BuildContext context, AppLocalizations s, AppColors c) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _busy ? null : tapSound(_onMarkDone),
            icon: const Icon(LucideIcons.checkCheck, size: 18),
            label: Text(s.ticketActionForceDone),
            style: _primaryStyle(c),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _SecondaryButton(
                icon: LucideIcons.archive,
                label: s.ticketActionMoveToBacklog,
                onTap: _busy ? null : tapSound(_onMoveToBacklog),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SecondaryButton(
                icon: LucideIcons.x,
                label: s.ticketActionCancel,
                isDestructive: true,
                onTap: _busy ? null : tapSound(_onCancel),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// BACKLOG healthy: Resume to In Progress (primary) + Cancel
  Widget _buildBacklogLayout(BuildContext context, AppLocalizations s, AppColors c) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _busy ? null : tapSound(_onStartFromBacklog),
                icon: const Icon(LucideIcons.circlePlay, size: 18),
                label: Text(s.ticketActionResumeToInProgress),
                style: _primaryStyle(c),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SecondaryButton(
                icon: LucideIcons.x,
                label: s.ticketActionCancel,
                isDestructive: true,
                onTap: _busy ? null : tapSound(_onCancel),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// BACKLOG overdue: Force Done (primary) + Cancel
  Widget _buildBacklogOverdueLayout(BuildContext context, AppLocalizations s, AppColors c) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _busy ? null : tapSound(_onMarkDone),
                icon: const Icon(LucideIcons.checkCheck, size: 18),
                label: Text(s.ticketActionForceDone),
                style: _primaryStyle(c),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SecondaryButton(
                icon: LucideIcons.x,
                label: s.ticketActionCancel,
                isDestructive: true,
                onTap: _busy ? null : tapSound(_onCancel),
              ),
            ),
          ],
        ),
      ],
    );
  }

  ButtonStyle _primaryStyle(AppColors c) => ElevatedButton.styleFrom(
    backgroundColor: c.buttonInverted,
    foregroundColor: c.fgOnInverted,
    disabledBackgroundColor: c.bgDisabled,
    minimumSize: const Size.fromHeight(48),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    textStyle: TypographyManager.labelLarge.copyWith(fontWeight: FontWeight.w600),
  );

  Widget _buildAcceptedLayout(BuildContext context, AppLocalizations s, AppColors c) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Row 1: Start Work (full width primary)
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _busy ? null : tapSound(_onStartWork),
            icon: const Icon(LucideIcons.circlePlay, size: 18),
            label: Text(s.ticketActionStartWork),
            style: ElevatedButton.styleFrom(
              backgroundColor: c.buttonInverted,
              foregroundColor: c.fgOnInverted,
              disabledBackgroundColor: c.bgDisabled,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: TypographyManager.labelLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Row 2: Add Time | Cancel (destructive) | Reset (3 buttons)
        Row(
          children: [
            Expanded(
              child: _SecondaryButton(
                icon: LucideIcons.circlePlus,
                label: 'Add Time',
                onTap: _busy ? null : tapSound(_onChangeDue, SoundCategory.preference),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SecondaryButton(
                icon: LucideIcons.x,
                label: 'Cancel',
                isDestructive: true,
                onTap: _busy ? null : tapSound(_onCancel),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SecondaryButton(
                icon: LucideIcons.rotateCcw,
                label: s.ticketActionReset,
                onTap: _busy ? null : tapSound(_onReset),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOnHoldLayout(BuildContext context, AppLocalizations s, AppColors c) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _busy ? null : tapSound(_onResume),
            icon: const Icon(LucideIcons.play, size: 18),
            label: Text(s.ticketActionResume),
            style: ElevatedButton.styleFrom(
              backgroundColor: c.buttonInverted,
              foregroundColor: c.fgOnInverted,
              disabledBackgroundColor: c.bgDisabled,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: TypographyManager.labelLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isDestructive;
  const _SecondaryButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: isDestructive ? c.tagRedText : null),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        foregroundColor: isDestructive ? c.tagRedText : c.fgBase,
        side: BorderSide(color: isDestructive ? c.tagRedText : c.borderBase),
        minimumSize: const Size.fromHeight(44),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: TypographyManager.textLabel,
      ),
    );
  }
}
