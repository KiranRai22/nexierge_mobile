import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/theme/typography_manager.dart';
import '../../../../core/theme/unified_theme_manager.dart';

/// Animated empty state for ticket lists and the needs-attention section.
///
/// Shows:
///   • Inbox icon with 3 staggered expanding ripple rings
///   • Typewriter text cycling through four status phrases
///   • Blinking cursor `|`
///   • "Live · realtime connected" footer
///
/// [compact] — wrap in a `Column` instead of a pull-to-refresh `ListView`.
/// Use `compact: true` when the widget is already inside a scroll view.
class LiveEmptyState extends StatefulWidget {
  final bool compact;
  const LiveEmptyState({super.key, this.compact = false});

  @override
  State<LiveEmptyState> createState() => _LiveEmptyStateState();
}

class _LiveEmptyStateState extends State<LiveEmptyState>
    with SingleTickerProviderStateMixin {
  // ── Ripple ──────────────────────────────────────────────────────────────────
  late final AnimationController _ripple;

  // ── Typewriter ───────────────────────────────────────────────────────────────
  late List<String> _phrases;
  int _phraseIndex = 0;
  int _charCount = 0;
  Timer? _typeTimer;

  // ── Cursor blink ─────────────────────────────────────────────────────────────
  bool _cursorVisible = true;
  Timer? _cursorTimer;

  @override
  void initState() {
    super.initState();
    _ripple = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Build phrase list from l10n (safe here — context available).
    final s = context.l10n;
    _phrases = [
      s.liveEmptyAiOnWatch,
      s.liveEmptyWaitingForGuests,
      s.liveEmptyChannelsOpen,
      s.liveEmptyListening,
    ];
    // Start only once.
    if (_typeTimer == null) {
      _startTyping();
      _startCursorBlink();
    }
  }

  // ── Typewriter logic ─────────────────────────────────────────────────────────

  void _startTyping() {
    _typeTimer?.cancel();
    // Type one character every 65 ms.
    _typeTimer = Timer.periodic(const Duration(milliseconds: 65), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      final full = _phrases[_phraseIndex];
      if (_charCount < full.length) {
        setState(() => _charCount++);
      } else {
        // Full phrase visible — pause 2.4 s then move to next phrase.
        t.cancel();
        _typeTimer = Timer(const Duration(milliseconds: 2400), () {
          if (!mounted) return;
          setState(() {
            _phraseIndex = (_phraseIndex + 1) % _phrases.length;
            _charCount = 0;
          });
          _startTyping();
        });
      }
    });
  }

  void _startCursorBlink() {
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 530), (_) {
      if (mounted) setState(() => _cursorVisible = !_cursorVisible);
    });
  }

  @override
  void dispose() {
    _ripple.dispose();
    _typeTimer?.cancel();
    _cursorTimer?.cancel();
    super.dispose();
  }

  // ── Ring builder ─────────────────────────────────────────────────────────────

  Widget _ring(BuildContext context, double offset, AppColors c) {
    return AnimatedBuilder(
      animation: _ripple,
      builder: (_, __) {
        final v = (_ripple.value + offset) % 1.0;
        final size = 60.0 + v * 54.0; // 60 → 114 px diameter
        final opacity = (1.0 - v) * 0.18;
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: c.fgMuted.withValues(alpha: opacity),
              width: 1.5,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    final s = context.l10n;
    final phrase = _phrases[_phraseIndex].substring(0, _charCount);
    final cursor = _cursorVisible ? '|' : '';

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Icon with ripple rings ────────────────────────────────────────────
        Center(
          child: SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _ring(context, 0.0, c),
                _ring(context, 0.333, c),
                _ring(context, 0.667, c),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: c.bgSubtle,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: c.fgDisabled.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Icon(LucideIcons.inbox, size: 24, color: c.fgMuted),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // ── Typewriter phrase ─────────────────────────────────────────────────
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _GreenDot(),
              const SizedBox(width: 8),
              Text(
                '$phrase$cursor',
                style: TypographyManager.bodyMedium.copyWith(
                  color: c.fgBase,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // ── Live · realtime connected ─────────────────────────────────────────
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.wifi, size: 12, color: c.fgSubtle),
              const SizedBox(width: 5),
              Text(
                s.liveEmptyRealtimeLabel,
                style: TypographyManager.cardMeta.copyWith(
                  color: c.fgSubtle,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (widget.compact) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: content,
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [const SizedBox(height: 96), content],
    );
  }
}

// ── Pulsing green dot ──────────────────────────────────────────────────────────

class _GreenDot extends StatefulWidget {
  @override
  State<_GreenDot> createState() => _GreenDotState();
}

class _GreenDotState extends State<_GreenDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: ColorPalette.ticketStripeDone,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
