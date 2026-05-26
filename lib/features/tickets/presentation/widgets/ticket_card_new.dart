import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/services/sound_manager.dart';
import '../../../../core/theme/card_theme.dart';
import '../../../../core/theme/unified_theme_manager.dart';
import '../../../../core/theme/typography_manager.dart';
import '../../../../core/time/server_clock.dart';
import '../../../../core/widgets/shimmer_widget.dart';
import '../../domain/models/ticket.dart';
import '../providers/my_tickets_notifier.dart';
import '../providers/ticket_busy_provider.dart';

/// Light green border used to highlight a ticket whose status just changed
/// (or that just arrived). Visible for [kRecentChangeHighlightWindow]
/// after the realtime event lands.
const Color _kRecentChangeBorder = Color(0xFF34A853);

/// Resolves the localized department label, preferring the API-provided
/// name when present, falling back to the static enum mapping.
String _departmentLabel(BuildContext context, Ticket ticket) {
  final api = ticket.departmentName;
  if (api != null && api.isNotEmpty) return api;
  return ticket.department.label(context.l10n);
}

/// Parses `#RRGGBB` (or `RRGGBB`) into a [Color]. Returns null on bad input.
Color? _parseHexColor(String? hex) {
  if (hex == null || hex.isEmpty) return null;
  var cleaned = hex.trim();
  if (cleaned.startsWith('#')) cleaned = cleaned.substring(1);
  if (cleaned.length == 6) cleaned = 'FF$cleaned';
  if (cleaned.length != 8) return null;
  final value = int.tryParse(cleaned, radix: 16);
  if (value == null) return null;
  return Color(value);
}

/// Quick-and-dirty currency formatter: USD/usd → `$12.34`, anything else
/// returns `12.34 EUR`. Keeps the card free of intl plumbing for now.
String _formatMoney(double amount, String currency) {
  final upper = currency.toUpperCase();
  final formatted = amount.toStringAsFixed(2);
  if (upper == 'USD' || upper.isEmpty) return '\$$formatted';
  return '$formatted $upper';
}

/// Ticket card matching the image design.
/// Layout: Title row → Room row → Inner card → Bottom row (tag + button)
/// Used by [TicketsScreenNew].
class TicketCardNew extends ConsumerWidget {
  final Ticket ticket;
  final VoidCallback? onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onStartWork;
  final VoidCallback? onMarkDone;

