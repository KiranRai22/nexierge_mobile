import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../../core/i18n/locale_aware_strings.dart';
import '../../../core/time/server_clock.dart';
import '../domain/entities/my_ticket.dart';
import '../presentation/providers/my_tickets_notifier.dart';

/// Schedules two local notifications per non-terminal ticket:
///   • `dueAt - 3min`  → "Ticket about to expire"
///   • `dueAt`         → "Ticket entered grace period"
///
/// Cancels per-ticket on status change to a terminal state, when the ticket
/// disappears from the list, or when `dueAt` shifts.
///
/// Grouped under [groupKey] so a flurry of tickets surfaces as a single
/// summary on Android instead of one banner per ticket.
///
/// Permission model:
///   - POST_NOTIFICATIONS (Android 13+) requested at startup. If denied, the
///     scheduler still runs but notifications won't appear — logged once.
///   - SCHEDULE_EXACT_ALARM (Android 12+) requested via the plugin. If denied,
///     falls back to `inexactAllowWhileIdle` (~1 min drift, still fires).
class TicketSlaScheduler {
  TicketSlaScheduler._();
  static final instance = TicketSlaScheduler._();

  static const _channelId = 'ticket_sla_v1';
  static const _groupKey = 'ticket_sla';
  static const _summaryId = 0x7F000000; // reserved id for the group summary
  static const _leadTime = Duration(minutes: 3);

  final _plugin = FlutterLocalNotificationsPlugin();

  bool _tzInitialised = false;
  bool _channelReady = false;
  bool _exactAlarmsAllowed = false;
  bool _postNotificationsAllowed = true;

  /// ticketId → (warnNotifId, graceNotifId, dueAtMs)
  final Map<String, _ScheduledEntry> _scheduled = {};

