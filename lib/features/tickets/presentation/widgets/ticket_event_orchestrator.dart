import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../core/services/sound_manager.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../domain/models/ticket_change_event.dart';
import '../providers/ticket_event_bus.dart';
import 'tickets_main_tabs.dart';

/// Window during which incoming events are coalesced into a single toast
/// per status bucket. Short enough to feel reactive, long enough to absorb
/// a burst of socket events that landed in the same backend transaction.
const Duration _kBatchWindow = Duration(milliseconds: 1500);

/// How long an enriched ticket toast stays on screen. Bumped from 4s
/// because the toast now carries multi-line info (type, target tab, due
/// time) that a real user actually needs time to read in the field.
const Duration _kToastDuration = Duration(seconds: 6);

/// Wraps a child subtree and reacts to [TicketChangeEvent]s from the bus by:
///   - showing a status-grouped toast (one per bucket per batch window),
///   - playing the per-event-type sound,
///   - on toast tap, navigating to the appropriate Tickets sub-tab.
class TicketEventOrchestrator extends ConsumerStatefulWidget {
  const TicketEventOrchestrator({
    super.key,
    required this.child,
    required this.onNavigateToTickets,
  });

  final Widget child;

  /// Called when the user taps a toast. Implementer should switch to the
  /// Tickets shell tab and set the Tickets main tab to [mainTab].
  final void Function(TicketsMainTab mainTab) onNavigateToTickets;

  @override
  ConsumerState<TicketEventOrchestrator> createState() =>
      _TicketEventOrchestratorState();
}

class _TicketEventOrchestratorState
    extends ConsumerState<TicketEventOrchestrator> {
  final Map<_ToastBucket, List<TicketChangeEvent>> _buffer = {};
  Timer? _flushTimer;

  @override
  void dispose() {
    _flushTimer?.cancel();
    super.dispose();
  }

  void _onEvent(TicketChangeEvent event) {
    final bucket = _bucketFor(event);
    if (bucket == null) return;
    _buffer.putIfAbsent(bucket, () => []).add(event);
    _flushTimer ??= Timer(_kBatchWindow, _flush);
  }

  void _flush() {
    _flushTimer = null;
    if (_buffer.isEmpty) return;
    final groups = Map<_ToastBucket, List<TicketChangeEvent>>.from(_buffer);
    _buffer.clear();
    for (final entry in groups.entries) {
      _showGroup(entry.key, entry.value);
    }
  }

  void _showGroup(_ToastBucket bucket, List<TicketChangeEvent> events) {
    if (!mounted) return;
    final s = context.l10n;
    final count = events.length;
    final title = bucket.title(s, count);
    final subtitle = count == 1
        ? _buildRichSubtitle(s, bucket, events.first)
        : s.toastTapToView;

    AppToast.show(
      context,
      title: title,
      subtitle: subtitle,
      type: bucket.toastType,
      duration: _kToastDuration,
      onTap: () => widget.onNavigateToTickets(bucket.mainTab),
    );

    SoundManager.instance.play(bucket.sound);
  }

  /// Composes the multi-line subtitle for a single-ticket toast:
  ///
  ///   Line 1: "Type: {Kind} · {Room 312}"
  ///   Line 2: "{Moved to|Landed in} {Tab} · Due {date}"
  ///
  /// Lines collapse gracefully when fields are missing — empty segments
  /// are dropped instead of leaving stray separators.
  String _buildRichSubtitle(
    AppLocalizations s,
    _ToastBucket bucket,
    TicketChangeEvent event,
  ) {
    final line1Parts = <String>[];
    final kindLabel = _kindLabel(s, event.ticketKind);
    if (kindLabel.isNotEmpty) {
      line1Parts.add(s.toastTicketTypeLabel(kindLabel));
    }
    if (event.label.isNotEmpty) {
      line1Parts.add(event.label);
    }

    final tabLabel = _tabLabel(s, bucket.mainTab);
    final movement = bucket == _ToastBucket.newTicket
        ? s.toastLandedInTab(tabLabel)
        : s.toastMovedToTab(tabLabel);
    final line2Parts = <String>[movement];
    if (event.dueAt > 0) {
      line2Parts.add(s.toastDueLabel(_formatDue(event.dueAt)));
    }

    final out = <String>[];
    if (line1Parts.isNotEmpty) out.add(line1Parts.join(' · '));
    out.add(line2Parts.join(' · '));
    return out.join('\n');
  }

  String _kindLabel(AppLocalizations s, String rawKind) {
    switch (rawKind.toUpperCase()) {
      case 'MANUAL':
        return s.ticketKindManual;
      case 'CATALOG':
        return s.ticketKindCatalog;
      case 'UNIVERSAL':
        return s.ticketKindUniversal;
      default:
        return '';
    }
  }

  String _tabLabel(AppLocalizations s, TicketsMainTab tab) {
    switch (tab) {
      case TicketsMainTab.incoming:
        return s.toastTabIncoming;
      case TicketsMainTab.today:
        return s.toastTabToday;
      case TicketsMainTab.done:
        return s.toastTabDone;
      case TicketsMainTab.backlog:
        // No bucket currently routes to backlog; fall back to "Today" so
        // the toast subtitle stays readable if that mapping ever changes.
        return s.toastTabToday;
    }
  }

  /// Light, intl-free formatter that mirrors the rest of the app's "May 12,
  /// 3:45 PM" style. Skips year when the due falls in the current year to
  /// keep the toast subtitle short.
  String _formatDue(int epochMs) {
    final dt = DateTime.fromMillisecondsSinceEpoch(epochMs).toLocal();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour12 = dt.hour == 0
        ? 12
        : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final now = DateTime.now();
    final datePart = dt.year == now.year
        ? '${months[dt.month - 1]} ${dt.day}'
        : '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    return '$datePart, $hour12:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<TicketChangeEvent>>(
      ticketEventStreamProvider,
      (_, next) {
        final event = next.valueOrNull;
        if (event != null) _onEvent(event);
      },
    );
    return widget.child;
  }
}

