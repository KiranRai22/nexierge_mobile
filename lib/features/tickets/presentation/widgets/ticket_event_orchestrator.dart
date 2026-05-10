import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/sound_manager.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../domain/models/ticket_change_event.dart';
import '../providers/ticket_event_bus.dart';
import 'tickets_main_tabs.dart';

/// Window during which incoming events are coalesced into a single toast
/// per status bucket. Short enough to feel reactive, long enough to absorb
/// a burst of socket events that landed in the same backend transaction.
const Duration _kBatchWindow = Duration(milliseconds: 1500);

/// Wraps a child subtree and reacts to [TicketChangeEvent]s from the bus by:
///   - showing a status-grouped toast (one per bucket per batch window),
///   - playing the per-event-type sound,
///   - on toast tap, navigating to the appropriate Tickets sub-tab.
///
/// Mounted once per logged-in session, just inside the shell scaffold so it
/// has Overlay context for [AppToast]. Sound + toast both fire for self
/// events (current user's own actions) — the user explicitly opted in.
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
  /// Buffer keyed by the status bucket the event lands in. Each bucket
  /// flushes as one toast.
  final Map<_ToastBucket, List<TicketChangeEvent>> _buffer = {};
  Timer? _flushTimer;

  @override
  void dispose() {
    _flushTimer?.cancel();
    super.dispose();
  }

  void _onEvent(TicketChangeEvent event) {
    final bucket = _bucketFor(event);
    if (bucket == null) return; // unknown / non-actionable status — drop.
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
    final count = events.length;
    final copy = bucket.copy(count);
    // Subtitle: when a single event, use its label (e.g. "Room 312"); when
    // batched, mention how many distinct rooms/items.
    final subtitle = count == 1
        ? (events.first.label.isEmpty ? _kTapHint : events.first.label)
        : _kTapHint;

    AppToast.show(
      context,
      title: copy,
      subtitle: subtitle,
      type: bucket.toastType,
      duration: const Duration(seconds: 4),
      onTap: () => widget.onNavigateToTickets(bucket.mainTab),
    );

    // Best-effort sound. Fire-and-forget.
    SoundManager.instance.play(bucket.sound);
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
        return ToastType.info;
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

  // TODO(i18n): migrate these copies into the localization layer once the
  // ARB keys land. Per CLAUDE.md the strings should not stay hardcoded.
  String copy(int count) {
    switch (this) {
      case _ToastBucket.newTicket:
        return count == 1 ? 'New ticket' : '$count new tickets';
      case _ToastBucket.accepted:
        return count == 1 ? 'Ticket accepted' : '$count tickets accepted';
      case _ToastBucket.inProgress:
        return count == 1 ? 'Ticket started' : '$count tickets started';
      case _ToastBucket.onHold:
        return count == 1 ? 'Ticket on hold' : '$count tickets on hold';
      case _ToastBucket.done:
        return count == 1 ? 'Ticket done' : '$count tickets done';
      case _ToastBucket.canceledOrExpired:
        return count == 1 ? 'Ticket closed' : '$count tickets closed';
    }
  }
}

// TODO(i18n): localise.
const String _kTapHint = 'Tap to view';

_ToastBucket? _bucketFor(TicketChangeEvent event) {
  if (event.kind == TicketChangeKind.created) return _ToastBucket.newTicket;
  if (event.kind == TicketChangeKind.deleted) return null;
  switch ((event.newStatus ?? '').toUpperCase()) {
    case 'NEW':
      // Status moved back to NEW (rare reset path) — surface as new ticket.
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
