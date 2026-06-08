import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/services/sound_manager.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/typography_manager.dart';

typedef ResetConfirmCallback = Future<void> Function();

class ResetAcknowledgementBottomSheet extends StatefulWidget {
  final ResetConfirmCallback? onConfirm;
  const ResetAcknowledgementBottomSheet._({this.onConfirm});

  /// Returns true if user confirmed reset, null if dismissed.
  /// When [onConfirm] is provided, sheet stays open with spinner until
  /// the callback resolves; pops with `true` only on success.
  static Future<bool?> show(
    BuildContext context, {
    ResetConfirmCallback? onConfirm,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ResetAcknowledgementBottomSheet._(onConfirm: onConfirm),
    );
  }

  @override
  State<ResetAcknowledgementBottomSheet> createState() =>
      _ResetAcknowledgementBottomSheetState();
}

class _ResetAcknowledgementBottomSheetState
    extends State<ResetAcknowledgementBottomSheet> {
  bool _submitting = false;

  Future<void> _handleConfirm() async {
    final cb = widget.onConfirm;
    if (cb == null) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() => _submitting = true);
    try {
      await cb();
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) setState(() => _submitting = false);
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;

    return PopScope(
      canPop: !_submitting,
      child: Container(
      decoration: BoxDecoration(
        color: c.bgBase,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
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
                  'Reset acknowledgement',
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
          const SizedBox(height: 12),
          // Body text with NEW bolded
          RichText(
            text: TextSpan(
              style: TypographyManager.bodyMedium.copyWith(color: c.fgMuted),
              children: [
                const TextSpan(text: 'This ticket will go back to '),
                TextSpan(
                  text: 'NEW',
                  style: TypographyManager.bodyMedium.copyWith(
                    color: c.fgBase,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const TextSpan(
                  text:
                      ' status and the due time will be cleared. You can acknowledge it again afterwards.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
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
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(context.appColors.fgOnBrand),
                          ),
                        )
                      : const Icon(LucideIcons.rotateCcw, size: 18),
                  label: const Text('Reset'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.tagRedIcon,
                    foregroundColor: context.appColors.fgOnBrand,
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