/// Status bucket → toast copy / sound / navigation target. Centralised so
/// there is one source of truth for the per-event behaviour matrix.
enum _ToastBucket {
  newTicket,
  accepted,
  inProgress,
  onHold,
  done,
  canceledOrExpired,
}

extension on _ToastBucket {
  TicketsMainTab get mainTab {
    switch (this) {
      case _ToastBucket.newTicket:
        return TicketsMainTab.incoming;
      case _ToastBucket.accepted:
      case _ToastBucket.inProgress:
      case _ToastBucket.onHold:
        return TicketsMainTab.today;
      case _ToastBucket.done:
      case _ToastBucket.canceledOrExpired:
        return TicketsMainTab.done;
    }
  }

  ToastType get toastType {
    switch (this) {
      case _ToastBucket.newTicket:
      case _ToastBucket.accepted:
      case _ToastBucket.inProgress:
        return ToastType.info;
      case _ToastBucket.onHold:
        return ToastType.warning;
      case _ToastBucket.done:
        return ToastType.success;
      case _ToastBucket.canceledOrExpired:
        return ToastType.failure;
    }
  }

  SoundCategory get sound {
    switch (this) {
      case _ToastBucket.newTicket:
        return SoundCategory.ticketCreated;
      case _ToastBucket.accepted:
        return SoundCategory.ticketAccepted;
      case _ToastBucket.inProgress:
        return SoundCategory.ticketInProgress;
      case _ToastBucket.onHold:
        return SoundCategory.ticketOnHold;
      case _ToastBucket.done:
        return SoundCategory.ticketDone;
      case _ToastBucket.canceledOrExpired:
        return SoundCategory.ticketEnded;
    }
  }

  String title(AppLocalizations s, int count) {
    switch (this) {
      case _ToastBucket.newTicket:
        return count == 1 ? s.toastNewTicketTitle : s.toastNewTicketsTitle(count);
      case _ToastBucket.accepted:
        return count == 1
            ? s.toastTicketAcceptedTitle
            : s.toastTicketsAcceptedTitle(count);
      case _ToastBucket.inProgress:
        return count == 1
            ? s.toastTicketStartedTitle
            : s.toastTicketsStartedTitle(count);
      case _ToastBucket.onHold:
        return count == 1
            ? s.toastTicketOnHoldTitle
            : s.toastTicketsOnHoldTitle(count);
      case _ToastBucket.done:
        return count == 1
            ? s.toastTicketDoneTitle
            : s.toastTicketsDoneTitle(count);
      case _ToastBucket.canceledOrExpired:
        return count == 1
            ? s.toastTicketClosedTitle
            : s.toastTicketsClosedTitle(count);
    }
  }
}

_ToastBucket? _bucketFor(TicketChangeEvent event) {
  if (event.kind == TicketChangeKind.created) return _ToastBucket.newTicket;
  if (event.kind == TicketChangeKind.deleted) return null;
  switch ((event.newStatus ?? '').toUpperCase()) {
    case 'NEW':
      return _ToastBucket.newTicket;
    case 'ACCEPTED':
      return _ToastBucket.accepted;
    case 'IN_PROGRESS':
      return _ToastBucket.inProgress;
    case 'ON_HOLD':
      return _ToastBucket.onHold;
    case 'DONE':
      return _ToastBucket.done;
    case 'CANCELED':
    case 'CANCELLED':
    case 'EXPIRED':
      return _ToastBucket.canceledOrExpired;
    default:
      return null;
  }
}
