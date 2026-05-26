import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/services/sound_manager.dart';
import '../../../../core/theme/unified_theme_manager.dart';
import '../../../../core/theme/typography_manager.dart';

/// Optional async callback. If provided, the sheet keeps itself open
/// with a spinner on the confirm button until [onConfirm] resolves; the
/// sheet pops with `true` only on success. If null, the sheet pops with
/// `true` immediately on tap (legacy behaviour).
typedef SheetConfirmCallback = Future<void> Function();

class StartWorkConfirmationBottomSheet extends StatefulWidget {
  final SheetConfirmCallback? onConfirm;
  const StartWorkConfirmationBottomSheet._({this.onConfirm});

  @override
  State<StartWorkConfirmationBottomSheet> createState() =>
      _StartWorkConfirmationBottomSheetState();
}

class _StartWorkConfirmationBottomSheetState
    extends State<StartWorkConfirmationBottomSheet> {
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: c.borderBase,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          // Header row with close
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Start working on this ticket?',
                    style: TypographyManager.headlineSmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: c.fgBase,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(LucideIcons.x, size: 20, color: c.fgMuted),
                  onPressed: tapSound(() => Navigator.of(context).pop(), SoundCategory.back),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'This will notify that the team has started preparing or resolving the request.',
              style: TypographyManager.bodyMedium.copyWith(
                color: c.fgMuted,
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Countdown card
          // Container(
          //   margin: const EdgeInsets.symmetric(horizontal: 24),
          //   padding: const EdgeInsets.all(16),
          //   decoration: BoxDecoration(
          //     color: c.tagPurpleBg,
          //     borderRadius: BorderRadius.circular(12),
          //     border: Border.all(color: c.tagPurpleIcon.withValues(alpha: 0.3)),
          //   ),
          //   child: Row(
          //     children: [
          //       Container(
          //         padding: const EdgeInsets.all(8),
          //         decoration: BoxDecoration(
          //           color: c.tagPurpleIcon,
          //           borderRadius: BorderRadius.circular(8),
          //         ),
          //         child: const Icon(LucideIcons.play, size: 20, color: Colors.white),
          //       ),
          //       const SizedBox(width: 12),
          //       Expanded(
          //         child: Column(
          //           crossAxisAlignment: CrossAxisAlignment.start,
          //           children: [
          //             Text(
          //               'Countdown will start now',
          //               style: TypographyManager.bodyMedium.copyWith(
          //                 fontWeight: FontWeight.w600,
          //                 color: c.fgBase,
          //               ),
          //             ),
          //             const SizedBox(height: 2),
          //             Text(
          //               'The preparation timer begins the moment you confirm.',
          //               style: TypographyManager.bodySmall.copyWith(
          //                 color: c.fgMuted,
          //               ),
          //             ),
          //           ],
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
          // const SizedBox(height: 28),
          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _submitting
                        ? null
                        : tapSound(() => Navigator.of(context).pop(), SoundCategory.back),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: c.borderBase),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
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
                const SizedBox(width: 16),
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
                        : const Icon(LucideIcons.circlePlay, size: 18),
                    label: const Text('Start Work'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: c.buttonInverted,
                      foregroundColor: c.fgOnInverted,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: TypographyManager.labelLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    ),
    );
  }
}

/// Shows the Start Work confirmation sheet.
///
/// If [onConfirm] is provided the sheet stays open with a spinner on the
/// primary button until the callback completes; it pops with `true` only
/// on success. Throwing inside [onConfirm] keeps the sheet open so the
/// user can retry. With no callback it pops with `true` on tap (legacy).
Future<bool?> showStartWorkConfirmation({
  required BuildContext context,
  SheetConfirmCallback? onConfirm,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) =>
        StartWorkConfirmationBottomSheet._(onConfirm: onConfirm),
  );
}
