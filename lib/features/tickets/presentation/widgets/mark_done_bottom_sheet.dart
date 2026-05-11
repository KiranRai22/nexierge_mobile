import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/services/sound_manager.dart';
import '../../../../core/theme/card_theme.dart';
import '../../../../core/theme/unified_theme_manager.dart';
import '../../../../core/theme/typography_manager.dart';

typedef MarkDoneConfirmCallback = Future<void> Function(String note);

class MarkDoneBottomSheet extends StatefulWidget {
  final MarkDoneConfirmCallback? onConfirm;
  const MarkDoneBottomSheet._({this.onConfirm});

  /// Legacy: pops with note string on confirm, null on dismiss.
  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const MarkDoneBottomSheet._(),
    );
  }

  /// Keeps sheet open with spinner during [onConfirm]. Returns true on
  /// success, null on dismiss.
  static Future<bool?> showWithCallback(
    BuildContext context, {
    required MarkDoneConfirmCallback onConfirm,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MarkDoneBottomSheet._(onConfirm: onConfirm),
    );
  }

  @override
  State<MarkDoneBottomSheet> createState() => _MarkDoneBottomSheetState();
}

class _MarkDoneBottomSheetState extends State<MarkDoneBottomSheet> {
  final _noteCtl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _noteCtl.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm() async {
    final cb = widget.onConfirm;
    final note = _noteCtl.text;
    if (cb == null) {
      Navigator.of(context).pop(note);
      return;
    }
    setState(() => _submitting = true);
    try {
      await cb(note);
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) setState(() => _submitting = false);
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return PopScope(
      canPop: !_submitting,
      child: Container(
      decoration: CardDecoration.subtle(
        colors: c,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + viewInsets),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: c.borderBase,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header row
          Row(
            children: [
              Expanded(
                child: Text(
                  'Mark ticket as done',
                  style: TypographyManager.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: c.fgBase,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(LucideIcons.x, size: 20, color: c.fgMuted),
                onPressed: _submitting
                    ? null
                    : tapSound(() => Navigator.of(context).pop(), SoundCategory.back),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Optionally add a resolution note before closing this ticket.',
            style: TypographyManager.bodySmall.copyWith(color: c.fgMuted),
          ),
          const SizedBox(height: 16),
          // Note field
          TextField(
            controller: _noteCtl,
            enabled: !_submitting,
            maxLines: 4,
            style: TypographyManager.bodyMedium.copyWith(color: c.fgBase),
            decoration: InputDecoration(
              hintText: 'Resolution note (optional)...',
              hintStyle: TypographyManager.bodyMedium.copyWith(
                color: c.fgMuted,
              ),
              filled: true,
              fillColor: c.bgSubtle,
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: c.borderBase),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: c.borderBase),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: c.tagPurpleIcon),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _submitting
                      ? null
                      : tapSound(() => Navigator.of(context).pop(), SoundCategory.back),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: c.borderBase),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: TypographyManager.labelLarge.copyWith(
                      color: c.fgBase,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _submitting ? null : tapSound(_handleConfirm),
                  icon: _submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(LucideIcons.circleCheck, size: 18),
                  label: const Text('Mark as Done'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.buttonInverted,
                    foregroundColor: c.fgOnInverted,
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
          ),
        ],
      ),
    ),
    );
  }
}
