import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/services/sound_manager.dart';
import '../../../../core/theme/card_theme.dart';
import '../../../../core/theme/unified_theme_manager.dart';
import '../../../../core/theme/typography_manager.dart';

typedef ResumeConfirmCallback = Future<void> Function(String reason);

class ResumeToInProgressBottomSheet extends StatefulWidget {
  final ResumeConfirmCallback? onConfirm;
  const ResumeToInProgressBottomSheet._({this.onConfirm});

  @override
  State<ResumeToInProgressBottomSheet> createState() =>
      _ResumeToInProgressBottomSheetState();
}

class _ResumeToInProgressBottomSheetState
    extends State<ResumeToInProgressBottomSheet> {
  final _controller = TextEditingController();
  bool _submitting = false;

  bool get _canSubmit => _controller.text.trim().isNotEmpty;

  Future<void> _handleConfirm() async {
    if (!_canSubmit) return;
    final cb = widget.onConfirm;
    if (cb == null) {
      Navigator.of(context).pop(_controller.text.trim());
      return;
    }
    setState(() => _submitting = true);
    try {
      await cb(_controller.text.trim());
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) setState(() => _submitting = false);
      rethrow;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    final s = context.l10n;
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    s.resumeToInProgressSheetTitle,
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
                      : tapSound(
                          () => Navigator.of(context).pop(),
                          SoundCategory.back,
                        ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              s.resumeToInProgressSheetSubtitle,
              style: TypographyManager.bodySmall.copyWith(color: c.fgMuted),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              enabled: !_submitting,
              maxLines: 4,
              style: TypographyManager.bodyMedium.copyWith(color: c.fgBase),
              decoration: InputDecoration(
                hintText: s.resumeToInProgressSheetHint,
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
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _submitting
                        ? null
                        : tapSound(
                            () => Navigator.of(context).pop(),
                            SoundCategory.back,
                          ),
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
                    onPressed: (_submitting || !_canSubmit)
                        ? null
                        : tapSound(_handleConfirm),
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
                        : const Icon(LucideIcons.play, size: 18),
                    label: Text(s.resumeToInProgressSheetConfirm),
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

Future<bool?> showResumeToInProgressBottomSheet({
  required BuildContext context,
  ResumeConfirmCallback? onConfirm,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) =>
        ResumeToInProgressBottomSheet._(onConfirm: onConfirm),
  );
}
