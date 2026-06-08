import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/services/sound_manager.dart';
import '../../../../core/theme/card_theme.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/theme/unified_theme_manager.dart';
import '../../../../core/theme/typography_manager.dart';
import '../../../../core/time/server_clock.dart';
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
  bool get _showMarkDone =>
      ticket.status == TicketStatus.inProgress ||
      ticket.status == TicketStatus.backlog;
  bool get _showStartWork => ticket.status == TicketStatus.accepted;

  /// ETA label derived from the first universal item's preset range, e.g. "15–30 min".
  String? get _etaLabel {
    final data = ticket.kindData;
    if (data is UniversalKindData && data.etaEnd > 0) {
      return data.etaStart > 0
          ? '${data.etaStart}–${data.etaEnd} min'
          : '${data.etaEnd} min';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    final radius = BorderRadius.circular(12);

    return Semantics(
      button: true,
      label: '${ticket.code} ${ticket.title}',
      child: _UrgencyWrapper(
        ticket: ticket,
        borderRadius: radius,
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
                          const SizedBox(height: 6),
                          _HeroBodyRow(
                            ticket: ticket,
                            etaLabel: _etaLabel,
                          ),
                          const SizedBox(height: 6),
                          _Row2(
                            ticket: ticket,
                            showAccept: _showAccept,
                            showMarkDone: _showMarkDone,
                            showStartWork: _showStartWork,
                            onAccept: onAccept,
                            onMarkDone: onMarkDone,
                            onStartWork: onStartWork,
                          ),
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
      ),
    );
  }
}

// ─── Urgency wrapper: shake at ≤3 min, soft tint for urgent / grace ──────────

/// Wraps a ticket card to convey time-pressure visually:
///   • Healthy w/ timeLeft ≤ 3 min  → amber halo + subtle horizontal shake
///   • Past dueAt, before graceAt    → soft red tint (grace period)
///   • Past graceAt (not incoming)   → soft red tint (overdue)
/// Cheap when not urgent: animation controller is only created/started when
/// the ticket enters the urgent window.
class _UrgencyWrapper extends StatefulWidget {
  final Ticket ticket;
  final BorderRadius borderRadius;
  final Widget child;

  const _UrgencyWrapper({
    required this.ticket,
    required this.borderRadius,
    required this.child,
  });

  @override
  State<_UrgencyWrapper> createState() => _UrgencyWrapperState();
}

