import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/services/sound_manager.dart';
import '../../../../core/utils/string_utils.dart';
import '../../../../core/theme/card_theme.dart';
import '../../../../core/theme/unified_theme_manager.dart';
import '../../../../core/theme/typography_manager.dart';

typedef MarkDoneConfirmCallback = Future<void> Function(String note);

class MarkDoneBottomSheet extends StatefulWidget {
  final MarkDoneConfirmCallback? onConfirm;

  /// When true, the note field is required — the confirm button stays
  /// disabled until the user types at least one non-whitespace character.
  /// Use this for overdue / force-done flows.
  final bool isRequired;

  const MarkDoneBottomSheet._({this.onConfirm, this.isRequired = false});

  /// Legacy: pops with note string on confirm, null on dismiss.
  static Future<String?> show(
    BuildContext context, {
    bool isRequired = false,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MarkDoneBottomSheet._(isRequired: isRequired),
    );
  }

  /// Keeps sheet open with spinner during [onConfirm]. Returns true on
  /// success, null on dismiss.
  static Future<bool?> showWithCallback(
    BuildContext context, {
    required MarkDoneConfirmCallback onConfirm,
    bool isRequired = false,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MarkDoneBottomSheet._(
        onConfirm: onConfirm,
        isRequired: isRequired,
      ),
    );
  }

  @override
  State<MarkDoneBottomSheet> createState() => _MarkDoneBottomSheetState();
}

class _MarkDoneBottomSheetState extends State<MarkDoneBottomSheet> {
  final _noteCtl = TextEditingController();
  bool _submitting = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _noteCtl.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = _noteCtl.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  @override
  void dispose() {
    _noteCtl.removeListener(_onTextChanged);
    _noteCtl.dispose();
    super.dispose();
  }

  void _onNoteChanged(String value) {
    final capitalized = StringUtils.capitalizeFirst(value);
    if (capitalized != value) {
      final cursorOffset = _noteCtl.selection.base.offset;
      _noteCtl.value = TextEditingValue(
        text: capitalized,
        selection: TextSelection.collapsed(
          offset: cursorOffset <= capitalized.length
              ? cursorOffset
              : capitalized.length,
        ),
      );
    }
  }

  bool get _canConfirm {
    if (_submitting) return false;
    if (widget.isRequired) return _hasText;
    return true;
  }

  Future<void> _handleConfirm() async {
    if (!_canConfirm) return;
    final cb = widget.onConfirm;
    final note = StringUtils.capitalizeFirst(_noteCtl.text.trim());
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
    final s = context.l10n;
    final c = context.themeColors;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final isRequired = widget.isRequired;

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
                    s.markDoneSheetTitle,
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
              isRequired
                  ? s.markDoneSheetSubtitleRequired
                  : s.markDoneSheetSubtitleOptional,
              style: TypographyManager.bodySmall.copyWith(
                color: isRequired ? c.tagRedIcon : c.fgMuted,
              ),
            ),
            const SizedBox(height: 16),
            // Note field
            TextField(
              controller: _noteCtl,
              onChanged: _onNoteChanged,
              enabled: !_submitting,
              maxLines: 4,
              style: TypographyManager.bodyMedium.copyWith(color: c.fgBase),
              decoration: InputDecoration(
                hintText: isRequired
                    ? s.markDoneSheetHintRequired
                    : s.markDoneSheetHintOptional,
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
                  borderSide: BorderSide(
                    color: isRequired && !_hasText
                        ? c.tagRedIcon
                        : c.borderBase,
                  ),
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
                      s.cancel,
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
                    onPressed: _canConfirm ? tapSound(_handleConfirm) : null,
                    icon: _submitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(LucideIcons.circleCheck, size: 18),
                    label: Text(s.ticketActionMarkDone),
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
