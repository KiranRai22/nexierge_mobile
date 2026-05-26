import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/services/sound_manager.dart';
import '../../../../core/theme/unified_theme_manager.dart';
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

  // +15 min is auto-selected on open.
  int? _selectedMinutes = 15;
  DateTime? _customDue;
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

  int get _resolvedMinutes {
    if (_customDue != null) {
      final diff = _customDue!.difference(DateTime.now()).inMinutes;
      return diff > 0 ? diff : 1;
    }
    return _selectedMinutes ?? 15;
  }

  DateTime get _resolvedDue {
    if (_customDue != null) return _customDue!;
    return _baseDue.add(Duration(minutes: _resolvedMinutes));
  }

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

  // ── Checkout cap for the custom date picker ─────────────────────────────────

  DateTime? get _checkoutDeadline {
    final stay = _matchingStay;
    if (stay == null) return null;
    final raw = stay.checkoutDate;
    if (raw.isEmpty) return null;
    try {
      return DateTime.parse(raw).toLocal();
    } catch (_) {}
    final ms = int.tryParse(raw);
    if (ms != null) return DateTime.fromMillisecondsSinceEpoch(ms).toLocal();
    return null;
  }

  // ── Validation ──────────────────────────────────────────────────────────────

  AddTimeValidation get _validation => validateAddTime(
        baseDueAtMs: _baseDue.millisecondsSinceEpoch,
        extensionMinutes: _resolvedMinutes,
        stay: _matchingStay,
      );

  bool get _canSave =>
      !_submitting &&
      (_selectedMinutes != null || _customDue != null) &&
      _reasonCtl.text.trim().isNotEmpty &&
      _validation.allowed;

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

  // ── Custom date/time picker ─────────────────────────────────────────────────

  Future<void> _pickCustom() async {
    final deadline = _checkoutDeadline;
    final lastDate = deadline != null
        ? deadline
        : DateTime.now().add(const Duration(days: 365));

    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: lastDate,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null || !mounted) return;
    setState(() {
      _customDue = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      _selectedMinutes = null;
    });
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
                    _customDue == null && _selectedMinutes == chip.minutes;
                // Hide chips whose extension exceeds the checkout budget.
                final blocked = !validation.chipVisible(chip.minutes);
                return GestureDetector(
                  onTap: blocked
                      ? null
                      : tapSound(
                          () => setState(() {
                            _selectedMinutes = chip.minutes;
                            _customDue = null;
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
                          ? c.bgSubtle.withOpacity(0.5)
                          : selected
                              ? c.tagPurpleBg
                              : c.bgSubtle,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: blocked
                            ? c.borderBase.withOpacity(0.4)
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
                              ? c.fgMuted.withOpacity(0.4)
                              : selected
                                  ? c.tagPurpleIcon
                                  : c.fgMuted,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          chip.label,
                          style: TypographyManager.labelSmall.copyWith(
                            color: blocked
                                ? c.fgMuted.withOpacity(0.4)
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
            // Custom date/time toggle
            GestureDetector(
              onTap: tapSound(_pickCustom, SoundCategory.preference),
              child: Row(
                children: [
                  Icon(LucideIcons.chevronDown, size: 14, color: c.fgMuted),
                  const SizedBox(width: 4),
                  Text(
                    'Set custom date/time',
                    style: TypographyManager.bodySmall.copyWith(
                      color: c.fgBase,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (_customDue != null || _selectedMinutes != null) ...[
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
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text('Save'),
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
