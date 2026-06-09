import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/services/sound_manager.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/typography_manager.dart';
import '../../domain/entities/add_time_validation.dart';
import '../providers/checked_in_guest_stays_provider.dart';

/// Result returned from [ChangeDueTimeBottomSheet] on confirm.
class ChangeDueResult {
  /// Minutes to add to the existing due time. Always positive.
  final int extensionMinutes;
  final String reason;
  const ChangeDueResult({required this.extensionMinutes, required this.reason});
}

typedef ChangeDueConfirmCallback = Future<void> Function(ChangeDueResult);

class ChangeDueTimeBottomSheet extends ConsumerStatefulWidget {
  /// The ID of the ticket being extended. Used only for debug / future hooks.
  final String ticketId;

  /// Current due-at epoch ms from the ticket. Used to calculate the new
  /// due time and validate against guest checkout.
  final int currentDueAtMs;

  /// The room UUID from the ticket (`Ticket.room.id`). Matched against
  /// `CheckedInGuestStay.roomId` to find the active guest stay.
  final String roomId;

  final ChangeDueConfirmCallback? onConfirm;

  const ChangeDueTimeBottomSheet._({
    required this.ticketId,
    required this.currentDueAtMs,
    required this.roomId,
    this.onConfirm,
  });

  /// Opens the sheet. Returns [ChangeDueResult] on confirm, null on dismiss.
  static Future<ChangeDueResult?> show(
    BuildContext context, {
    required String ticketId,
    required int currentDueAtMs,
    required String roomId,
  }) {
    return showModalBottomSheet<ChangeDueResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeDueTimeBottomSheet._(
        ticketId: ticketId,
        currentDueAtMs: currentDueAtMs,
        roomId: roomId,
      ),
    );
  }

  /// Keeps sheet open with spinner during [onConfirm]. Returns true on
  /// success, null on dismiss.
  static Future<bool?> showWithCallback(
    BuildContext context, {
    required String ticketId,
    required int currentDueAtMs,
    required String roomId,
    required ChangeDueConfirmCallback onConfirm,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeDueTimeBottomSheet._(
        ticketId: ticketId,
        currentDueAtMs: currentDueAtMs,
        roomId: roomId,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  ConsumerState<ChangeDueTimeBottomSheet> createState() =>
      _ChangeDueTimeBottomSheetState();
}

class _ChangeDueTimeBottomSheetState
    extends ConsumerState<ChangeDueTimeBottomSheet> {
  static const _chips = [
    (label: '+15 min', minutes: 15),
    (label: '+30 min', minutes: 30),
    (label: '+1 hour', minutes: 60),
    (label: '+3 hours', minutes: 180),
    (label: '+12 hrs', minutes: 720),
    (label: '+24 hrs', minutes: 1440),
  ];

  /// Hard cap on the custom-time stepper. Mirrors the user-facing rule
  /// "user cannot select 24 hour 01 mins" — total custom extension must
  /// strictly fit within a single day (≤ 24:00).
  static const int _maxCustomHours = 24;
  static const int _maxCustomMinutes = 59;

  // +15 min is auto-selected on open.
  int? _selectedMinutes = 15;

  /// When true, the inline hour/minute steppers replace the chip selection
  /// as the source of `_resolvedMinutes`. Toggled by the "Set custom time"
  /// expander.
  bool _customMode = false;
  int _customHours = 0;
  int _customMinutes = 0;

  bool _submitting = false;
  final _reasonCtl = TextEditingController();

  @override
  void dispose() {
    _reasonCtl.dispose();
    super.dispose();
  }

  // ── Resolved extension in minutes ──────────────────────────────────────────

  /// The effective base for due-time calculation.
  /// Uses the ticket's ETA if set, otherwise falls back to now.
  DateTime get _baseDue => widget.currentDueAtMs > 0
      ? DateTime.fromMillisecondsSinceEpoch(widget.currentDueAtMs)
      : DateTime.now();

  /// Minutes to add to the existing due time. In custom-mode this is the
  /// hour+minute stepper value; in chip-mode it's the selected chip.
  int get _resolvedMinutes {
    if (_customMode) {
      return _customHours * 60 + _customMinutes;
    }
    return _selectedMinutes ?? 15;
  }

  /// Always derived from `_baseDue + Duration(minutes: _resolvedMinutes)`.
  /// The displayed "Due …" pill reads off this getter so it stays in sync
  /// with whatever the user is currently choosing.
  DateTime get _resolvedDue =>
      _baseDue.add(Duration(minutes: _resolvedMinutes));

  // ── Guest stay lookup ───────────────────────────────────────────────────────

  /// Returns the guest stay whose room matches the ticket's roomId, or null.
  get _matchingStay {
    final stays = ref
        .watch(checkedInGuestStaysProvider)
        .maybeWhen(data: (l) => l, orElse: () => const []);
    for (final s in stays) {
      if (s.roomId == widget.roomId) return s;
    }
    return null;
  }

  // The checkout-deadline cap is enforced by `validateAddTime` directly
  // from the matched stay — `_resolvedMinutes` past the guest's checkout
  // surfaces as `validation.blockedReason` and disables save. No separate
  // accessor needed now that the custom-date picker is gone.

  // ── Validation ──────────────────────────────────────────────────────────────

  AddTimeValidation get _validation => validateAddTime(
        baseDueAtMs: _baseDue.millisecondsSinceEpoch,
        extensionMinutes: _resolvedMinutes,
        stay: _matchingStay,
      );

  bool get _canSave {
    if (_submitting) return false;
    if (_reasonCtl.text.trim().isEmpty) return false;
    if (!_validation.allowed) return false;
    if (_customMode) {
      // Custom mode requires at least one minute of extension — saving 0
      // would be a no-op the user almost certainly didn't mean.
      return _resolvedMinutes > 0;
    }
    return _selectedMinutes != null;
  }

  // ── Confirm ─────────────────────────────────────────────────────────────────

  Future<void> _handleConfirm() async {
    final result = ChangeDueResult(
      extensionMinutes: _resolvedMinutes,
      reason: _reasonCtl.text.trim(),
    );
    final cb = widget.onConfirm;
    if (cb == null) {
      Navigator.of(context).pop(result);
      return;
    }
    setState(() => _submitting = true);
    try {
      await cb(result);
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) setState(() => _submitting = false);
      rethrow;
    }
  }

  // ── Custom hour / minute steppers ───────────────────────────────────────────

  /// Toggle the inline "Set Custom Time" expander. Entering custom mode
  /// clears the chip selection; exiting it falls back to the +15 min chip
  /// so the form is never in a "nothing selected" state.
  void _toggleCustomMode() {
    setState(() {
      _customMode = !_customMode;
      if (_customMode) {
        _selectedMinutes = null;
        // Reset stepper to 0/0 each time the user opens the section. Keeps
        // the affordance honest — there is no carried-over value to guess.
        _customHours = 0;
        _customMinutes = 0;
      } else {
        _selectedMinutes = 15;
      }
    });
  }

  void _incrementHours() {
    if (_customHours >= _maxCustomHours) return;
    setState(() {
      _customHours++;
      // Total cap is < 24:00 — if the user nudges hours to 24, force
      // minutes back to 0 so the resolved duration never exceeds the day.
      if (_customHours == _maxCustomHours) _customMinutes = 0;
    });
  }

  void _decrementHours() {
    if (_customHours <= 0) return;
    setState(() => _customHours--);
  }

  void _incrementMinutes() {
    // Reject any nudge that would push the total past 24:00. Practically
    // this means "minutes are pinned to 0 once hours == 24".
    if (_customHours == _maxCustomHours) return;
    if (_customMinutes >= _maxCustomMinutes) return;
    setState(() => _customMinutes++);
  }

  void _decrementMinutes() {
    if (_customMinutes <= 0) return;
    setState(() => _customMinutes--);
  }

  // ── Formatters ──────────────────────────────────────────────────────────────

  String _formatDue(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = h >= 12 ? 'PM' : 'AM';
    final hour12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}, $hour12:$m $ampm';
  }

  String _descriptionText() =>
      'Choose time. It will be added to your existing due time to close the ticket.';

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final validation = _validation;

    return PopScope(
      canPop: !_submitting,
      child: Container(
        decoration: BoxDecoration(
          color: c.bgBase,
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
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Do you want to add time?',
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
            const SizedBox(height: 4),
            // Description
            Text(
              _descriptionText(),
              style: TypographyManager.bodySmall.copyWith(color: c.fgMuted),
            ),
            const SizedBox(height: 16),
            Text(
              'SELECT TIME',
              style: TypographyManager.labelSmall.copyWith(
                color: c.fgMuted,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            // Chips grid
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _chips.map((chip) {
                final selected =
                    !_customMode && _selectedMinutes == chip.minutes;
                // Hide chips whose extension exceeds the checkout budget.
                final blocked = !validation.chipVisible(chip.minutes);
                return GestureDetector(
                  onTap: blocked
                      ? null
                      : tapSound(
                          () => setState(() {
                            _selectedMinutes = chip.minutes;
                            _customMode = false;
                          }),
                          SoundCategory.preference,
                        ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: blocked
                          ? c.bgSubtle.withValues(alpha: 0.5)
                          : selected
                              ? c.tagPurpleBg
                              : c.bgSubtle,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: blocked
                            ? c.borderBase.withValues(alpha: 0.4)
                            : selected
                                ? c.tagPurpleIcon
                                : c.borderBase,
                        width: selected ? 1.4 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.clock,
                          size: 13,
                          color: blocked
                              ? c.fgMuted.withValues(alpha: 0.4)
                              : selected
                                  ? c.tagPurpleIcon
                                  : c.fgMuted,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          chip.label,
                          style: TypographyManager.labelSmall.copyWith(
                            color: blocked
                                ? c.fgMuted.withValues(alpha: 0.4)
                                : selected
                                    ? c.tagPurpleText
                                    : c.fgBase,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            // ── Custom time expander ────────────────────────────────────
            // Toggle row — tapping flips `_customMode`. The hour/minute
            // steppers below render only when expanded.
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: tapSound(_toggleCustomMode, SoundCategory.preference),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      _customMode
                          ? LucideIcons.chevronUp
                          : LucideIcons.chevronDown,
                      size: 14,
                      color: c.fgMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Set Custom Time',
                      style: TypographyManager.bodySmall.copyWith(
                        color: c.fgBase,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_customMode) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _NumericStepper(
                      value: _customHours,
                      unitLabel: 'hour(s)',
                      onMinus: _customHours > 0 ? _decrementHours : null,
                      onPlus: _customHours < _maxCustomHours
                          ? _incrementHours
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _NumericStepper(
                      value: _customMinutes,
                      unitLabel: 'minute(s)',
                      onMinus: _customMinutes > 0 ? _decrementMinutes : null,
                      // When hours hit 24, minutes are pinned at 0 — the
                      // plus button is disabled to make the cap obvious.
                      onPlus: (_customHours < _maxCustomHours &&
                              _customMinutes < _maxCustomMinutes)
                          ? _incrementMinutes
                          : null,
                    ),
                  ),
                ],
              ),
            ],
            // ── Resulting "Due …" pill — same look as before, just driven
            //    by the unified `_resolvedDue` getter.
            if (_selectedMinutes != null ||
                (_customMode && _resolvedMinutes > 0)) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: c.tagPurpleBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: c.tagPurpleIcon),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.clock, size: 14, color: c.tagPurpleIcon),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Due ${_formatDue(_resolvedDue)}',
                        style: TypographyManager.bodySmall.copyWith(
                          color: c.tagPurpleText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Blocked reason banner
            if (!validation.allowed && validation.blockedReason != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: c.tagRedBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: c.tagRedIcon),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      LucideIcons.alertCircle,
                      size: 16,
                      color: c.tagRedIcon,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        validation.blockedReason!,
                        style: TypographyManager.bodySmall.copyWith(
                          color: c.tagRedText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            // Reason field (required) — hidden when blocked to keep UX clean.
            if (validation.allowed) ...[
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Reason for change ',
                      style: TypographyManager.bodySmall.copyWith(
                        color: c.fgBase,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(
                      text: '*',
                      style: TypographyManager.bodySmall.copyWith(
                        color: c.tagRedIcon,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _reasonCtl,
                maxLines: 3,
                onChanged: (_) => setState(() {}),
                style: TypographyManager.bodyMedium.copyWith(color: c.fgBase),
                decoration: InputDecoration(
                  hintText: 'Why is the due time being changed?',
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
              // Save / Cancel buttons
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
                    child: ElevatedButton(
                      onPressed: _canSave ? tapSound(_handleConfirm) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: c.buttonInverted,
                        foregroundColor: c.fgOnInverted,
                        disabledBackgroundColor: c.bgDisabled,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: TypographyManager.labelLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: _submitting
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  context.appColors.fgOnBrand,
                                ),
                              ),
                            )
                          : Text(context.l10n.save),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Compact `−  NN unit  +` pill used by the custom-time expander.
///
/// - `value` is always rendered as a zero-padded two-digit number so 0 reads
///   as "00", 5 reads as "05", matching the spec.
/// - `unitLabel` is the suffix shown after the value (e.g. "hour(s)" or
///   "minute(s)"); kept as a string so the same widget can drive both
///   steppers without enums.
/// - `onMinus` / `onPlus` are nullable: a null callback renders the button
///   in a disabled state and ignores taps. The caller is responsible for
///   the clamping logic (see `_decrementHours` / `_incrementMinutes` in
///   the parent state).
class _NumericStepper extends StatelessWidget {
  final int value;
  final String unitLabel;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  const _NumericStepper({
    required this.value,
    required this.unitLabel,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: c.bgSubtle,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.borderBase),
      ),
      child: Row(
        children: [
          _StepperButton(
            icon: LucideIcons.minus,
            onTap: onMinus,
          ),
          Expanded(
            child: Center(
              child: Text(
                '${value.toString().padLeft(2, '0')} $unitLabel',
                style: TypographyManager.bodyMedium.copyWith(
                  color: c.fgBase,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          _StepperButton(
            icon: LucideIcons.plus,
            onTap: onPlus,
          ),
        ],
      ),
    );
  }
}

/// 36×36 square tap-target for the stepper's `−` / `+` buttons. Null
/// `onTap` renders the icon in a muted disabled colour and swallows taps.
class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _StepperButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    final enabled = onTap != null;
    return InkWell(
      onTap: enabled ? tapSound(onTap!, SoundCategory.preference) : null,
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 36,
        height: 36,
        child: Icon(
          icon,
          size: 16,
          color: enabled ? c.fgBase : c.fgDisabled,
        ),
      ),
    );
  }
}
