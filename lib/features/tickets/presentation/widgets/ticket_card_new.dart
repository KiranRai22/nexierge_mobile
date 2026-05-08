import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/theme/card_theme.dart';
import '../../../../core/theme/unified_theme_manager.dart';
import '../../../../core/theme/typography_manager.dart';
import '../../../../core/widgets/shimmer_widget.dart';
import '../../domain/models/ticket.dart';
import '../providers/my_tickets_notifier.dart';

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
    final isFresh = ref.watch(isFreshlyArrivedProvider(ticket.id));

    // Only show shimmer effect for transitioning tickets
    final cardContent = Semantics(
      button: true,
      label: '${ticket.code} ${ticket.title}',
      child: Material(
        color: c.bgBase,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: CardDecoration.standard(
              colors: c,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title row: dot + title + timer
                  _TitleRow(ticket: ticket),
                  const SizedBox(height: 6),
                  // Room row: icon + room + department
                  _RoomRow(ticket: ticket),
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

    // Apply shimmer effect only when ticket is transitioning
    if (ticket.isTransitioning) {
      return ShimmerWidget(
        baseColor: c.bgBase,
        highlightColor: c.bgHighlight,
        child: cardContent,
      );
    }

    return cardContent;
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
    final catalog = ticket.kindData is CatalogKindData
        ? ticket.kindData as CatalogKindData
        : null;
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
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            _TimeDisplay(ticket: ticket),
            if (catalog != null && catalog.grandTotal > 0) ...[
              const SizedBox(height: 2),
              Text(
                _formatMoney(catalog.grandTotal, catalog.currency),
                style: TypographyManager.bodySmall.copyWith(
                  color: c.fgBase,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
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

    final now = DateTime.now();
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

class _RoomRow extends StatelessWidget {
  final Ticket ticket;
  const _RoomRow({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    return Row(
      children: [
        Icon(LucideIcons.doorOpen, size: 14, color: c.fgMuted),
        const SizedBox(width: 4),
        Text(
          '${ticket.room.number} · ${_departmentLabel(context, ticket)}',
          style: TypographyManager.bodySmall.copyWith(color: c.fgMuted),
        ),
      ],
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
          _RoundThumbnail(
            imageUrl: data.thumbnailUrl,
            emoji: data.emoji ?? '•',
            size: 40,
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
      return _RoundThumbnail(
        imageUrl: null,
        emoji: fallbackEmoji,
      );
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
    return Row(
      children: [
        _TypeTag(kind: ticket.kind),
        const Spacer(),
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
      TicketKind.manual => (
        c.bgSubtle,
        c.fgMuted,
        s.ticketKindManual,
      ),
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
      _ => _buildAcceptButton(c, onAccept),
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
          onTap: onTap,
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

  Widget _buildStartWorkButton(AppColors c, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
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
      onTap: onTap,
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