class _UrgencyWrapperState extends State<_UrgencyWrapper>
    with SingleTickerProviderStateMixin {
  static const _urgentWindow = Duration(minutes: 3);

  Timer? _tick;
  AnimationController? _shake;

  bool get _isTerminal {
    final s = widget.ticket.status;
    return s == TicketStatus.done || s == TicketStatus.canceled;
  }

  /// True when the ticket is healthy but ≤ 3 min from dueAt.
  bool get _isUrgent {
    if (_isTerminal) return false;
    final due = widget.ticket.eta;
    if (due == null) return false;
    final left = due.difference(ServerClock.now());
    return !left.isNegative && left <= _urgentWindow;
  }

  /// True when past dueAt but before dueAtWithGrace, OR incoming past grace
  /// (which is the transient "still in grace" state).
  bool get _isInGrace {
    if (_isTerminal) return false;
    final due = widget.ticket.eta;
    if (due == null) return false;
    final now = ServerClock.now();
    if (now.isBefore(due)) return false;
    final grace = widget.ticket.dueAtWithGrace ?? due;
    if (now.isBefore(grace)) return true;
    return widget.ticket.status == TicketStatus.incoming;
  }

  /// True when past dueAtWithGrace and not incoming (hard overdue).
  bool get _isOverdue {
    if (_isTerminal) return false;
    final grace = widget.ticket.dueAtWithGrace ?? widget.ticket.eta;
    if (grace == null) return false;
    if (ServerClock.now().isBefore(grace)) return false;
    return widget.ticket.status != TicketStatus.incoming;
  }

  @override
  void initState() {
    super.initState();
    if (!_isTerminal) {
      _tick = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void didUpdateWidget(covariant _UrgencyWrapper old) {
    super.didUpdateWidget(old);
    if (_isTerminal) {
      _tick?.cancel();
      _tick = null;
      _shake?.stop();
    } else if (_tick == null) {
      _tick = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    _shake?.dispose();
    super.dispose();
  }

  void _ensureShakeRunning() {
    _shake ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    if (!_shake!.isAnimating) _shake!.repeat();
  }

  void _stopShake() {
    if (_shake != null && _shake!.isAnimating) {
      _shake!.stop();
      _shake!.value = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final urgent = _isUrgent;
    final grace = _isInGrace;
    final overdue = _isOverdue;

    if (urgent) {
      _ensureShakeRunning();
    } else {
      _stopShake();
    }

    // Pick the wrapper background/halo. Urgent wins over grace/overdue.
    Color? tint;
    List<BoxShadow>? halo;
    if (urgent) {
      const amber = Color(0xFFFFB020);
      tint = amber.withOpacity(0.08);
      halo = [
        BoxShadow(
          color: amber.withOpacity(0.45),
          blurRadius: 10,
          spreadRadius: 0.5,
        ),
      ];
    } else if (overdue) {
      tint = ColorPalette.statusOverdue.withOpacity(0.10);
    } else if (grace) {
      tint = ColorPalette.statusOverdue.withOpacity(0.06);
    }

    final wrapped = AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius,
        color: tint,
        boxShadow: halo,
      ),
      child: widget.child,
    );

    if (_shake == null) return wrapped;
    return AnimatedBuilder(
      animation: _shake!,
      builder: (_, child) {
        final dx = urgent
            ? math.sin(_shake!.value * 2 * math.pi) * 2.5
            : 0.0;
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: wrapped,
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

/// Hero body row: large square thumbnail on the left (~30% width) and a
/// 2-row text column on the right (~70%) holding the title+SLA and the
/// created/due/time-left line.
class _HeroBodyRow extends StatelessWidget {
  final Ticket ticket;
  final String? etaLabel;

  const _HeroBodyRow({required this.ticket, this.etaLabel});

  List<String> _resolveThumbnails() {
    final data = ticket.kindData;
    if (data is CatalogKindData) {
      return data.itemThumbnails
          .where((u) => u.isNotEmpty)
          .take(4)
          .toList();
    }
    if (data is UniversalKindData) {
      final urls = <String>[];
      for (final item in data.allItems) {
        final u = item.thumbnailUrl;
        if (u != null && u.isNotEmpty) urls.add(u);
        if (urls.length == 4) break;
      }
      if (urls.isEmpty) {
        final single = data.thumbnailUrl;
        if (single != null && single.isNotEmpty) urls.add(single);
      }
      return urls;
    }
    return const [];
  }

  String _fallbackEmoji() {
    final data = ticket.kindData;
    if (data is UniversalKindData && (data.emoji?.isNotEmpty ?? false)) {
      return data.emoji!;
    }
    return switch (ticket.kind) {
      TicketKind.universal => '🧳',
      TicketKind.catalog => '🍽️',
      TicketKind.manual => '📝',
    };
  }

  int _totalItemCount() {
    final data = ticket.kindData;
    if (data is CatalogKindData) return data.itemCount;
    if (data is UniversalKindData) return data.itemCount;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    final urls = _resolveThumbnails();
    final total = _totalItemCount();

    // Fixed square thumbnail — using LayoutBuilder or AspectRatio here would
    // collide with the outer [IntrinsicHeight], which can't query intrinsic
    // dimensions through a layout builder.
    const imageSize = 96.0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: imageSize,
          height: imageSize,
          child: _HeroThumbnail(
            imageUrls: urls,
            fallbackEmoji: _fallbackEmoji(),
            totalItemCount: total,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title + SLA / ETA label.
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      ticket.title,
                      style: TypographyManager.cardTitle.copyWith(fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (etaLabel != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      etaLabel!,
                      style: TypographyManager.cardMeta.copyWith(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: c.fgMuted,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              // Created / Due / Time left.
              _Row3(ticket: ticket),
            ],
          ),
        ),
      ],
    );
  }
}

/// Square hero thumbnail. Shows the first item image full-bleed, with a
/// "+N" badge in the bottom-right when the ticket has more items than the
/// single tile can represent. Falls back to the supplied emoji on missing
/// URL or load failure.
class _HeroThumbnail extends StatelessWidget {
  final List<String> imageUrls;
  final String fallbackEmoji;
  final int totalItemCount;

  const _HeroThumbnail({
    required this.imageUrls,
    required this.fallbackEmoji,
    required this.totalItemCount,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    final radius = BorderRadius.circular(10);
    final firstUrl = imageUrls.isNotEmpty ? imageUrls.first : null;
    final extra = totalItemCount > 1 ? totalItemCount - 1 : 0;

    Widget fallback() => Center(
          child: Text(
            fallbackEmoji,
            style: const TextStyle(fontSize: 28),
          ),
        );

    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: BoxDecoration(
            color: c.bgSubtle,
            borderRadius: radius,
            border: Border.all(color: c.borderBase),
          ),
          clipBehavior: Clip.antiAlias,
          child: firstUrl == null
              ? fallback()
              : Image.network(
                  firstUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => fallback(),
                ),
        ),
        if (extra > 0)
          Positioned(
            right: 4,
            bottom: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '+$extra',
                style: TypographyManager.labelSmall.copyWith(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
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

    final metaStyle = TypographyManager.cardMeta.copyWith(
      fontSize: 11.5,
      color: c.fgMuted,
    );
    final divider = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Text(
        '·',
        style: TypographyManager.cardMeta.copyWith(color: c.fgSubtle),
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Col 1: kind badge
        _KindBadge(kind: ticket.kind),
        divider,
        // Col 2: room icon + number
        Icon(LucideIcons.doorOpen, size: 12, color: c.fgMuted),
        Text(ticket.room.number, style: metaStyle, maxLines: 1),
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
          _MarkDoneButton(
            onMarkDone: onMarkDone,
            isForce: ticket.isOverdue || ticket.status == TicketStatus.backlog,
          ),
        ] else if (showStartWork) ...[
          _StartWorkButton(onStartWork: onStartWork),
        ],
      ],
    );
  }
}

// ─── Row 3: created · due · time indicator ───────────────────────────────────
//
// States:
//   Healthy     (!isOverdue)                      → countdown purple
//   Grace       (isOverdue && isInProgress)        → "Grace Period" orange + red due
//   Overdue     (isOverdue && !isInProgress)       → "Overdue Xm Ys" red + red due
//   Done/Cancel                                    → no indicator

class _Row3 extends StatefulWidget {
  final Ticket ticket;
  const _Row3({required this.ticket});

  @override
  State<_Row3> createState() => _Row3State();
}

class _Row3State extends State<_Row3> {
  Timer? _timer;

  bool get _needsTimer {
    final s = widget.ticket.status;
    return s != TicketStatus.done && s != TicketStatus.canceled;
  }

  @override
  void initState() {
    super.initState();
    if (_needsTimer) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void didUpdateWidget(_Row3 old) {
    super.didUpdateWidget(old);
    if (_needsTimer && _timer == null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else if (!_needsTimer && _timer != null) {
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    final s = context.l10n;
    final ticket = widget.ticket;
    final now = ServerClock.now();

    final isDone =
        ticket.status == TicketStatus.done ||
        ticket.status == TicketStatus.canceled;
    final isInProgress =
        ticket.status == TicketStatus.inProgress ||
        ticket.status == TicketStatus.accepted;
    final isIncoming = ticket.status == TicketStatus.incoming;

    // Time-state machine driven by the two server thresholds:
    //   dueAt   = ticket.eta              (SLA deadline)
    //   graceAt = ticket.dueAtWithGrace   (hard overdue threshold; server moves
    //                                      tickets to backlog past this point)
    // Healthy : now <= dueAt
    // Grace   : dueAt < now < graceAt    → render "Grace Period"
    //           Incoming past graceAt also stays in Grace until the server
    //           event moves it to backlog (transient, avoids a red flash).
    // Overdue : now >= graceAt (in-progress / backlog) → "Overdue by"
    final dueAt = ticket.eta;
    final graceAt = ticket.dueAtWithGrace ?? ticket.eta;
    final pastDue = dueAt != null && !now.isBefore(dueAt);
    final pastGrace = graceAt != null && !now.isBefore(graceAt);
    final isInGrace = !isDone && pastDue && (!pastGrace || isIncoming);
    final isOverdue = !isDone && pastGrace && !isIncoming;

    // Due date display — show dueAt (the SLA the user expects)
    final displayDue = dueAt ?? graceAt;
    final dueColor = isOverdue
        ? ColorPalette.statusOverdue
        : isInGrace
            ? c.tagOrangeIcon
            : c.fgMuted;

    // Time indicator on the right
    Widget? indicator;
    if (!isDone) {
      if (isOverdue) {
        // ── Overdue by X (in-progress past grace, or backlog) ─────────────────
        final overdueBy = graceAt != null
            ? now.difference(graceAt)
            : Duration.zero;
        indicator = _CountdownIndicator(
          label: s.ticketOverdueByLabel,
          duration: overdueBy.isNegative ? Duration.zero : overdueBy,
          color: ColorPalette.statusOverdue,
          countingUp: true,
        );
      } else if (isInGrace) {
        // ── Grace Period (incoming past due, or in-progress past due) ─────────
        indicator = _LabelIndicator(
          topLabel: s.ticketTimeLeftLabel,
          valueLabel: s.ticketGracePeriod,
          color: c.tagOrangeIcon,
        );
      } else if (dueAt != null) {
        // ── Healthy: countdown to dueAt ───────────────────────────────────────
        final timeLeft = dueAt.difference(now);
        indicator = _CountdownIndicator(
          label: s.ticketTimeLeftLabel,
          duration: timeLeft.isNegative ? Duration.zero : timeLeft,
          color: ColorPalette.statusInProgress,
        );
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: c.bgSubtle,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TimeChip(
            label: s.ticketCreatedAt,
            time: AppDateUtils.clock(ticket.createdAt),
            color: c.fgMuted,
          ),
          if (displayDue != null) ...[
            const SizedBox(width: 14),
            _TimeChip(
              label: s.ticketDueAt,
              time: AppDateUtils.clock(displayDue),
              color: dueColor,
            ),
          ],
          const Spacer(),
          if (indicator != null) indicator,
        ],
      ),
    );
  }
}

/// Two-line indicator: small label above + bold value below.
class _CountdownIndicator extends StatelessWidget {
  final String label;
  final Duration duration;
  final Color color;
  final bool countingUp;

  const _CountdownIndicator({
    required this.label,
    required this.duration,
    required this.color,
    this.countingUp = false,
  });

  String _format() {
    final h = duration.inHours;
    final m = duration.inMinutes % 60;
    final s = duration.inSeconds % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m ${s}s';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TypographyManager.cardMeta.copyWith(
            fontSize: 9.5,
            color: context.themeColors.fgSubtle,
          ),
        ),
        Text(
          _format(),
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

/// Two-line label indicator (e.g. "Time left" / "Grace Period").
class _LabelIndicator extends StatelessWidget {
  final String topLabel;
  final String valueLabel;
  final Color color;
  const _LabelIndicator({
    required this.topLabel,
    required this.valueLabel,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          topLabel,
          style: TypographyManager.cardMeta.copyWith(
            fontSize: 9.5,
            color: c.fgSubtle,
          ),
        ),
        Text(
          valueLabel,
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

class _TimeChip extends StatelessWidget {
  final String label;
  final String time;
  final Color color;
  const _TimeChip({
    required this.label,
    required this.time,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TypographyManager.cardMeta.copyWith(
            fontSize: 9.5,
            color: context.themeColors.fgSubtle,
          ),
        ),
        Text(
          time,
          style: TypographyManager.cardMeta.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w600,
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

  ({IconData icon, Color bg, Color fg, String Function(AppLocalizations) label})
  _spec() {
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
          color: ColorPalette.opsPurple,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.arrow_forward_rounded,
              size: 13,
              color: Colors.white,
            ),
            const SizedBox(width: 4),
            Text(
              context.l10n.actionMarkInProgress,
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
  final bool isForce;
  const _MarkDoneButton({this.onMarkDone, this.isForce = false});

  @override
  Widget build(BuildContext context) {
    final color = isForce
        ? ColorPalette.statusOverdue
        : context.themeColors.tagGreenIcon;
    final label = isForce
        ? context.l10n.ticketActionForceDone
        : context.l10n.ticketActionMarkDone;
    final icon = isForce ? LucideIcons.alertCircle : LucideIcons.circleCheck;
    return GestureDetector(
      onTap: onMarkDone != null ? tapSound(onMarkDone!) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: Colors.white),
            const SizedBox(width: 3),
            Text(
              label,
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
          color: ColorPalette.opsPurple,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.arrow_forward_rounded,
              size: 13,
              color: Colors.white,
            ),
            const SizedBox(width: 4),
            Text(
              context.l10n.actionMarkInProgress,
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