  const TicketCardNew({
    super.key,
    required this.ticket,
    this.onTap,
    this.onAccept,
    this.onStartWork,
    this.onMarkDone,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.themeColors;
    final isRecentlyChanged = ref.watch(isRecentlyChangedProvider(ticket.id));
    final isBusy = ref.watch(isTicketBusyProvider(ticket.id));

    // Highlighted border when the ticket was just created or its status
    // moved within the last few seconds (driven by the realtime layer).
    final baseDecoration = CardDecoration.standard(
      colors: c,
      borderRadius: BorderRadius.circular(16),
    );
    final decoration = isRecentlyChanged
        ? (baseDecoration is BoxDecoration
              ? baseDecoration.copyWith(
                  border: Border.all(color: _kRecentChangeBorder, width: 2),
                )
              : baseDecoration)
        : baseDecoration;

    // Only show shimmer effect for transitioning tickets
    final cardContent = Semantics(
      button: true,
      label: '${ticket.code} ${ticket.title}',
      child: Material(
        color: c.bgBase,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: GestureDetector(
          onTap: tapSound(onTap, SoundCategory.card),
          child: Container(
            decoration: decoration,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title row: dot + title + status
                  _TitleRow(ticket: ticket),
                  const SizedBox(height: 6),
                  // Room row: icon + room + department + price
                  _RoomRow(ticket: ticket),
                  const SizedBox(height: 4),
                  // Countdown timer for ACTIVE inProgress tickets only (not overdue)
                  if (ticket.status == TicketStatus.inProgress &&
                      ticket.eta != null &&
                      !ticket.isOverdue)
                    _CountdownTimer(ticket: ticket),
                  // Elapsed time row for incoming tickets
                  if (ticket.status == TicketStatus.incoming)
                    _ElapsedTimeRow(ticket: ticket),
                  // Elapsed time row for OVERDUE inProgress tickets
                  if (ticket.status == TicketStatus.inProgress && ticket.isOverdue)
                    _OverdueElapsedRow(ticket: ticket),
                  const SizedBox(height: 12),
                  // Inner card with avatar, details
                  _InnerCard(ticket: ticket),
                  const SizedBox(height: 12),
                  // Bottom row: tag (left) + action button (right)
                  _BottomRow(
                    ticket: ticket,
                    onAccept: onAccept,
                    onStartWork: onStartWork,
                    onMarkDone: onMarkDone,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // Busy overlay: in-flight status change → block taps, dim card, show
    // spinner. Wraps either the shimmer or plain card output.
    Widget result = cardContent;
    if (ticket.isTransitioning) {
      result = ShimmerWidget(
        baseColor: c.bgBase,
        highlightColor: c.bgHighlight,
        child: result,
      );
    }
    if (isBusy) {
      result = Stack(
        children: [
          AbsorbPointer(
            absorbing: true,
            child: Opacity(opacity: 0.5, child: result),
          ),
          Positioned.fill(
            child: Center(
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: c.bgBase,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.borderBase),
                ),
                padding: const EdgeInsets.all(8),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(c.tagPurpleIcon),
                ),
              ),
            ),
          ),
        ],
      );
    }
    return result;
  }
}

/// Wraps a card in a one-shot slide-in + background-flash animation when
/// the ticket arrived via realtime in the last 3 seconds. Both effects run
/// off a single AnimationController so the card stays cheap. Slide takes
/// the first 300ms; the bg color decays over the full 3 seconds.
class _FreshArrivalWrapper extends StatefulWidget {
  final bool isFresh;
  final Color baseColor;
  final Color highlightColor;
  final Widget Function(Color bgColor) builder;

  const _FreshArrivalWrapper({
    required this.isFresh,
    required this.baseColor,
    required this.highlightColor,
    required this.builder,
  });

  @override
  State<_FreshArrivalWrapper> createState() => _FreshArrivalWrapperState();
}

class _FreshArrivalWrapperState extends State<_FreshArrivalWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _flash;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _slide = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.1, curve: Curves.easeOut),
      ),
    );
    _flash = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    if (widget.isFresh) {
      _ctrl.forward();
    } else {
      _ctrl.value = 1.0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: AnimatedBuilder(
        animation: _flash,
        builder: (context, _) {
          final color =
              Color.lerp(
                widget.baseColor,
                widget.highlightColor,
                _flash.value,
              ) ??
              widget.baseColor;
          return widget.builder(color);
        },
      ),
    );
  }
}

class _TitleRow extends StatelessWidget {
  final Ticket ticket;
  const _TitleRow({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _KindDot(ticket: ticket),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _buildTitle(context, ticket),
            style: TypographyManager.cardTitle.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: c.fgBase, // Use theme-aware color for dark mode
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        _StatusPill(ticket: ticket),
      ],
    );
  }

  String _buildTitle(BuildContext context, Ticket ticket) {
    final s = context.l10n;
    final data = ticket.kindData;
    switch (ticket.kind) {
      case TicketKind.universal:
        if (data is UniversalKindData) {
          final lang = Localizations.localeOf(context).languageCode;
          final name = data.resolveName(lang);
          if (data.itemCount > 1) {
            return s.incomingUniversalTitleWithCount(name, data.itemCount);
          }
          return name;
        }
        return ticket.title;
      case TicketKind.catalog:
        if (data is CatalogKindData) {
          final name = data.catalogName.isNotEmpty
              ? data.catalogName
              : ticket.title;
          if (data.itemCount > 0) {
            return s.incomingCatalogTitleWithCount(name, data.itemCount);
          }
          return name;
        }
        return ticket.title;
      case TicketKind.manual:
        return ticket.title;
    }
  }
}