  Future<void> _ensureReady() async {
    if (!_tzInitialised) {
      tzdata.initializeTimeZones();
      // We schedule against UTC and let the plugin fire at the absolute
      // instant — no device-zone lookup needed.
      tz.setLocalLocation(tz.UTC);
      _tzInitialised = true;
    }

    if (!_channelReady) {
      final s = LocaleAwareStrings.instance.strings;
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        await android.createNotificationChannel(
          AndroidNotificationChannel(
            _channelId,
            s.ticketSlaChannelName,
            description: s.ticketSlaChannelDescription,
            importance: Importance.high,
            playSound: true,
            // Sound slot reserved — wire a custom raw resource here later.
          ),
        );

        // Android 13+: notification permission. Older versions return true.
        final granted = await android.requestNotificationsPermission();
        _postNotificationsAllowed = granted ?? true;
        if (!_postNotificationsAllowed) {
          debugPrint('[TicketSlaScheduler] POST_NOTIFICATIONS denied');
        }

        // Android 12+: exact alarms. Best-effort; we fall back if denied.
        try {
          final exact = await android.requestExactAlarmsPermission();
          _exactAlarmsAllowed = exact ?? false;
        } catch (_) {
          _exactAlarmsAllowed = false;
        }
      }
      _channelReady = true;
    }
  }

  /// Reconcile scheduled notifications against the current ticket list.
  /// Idempotent — called whenever the ticket list mutates.
  Future<void> sync(List<MyTicket> tickets) async {
    await _ensureReady();
    if (!_postNotificationsAllowed) return;

    final now = ServerClock.now();
    final seen = <String>{};

    for (final t in tickets) {
      if (_isTerminal(t.status)) continue;
      if (t.dueAt <= 0) continue;
      final dueAt = DateTime.fromMillisecondsSinceEpoch(t.dueAt);
      // Skip tickets whose grace period has fully elapsed — server will have
      // moved them to backlog (or is about to). Nothing useful to schedule.
      if (t.dueAtWithGrace > 0 &&
          DateTime.fromMillisecondsSinceEpoch(t.dueAtWithGrace).isBefore(now)) {
        continue;
      }
      seen.add(t.id);

      final existing = _scheduled[t.id];
      if (existing != null && existing.dueAtMs == t.dueAt) {
        continue; // already scheduled for this exact dueAt
      }
      // dueAt changed (or first time) — cancel old then reschedule.
      if (existing != null) await _cancelEntry(existing);

      final warnAt = dueAt.subtract(_leadTime);
      final warnId = _idFor(t.id, 'warn');
      final graceId = _idFor(t.id, 'grace');

      if (warnAt.isAfter(now)) {
        await _schedule(
          id: warnId,
          fireAt: warnAt,
          title: LocaleAwareStrings.instance.strings.ticketSlaAboutToExpireTitle,
          body: _body(t, dueAt, footerMinutesLeft: _leadTime.inMinutes),
          ticketId: t.id,
        );
      }
      if (dueAt.isAfter(now)) {
        await _schedule(
          id: graceId,
          fireAt: dueAt,
          title: LocaleAwareStrings.instance.strings.ticketSlaEnteredGraceTitle,
          body: _body(t, dueAt, footerGrace: true),
          ticketId: t.id,
        );
      }

      _scheduled[t.id] = _ScheduledEntry(
        warnId: warnId,
        graceId: graceId,
        dueAtMs: t.dueAt,
      );
    }

    // Cancel anything still in our map but no longer in the active set.
    final stale = _scheduled.keys.where((id) => !seen.contains(id)).toList();
    for (final id in stale) {
      final e = _scheduled.remove(id);
      if (e != null) await _cancelEntry(e);
    }

    await _refreshGroupSummary();
  }

  Future<void> _schedule({
    required int id,
    required DateTime fireAt,
    required String title,
    required String body,
    required String ticketId,
  }) async {
    final s = LocaleAwareStrings.instance.strings;
    final tzTime = tz.TZDateTime.from(fireAt.toUtc(), tz.UTC);
    final mode = _exactAlarmsAllowed
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tzTime,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            s.ticketSlaChannelName,
            channelDescription: s.ticketSlaChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
            groupKey: _groupKey,
            styleInformation: BigTextStyleInformation(
              body,
              contentTitle: title,
            ),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            threadIdentifier: _groupKey,
          ),
        ),
        androidScheduleMode: mode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'ticket:$ticketId',
      );
    } catch (e) {
      debugPrint('[TicketSlaScheduler] schedule failed for $ticketId: $e');
    }
  }

  Future<void> _refreshGroupSummary() async {
    // Only Android shows a summary card; iOS uses threadIdentifier above.
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return;

    if (_scheduled.isEmpty) {
      await _plugin.cancel(_summaryId);
      return;
    }

    final s = LocaleAwareStrings.instance.strings;
    try {
      await _plugin.show(
        _summaryId,
        s.ticketSlaGroupSummary,
        null,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            s.ticketSlaChannelName,
            channelDescription: s.ticketSlaChannelDescription,
            importance: Importance.low,
            priority: Priority.low,
            groupKey: _groupKey,
            setAsGroupSummary: true,
            onlyAlertOnce: true,
            styleInformation: InboxStyleInformation(
              const [],
              contentTitle: s.ticketSlaGroupSummary,
              summaryText: s.ticketSlaGroupSummary,
            ),
          ),
        ),
      );
    } catch (e) {
      debugPrint('[TicketSlaScheduler] group summary failed: $e');
    }
  }

  Future<void> _cancelEntry(_ScheduledEntry e) async {
    await _plugin.cancel(e.warnId);
    await _plugin.cancel(e.graceId);
  }

  String _body(
    MyTicket t,
    DateTime dueAt, {
    int? footerMinutesLeft,
    bool footerGrace = false,
  }) {
    final s = LocaleAwareStrings.instance.strings;
    final created = DateFormat.jm().format(
      DateTime.fromMillisecondsSinceEpoch(t.createdAt),
    );
    final due = DateFormat.jm().format(dueAt);
    final footer = footerGrace
        ? s.ticketSlaFooterGrace
        : s.ticketSlaFooterMinutesLeft(footerMinutesLeft ?? 0);
    final title = t.issueSummary.isNotEmpty
        ? t.issueSummary
        : (t.universalItems.isNotEmpty
            ? t.universalItems.first.item
            : t.category);
    return s.ticketSlaNotifBody(
      t.opsTicketId.isNotEmpty ? t.opsTicketId : t.id,
      title,
      _statusLabel(t.status),
      created,
      due,
      footer,
    );
  }

  String _statusLabel(String status) {
    // Render the raw status code in a human-friendly form; full i18n of every
    // status string lives in the ticket-status helper used by the UI. The
    // notification body is best-effort and short.
    switch (status.toUpperCase()) {
      case 'NEW':
        return 'New';
      case 'ACCEPTED':
        return 'Accepted';
      case 'IN_PROGRESS':
        return 'In Progress';
      case 'BACKLOG':
        return 'Backlog';
      case 'DONE':
        return 'Done';
      case 'CANCELED':
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }

  bool _isTerminal(String status) {
    final s = status.toUpperCase();
    return s == 'DONE' || s == 'CANCELED' || s == 'CANCELLED';
  }

  /// Notification IDs must be 32-bit ints. Use a stable hash of the ticket id
  /// XORed with a per-variant salt so warn/grace never collide.
  int _idFor(String ticketId, String variant) {
    // ticketId is a UUID; its hashCode is well-distributed.
    final base = ticketId.hashCode & 0x3FFFFFFF; // keep 30 bits
    final salt = variant == 'warn' ? 0x10000000 : 0x20000000;
    return base ^ salt;
  }
}

class _ScheduledEntry {
  final int warnId;
  final int graceId;
  final int dueAtMs;
  const _ScheduledEntry({
    required this.warnId,
    required this.graceId,
    required this.dueAtMs,
  });
}

/// Watches the unified ticket list and (re)schedules SLA notifications. Mount
/// once at the app shell so the subscription is alive for the logged-in
/// session.
final ticketSlaSchedulerProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<MyTicketsState>>(myTicketsNotifierProvider, (_, next) {
    final tickets = next.valueOrNull?.all;
    if (tickets == null) return;
    // Fire-and-forget — the scheduler is idempotent.
    unawaited(TicketSlaScheduler.instance.sync(tickets));
  });
});