class _KindDot extends StatelessWidget {
  final Ticket ticket;
  const _KindDot({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: _resolveColor(c),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Color _resolveColor(AppColors c) {
    switch (ticket.kind) {
      case TicketKind.manual:
        return c.fgMuted;
      case TicketKind.universal:
        return c.tagPurpleIcon;
      case TicketKind.catalog:
        if (ticket.kindData is CatalogKindData) {
          final brand = _parseHexColor(
            (ticket.kindData as CatalogKindData).brandColorHex,
          );
          if (brand != null) return brand;
        }
        return c.tagPurpleIcon;
    }
  }
}

class _TimeDisplay extends StatefulWidget {
  final Ticket ticket;
  const _TimeDisplay({required this.ticket});

  @override
  State<_TimeDisplay> createState() => _TimeDisplayState();
}

class _TimeDisplayState extends State<_TimeDisplay> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Only tick for tickets that need live elapsed time (not Done).
    if (widget.ticket.status != TicketStatus.done) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration diff) {
    if (diff.inDays > 0) {
      return '${diff.inDays}d ${diff.inHours % 24}h ${diff.inMinutes % 60}m';
    }
    if (diff.inHours > 0) {
      return '${diff.inHours}h ${diff.inMinutes % 60}m ${diff.inSeconds % 60}s';
    }
    return '${diff.inMinutes}m ${diff.inSeconds % 60}s';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    final t = widget.ticket;

    if (t.status == TicketStatus.done) {
      final dt = t.doneAt;
      final label = dt != null
          ? 'Done ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'
          : 'Done';
      return Text(
        label,
        style: TypographyManager.bodySmall.copyWith(
          color: c.fgMuted,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    final now = ServerClock.now();
    final isOverdue = t.isOverdue;
    final elapsedFrom = t.workStartedAt ?? t.createdAt;
    final elapsed = now.difference(elapsedFrom);
    final label = _formatDuration(elapsed);

    if (isOverdue) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: c.tagRedBg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '● Overdue $label',
          style: TypographyManager.bodySmall.copyWith(
            color: c.tagRedText,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
      );
    }

    return Text(
      label,
      style: TypographyManager.bodySmall.copyWith(
        color: c.fgMuted,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

/// Status pill for the top-right of the ticket card.
/// Shows status with appropriate colors (OVERDUE in red if ticket.isOverdue).
class _StatusPill extends StatelessWidget {
  final Ticket ticket;
  const _StatusPill({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    final s = context.l10n;

    final bool isOverdue = ticket.isOverdue;
    final String label;
    final Color bg;
    final Color fg;

    if (isOverdue) {
      label = 'OVERDUE';
      bg = c.tagRedBg;
      fg = c.tagRedText;
    } else {
      switch (ticket.status) {
        case TicketStatus.incoming:
          label = s.ticketStatusBadgeNew;
          bg = c.tagBlueBg;
          fg = c.tagBlueText;
        case TicketStatus.accepted:
          label = s.ticketStatusBadgeAccepted;
          bg = c.tagGreenBg;
          fg = c.tagGreenText;
        case TicketStatus.inProgress:
          label = s.ticketStatusBadgeInProgress;
          bg = c.tagGreenBg;
          fg = c.tagGreenText;
        case TicketStatus.onHold:
          label = s.ticketStatusBadgeOnHold;
          bg = c.tagPurpleBg;
          fg = c.tagPurpleText;
        case TicketStatus.done:
          label = s.ticketStatusBadgeDone;
          bg = c.tagNeutralBg;
          fg = c.tagNeutralText;
        case TicketStatus.canceled:
          label = s.ticketStatusBadgeCancelled;
          bg = c.tagRedBg;
          fg = c.tagRedText;
        case TicketStatus.backlog:
          label = 'Backlog';
          bg = c.tagNeutralBg;
          fg = c.tagNeutralText;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TypographyManager.labelSmall.copyWith(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: fg,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// Elapsed time row for new/incoming tickets.
/// Shows timer icon + time elapsed since ticket creation.
class _ElapsedTimeRow extends StatefulWidget {
  final Ticket ticket;
  const _ElapsedTimeRow({required this.ticket});

  @override
  State<_ElapsedTimeRow> createState() => _ElapsedTimeRowState();
}

class _ElapsedTimeRowState extends State<_ElapsedTimeRow> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Tick every second while ticket is incoming
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatElapsed(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h > 0) return '${h}h ${m}m ${s}s';
    return '${m}m ${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    final elapsed = DateTime.now().difference(widget.ticket.createdAt);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(LucideIcons.timer, size: 12, color: c.fgMuted),
        const SizedBox(width: 4),
        Text(
          _formatElapsed(elapsed),
          style: TypographyManager.bodySmall.copyWith(
            color: c.fgMuted,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _RoomRow extends StatelessWidget {
  final Ticket ticket;
  const _RoomRow({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    final catalog = ticket.kindData is CatalogKindData
        ? ticket.kindData as CatalogKindData
        : null;

    return Row(
      children: [
        // Left: Room info
        Icon(LucideIcons.doorOpen, size: 14, color: c.fgMuted),
        const SizedBox(width: 4),
        Text(
          '${ticket.room.number} · ${_departmentLabel(context, ticket)}',
          style: TypographyManager.bodySmall.copyWith(color: c.fgMuted),
        ),
        const Spacer(),
        // Right: Price (for catalog tickets with price)
        if (catalog != null && catalog.grandTotal > 0)
          Text(
            _formatMoney(catalog.grandTotal, catalog.currency),
            style: TypographyManager.bodySmall.copyWith(
              color: c.fgBase,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }
}

/// Live countdown timer row for inProgress tickets.
/// Shows remaining time counting down (e.g., "14m 32s") in gray.
/// When overdue, shows elapsed time in red.
/// Updates every second.
class _CountdownTimer extends StatefulWidget {
  final Ticket ticket;
  const _CountdownTimer({required this.ticket});

  @override
  State<_CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<_CountdownTimer> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant _CountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    if (widget.ticket.eta != null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    if (d.isNegative) d = Duration.zero;
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    // Always show seconds for live countdown effect
    if (h > 0) return '${h}h ${m}m ${s}s';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    final s = context.l10n;

    final eta = widget.ticket.eta;
    if (eta == null) return const SizedBox.shrink();

    final now = ServerClock.now();
    final remaining = eta.difference(now);
    final isOverdue = remaining.isNegative;

    final timeText = _formatDuration(isOverdue ? remaining.abs() : remaining);
    final textColor = isOverdue ? c.tagRedText : c.fgMuted;
    final iconColor = isOverdue ? c.tagRedText : c.fgMuted;

    return Row(
      children: [
        Icon(
          LucideIcons.timer,
          size: 14,
          color: iconColor,
        ),
        const SizedBox(width: 4),
        Text(
          '${s.ticketResolutionTimeLabel}: $timeText',
          style: TypographyManager.bodySmall.copyWith(
            color: textColor,
            fontWeight: isOverdue ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Elapsed time row for overdue In Progress tickets.
/// Shows elapsed time in red (e.g., "Elapsed Time: 44m 19s")
/// Only visible when ticket is overdue. Auto-updates every second.
class _OverdueElapsedRow extends StatefulWidget {
  final Ticket ticket;
  const _OverdueElapsedRow({required this.ticket});

  @override
  State<_OverdueElapsedRow> createState() => _OverdueElapsedRowState();
}

class _OverdueElapsedRowState extends State<_OverdueElapsedRow> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant _OverdueElapsedRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    if (widget.ticket.status == TicketStatus.inProgress &&
        widget.ticket.eta != null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    if (d.isNegative) d = Duration.zero;
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m}m ${s}s';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    final s = context.l10n;

    // Only show for in-progress tickets with an ETA
    if (widget.ticket.status != TicketStatus.inProgress ||
        widget.ticket.eta == null) {
      return const SizedBox.shrink();
    }

    final now = ServerClock.now();
    final remaining = widget.ticket.eta!.difference(now);
    final isOverdue = remaining.isNegative;

    // Only show for overdue tickets
    if (!isOverdue) {
      return const SizedBox.shrink();
    }

    // Calculate elapsed time (how long since it became overdue)
    final elapsed = remaining.abs();
    final elapsedText = _formatDuration(elapsed);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          LucideIcons.timer,
          size: 14,
          color: c.tagRedText,
        ),
        const SizedBox(width: 4),
        Text(
          '${s.ticketElapsedTimeLabel}: $elapsedText',
          style: TypographyManager.bodySmall.copyWith(
            color: c.tagRedText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Green chip showing the original resolution time that was allocated
class _OriginalResolutionChip extends StatelessWidget {
  final String text;

  const _OriginalResolutionChip({required this.text});

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.tagGreenBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.tagGreenBorder, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.clock,
            size: 12,
            color: c.tagGreenText,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TypographyManager.bodySmall.copyWith(
              color: c.tagGreenText,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows a kind-specific preview block. Returns `SizedBox.shrink()` for
/// manual tickets — the mock has no inner block for those.
class _InnerCard extends StatelessWidget {
  final Ticket ticket;
  const _InnerCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final data = ticket.kindData;
    if (data is UniversalKindData) {
      return _UniversalInnerBlock(ticket: ticket, data: data);
    }
    if (data is CatalogKindData) {
      return _CatalogInnerBlock(ticket: ticket, data: data);
    }
    return const SizedBox.shrink();
  }
}

class _UniversalInnerBlock extends StatelessWidget {
  final Ticket ticket;
  final UniversalKindData data;
  const _UniversalInnerBlock({required this.ticket, required this.data});

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    final s = context.l10n;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.bgSubtle,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Bolt icon for universal requests (matching create ticket sheet)
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: c.tagBlueBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.bolt_outlined, size: 22, color: c.fgBase),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        s.incomingUniversalRequestLabel,
                        style: TypographyManager.bodyMedium.copyWith(
                          color: c.fgBase,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      s.incomingItemsCount(data.itemCount),
                      style: TypographyManager.bodySmall.copyWith(
                        color: c.fgMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _departmentLabel(context, ticket),
                  style: TypographyManager.bodySmall.copyWith(color: c.fgMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogInnerBlock extends StatelessWidget {
  final Ticket ticket;
  final CatalogKindData data;
  const _CatalogInnerBlock({required this.ticket, required this.data});

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    final s = context.l10n;
    final totalLine = data.grandTotal > 0
        ? s.incomingItemsAndTotal(
            data.itemCount,
            _formatMoney(data.grandTotal, data.currency),
          )
        : s.incomingItemsCount(data.itemCount);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.bgSubtle,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _StackedThumbnails(
            imageUrls: data.itemThumbnails,
            fallbackEmoji: '🍽️',
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        data.catalogName,
                        style: TypographyManager.bodyMedium.copyWith(
                          color: c.fgBase,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      totalLine,
                      style: TypographyManager.bodySmall.copyWith(
                        color: c.fgMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (data.itemNames.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    data.itemNames.join(', '),
                    style: TypographyManager.bodySmall.copyWith(
                      color: c.fgMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundThumbnail extends StatelessWidget {
  final String? imageUrl;
  final String emoji;
  final double size;
  const _RoundThumbnail({
    required this.imageUrl,
    required this.emoji,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    final placeholder = Center(
      child: Text(emoji, style: TextStyle(fontSize: size * 0.5)),
    );
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c.bgBase,
        shape: BoxShape.circle,
        border: Border.all(color: c.borderBase),
      ),
      clipBehavior: Clip.antiAlias,
      child: (imageUrl != null && imageUrl!.isNotEmpty)
          ? Image.network(
              imageUrl!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => placeholder,
            )
          : placeholder,
    );
  }
}

class _StackedThumbnails extends StatelessWidget {
  final List<String> imageUrls;
  final String fallbackEmoji;
  const _StackedThumbnails({
    required this.imageUrls,
    required this.fallbackEmoji,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    final visible = imageUrls.take(3).toList();
    if (visible.isEmpty) {
      return _RoundThumbnail(imageUrl: null, emoji: fallbackEmoji);
    }
    const tileSize = 36.0;
    const overlap = 16.0;
    final width = tileSize + (visible.length - 1) * overlap;
    return SizedBox(
      width: width,
      height: tileSize,
      child: Stack(
        children: [
          for (var i = 0; i < visible.length; i++)
            Positioned(
              left: i * overlap,
              child: Container(
                width: tileSize,
                height: tileSize,
                decoration: BoxDecoration(
                  color: c.bgBase,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.borderBase, width: 2),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.network(
                  visible[i],
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Center(
                    child: Text(
                      fallbackEmoji,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BottomRow extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback? onAccept;
  final VoidCallback? onStartWork;
  final VoidCallback? onMarkDone;
  const _BottomRow({
    required this.ticket,
    this.onAccept,
    this.onStartWork,
    this.onMarkDone,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    final s = context.l10n;

    return Row(
      children: [
        // Left side: Type tag
        _TypeTag(kind: ticket.kind),
        const SizedBox(width: 8),
        // Middle: Resolution time chip (for inProgress with ETA)
        if (ticket.status == TicketStatus.inProgress && ticket.eta != null)
          _ResolutionChip(ticket: ticket),
        const Spacer(),
        // Right side: Action button
        _ActionButton(
          ticket: ticket,
          onAccept: onAccept,
          onStartWork: onStartWork,
          onMarkDone: onMarkDone,
        ),
      ],
    );
  }
}

/// Static resolution time chip showing original expected time (e.g., "15m")
/// Always displayed in green. Only shown for incoming, inProgress, and backlog.
class _ResolutionChip extends StatelessWidget {
  final Ticket ticket;
  const _ResolutionChip({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;

    // Don't show for done tickets
    if (ticket.status == TicketStatus.done) {
      return const SizedBox.shrink();
    }

    // Calculate original resolution time: dueAt - acknowledgedAt/workStartedAt
    final originalResolution = _calculateOriginalResolutionTime();
    if (originalResolution == null || originalResolution.inMinutes <= 0) {
      return const SizedBox.shrink();
    }

    final timeText = _formatDuration(originalResolution);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.tagGreenBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.timer,
            size: 12,
            color: c.tagGreenText,
          ),
          const SizedBox(width: 4),
          Text(
            timeText,
            style: TypographyManager.labelSmall.copyWith(
              color: c.tagGreenText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Calculate original resolution time: dueAt - (workStartedAt/acceptedAt/createdAt)
  /// For incoming tickets, use createdAt since it hasn't been accepted yet
  Duration? _calculateOriginalResolutionTime() {
    final eta = ticket.eta;
    // Priority: workStartedAt > acceptedAt > createdAt (for incoming)
    final startedAt = ticket.workStartedAt ?? ticket.acceptedAt;
    // For incoming tickets without acceptedAt, use createdAt
    final effectiveStartAt = startedAt ??
        (ticket.status == TicketStatus.incoming ? ticket.createdAt : null);

    if (eta == null || effectiveStartAt == null) return null;
    return eta.difference(effectiveStartAt);
  }

  String _formatDuration(Duration d) {
    if (d.isNegative) d = Duration.zero;
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }
}

class _TypeTag extends StatelessWidget {
  final TicketKind kind;
  const _TypeTag({required this.kind});

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    final s = context.l10n;

    final (bg, fg, label) = switch (kind) {
      TicketKind.universal => (
        c.tagPurpleBg,
        c.tagPurpleText,
        s.ticketKindUniversal,
      ),
      TicketKind.catalog => (c.tagBlueBg, c.tagBlueText, s.ticketKindPaid),
      TicketKind.manual => (c.bgSubtle, c.fgMuted, s.ticketKindManual),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TypographyManager.labelSmall.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback? onAccept;
  final VoidCallback? onStartWork;
  final VoidCallback? onMarkDone;
  const _ActionButton({
    required this.ticket,
    this.onAccept,
    this.onStartWork,
    this.onMarkDone,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    final s = context.l10n;
    return switch (ticket.status) {
      TicketStatus.done => _buildDoneBadge(c),
      TicketStatus.inProgress => _buildMarkDoneButton(c, onMarkDone),
      TicketStatus.accepted => _buildStartWorkButton(c, onStartWork),
      TicketStatus.onHold => _buildScheduledBadge(c, s.ticketStatusBadgeOnHold),
      // [ACCEPT_AND_START_FLOW] Old: NEW cards showed an "Accept" button that
      // opened the acknowledge bottom sheet. New flow: NEW cards show a single
      // "Accept & Start" button that transitions directly to IN_PROGRESS.
      // _ => _buildAcceptButton(c, onAccept),
      _ => _buildAcceptAndStartButton(c, onAccept),
    };
  }

  Widget _buildScheduledBadge(AppColors c, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.tagPurpleBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.clock, size: 14, color: c.tagPurpleIcon),
          const SizedBox(width: 4),
          Text(
            label,
            style: TypographyManager.labelSmall.copyWith(
              color: c.tagPurpleIcon,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcceptButton(AppColors c, VoidCallback? onTap) {
    return Builder(
      builder: (context) {
        final s = context.l10n;
        return GestureDetector(
          onTap: tapSound(onTap),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: c.tagPurpleIcon,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.check, size: 14, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  s.actionAcceptShort,
                  style: TypographyManager.labelSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // [ACCEPT_AND_START_FLOW] New button for NEW-status cards. Replaces
  // _buildAcceptButton in the build switch.
  Widget _buildAcceptAndStartButton(AppColors c, VoidCallback? onTap) {
    return Builder(
      builder: (context) {
        final s = context.l10n;
        return GestureDetector(
          onTap: tapSound(onTap),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: c.tagPurpleIcon,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.play, size: 14, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  s.ticketActionAcceptAndStart,
                  style: TypographyManager.labelSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStartWorkButton(AppColors c, VoidCallback? onTap) {
    return GestureDetector(
      onTap: tapSound(onTap),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: c.tagPurpleIcon,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.play, size: 14, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              'Start Work',
              style: TypographyManager.labelSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarkDoneButton(AppColors c, VoidCallback? onTap) {
    return GestureDetector(
      onTap: tapSound(onTap),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: c.tagGreenIcon,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.circleCheck, size: 14, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              'Mark Done',
              style: TypographyManager.labelSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoneBadge(AppColors c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.tagGreenBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.check, size: 14, color: c.tagGreenText),
          const SizedBox(width: 4),
          Text(
            'Done',
            style: TypographyManager.labelSmall.copyWith(
              color: c.tagGreenText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
