import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/services/sound_manager.dart';
import '../../../../core/theme/card_theme.dart';
import '../../../../core/theme/typography_manager.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/time/server_clock.dart';

/// Result data when acknowledging a ticket with ETA selection
class AcknowledgeTicketResult {
  final String mode; // 'preset', 'custom'
  final int? minutesFromNow;
  final DateTime? customDateTime;
  final String readyByLabel;
  final String buttonLabel;

  /// True when the user picked "Accept & Start" — caller should transition
  /// the ticket directly to IN_PROGRESS instead of stopping at ACCEPTED.
  final bool startImmediately;

  /// Optional staff note typed into the sheet. Trimmed; null when blank so
  /// the API receives `null` rather than an empty string.
  final String? notes;

  /// Resolved due-at as epoch ms, ready to ship to
  /// `/tickets/acknowledge` / `/tickets/acknowledge_and_start`. Always
  /// computed on the client from the picked preset or custom date/time so
  /// the caller doesn't need to redo the math.
  final int dueAtEpochMs;

  const AcknowledgeTicketResult({
    required this.mode,
    this.minutesFromNow,
    this.customDateTime,
    required this.readyByLabel,
    required this.buttonLabel,
    required this.dueAtEpochMs,
    this.startImmediately = false,
    this.notes,
  });
}

/// Bottom sheet for acknowledging tickets with ETA selection.
///
/// Theme-tokenised: selected chips use the ops purple tag palette, the
/// confirm button uses the inverted button color, and the custom-time
/// row collapses to a compact toggle that expands into a purple info
/// card when a date is picked.
typedef AcknowledgeConfirmCallback =
    Future<void> Function(AcknowledgeTicketResult);

class AcknowledgeTicketBottomSheet {
  /// Legacy: pops with the picked result on confirm; caller fires the API.
  static Future<AcknowledgeTicketResult?> show({
    required BuildContext context,
    required String ticketCode,
    required String ticketTitle,
    required bool hasGuest,
  }) {
    return showModalBottomSheet<AcknowledgeTicketResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AcknowledgeTicketSheetBody(
        ticketCode: ticketCode,
        ticketTitle: ticketTitle,
        hasGuest: hasGuest,
      ),
    );
  }

  /// Keeps the sheet open with a spinner on the confirm button while
  /// [onConfirm] runs the API call. Pops with `true` only on success.
  static Future<bool?> showWithCallback({
    required BuildContext context,
    required String ticketCode,
    required String ticketTitle,
    required bool hasGuest,
    required AcknowledgeConfirmCallback onConfirm,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AcknowledgeTicketSheetBody(
        ticketCode: ticketCode,
        ticketTitle: ticketTitle,
        hasGuest: hasGuest,
        onConfirm: onConfirm,
      ),
    );
  }
}

class _AcknowledgeTicketSheetBody extends StatefulWidget {
  final String ticketCode;
  final String ticketTitle;
  final bool hasGuest;
  final AcknowledgeConfirmCallback? onConfirm;

  const _AcknowledgeTicketSheetBody({
    required this.ticketCode,
    required this.ticketTitle,
    required this.hasGuest,
    this.onConfirm,
  });

  @override
  State<_AcknowledgeTicketSheetBody> createState() =>
      _AcknowledgeTicketSheetBodyState();
}

class _AcknowledgeTicketSheetBodyState
    extends State<_AcknowledgeTicketSheetBody> {
  int _selectedMinutes = 15;
  DateTime? _customDateTime;
  bool _isCustomDateTime = false;
  bool _customExpanded = false;
  final TextEditingController _noteController = TextEditingController();
  bool _submitting = false;

  static const List<_PresetOption> _presets = [
    _PresetOption(minutes: 15, label: '+15 min', icon: LucideIcons.clock),
    _PresetOption(minutes: 30, label: '+30 min', icon: LucideIcons.clock),
    _PresetOption(minutes: 60, label: '+1 hour', icon: LucideIcons.clock),
    _PresetOption(minutes: 180, label: '+3 hours', icon: LucideIcons.clock),
    _PresetOption(minutes: 1440, label: '+1 day', icon: LucideIcons.calendar),
    _PresetOption(minutes: 4320, label: '+3 days', icon: LucideIcons.calendar),
  ];

  /// The due date/time the user has currently picked — either the custom
  /// date/time or `now + selectedMinutes`. Driven by [ServerClock] so it's
  /// consistent with the rest of the app's clock semantics.
  DateTime get _effectiveDueDateTime {
    if (_isCustomDateTime && _customDateTime != null) return _customDateTime!;
    return ServerClock.now().add(Duration(minutes: _selectedMinutes));
  }

  /// Whether the picked due time falls inside today (local calendar). Drives
  /// visibility of the "Accept & Start" button — only meaningful when work
  /// is expected to begin today.
  bool get _isDueToday {
    final due = _effectiveDueDateTime;
    final now = ServerClock.now();
    return due.year == now.year &&
        due.month == now.month &&
        due.day == now.day;
  }

  String get _readyByLabel {
    if (_isCustomDateTime && _customDateTime != null) {
      return 'Ready by ${_formatDateTime(_customDateTime!)}';
    }
    return 'Ready by ${_formatDateTime(ServerClock.now().add(Duration(minutes: _selectedMinutes)))}';
  }

  String get _buttonTimeLabel {
    if (_isCustomDateTime && _customDateTime != null) {
      return '· at ${_formatDateTime(_customDateTime!)}';
    }
    if (_selectedMinutes >= 60) {
      final hours = _selectedMinutes ~/ 60;
      return '· $hours hour${hours > 1 ? 's' : ''}';
    }
    return '· $_selectedMinutes min';
  }

  String _formatDateTime(DateTime dt) {
    final now = ServerClock.now();
    final isToday =
        dt.day == now.day && dt.month == now.month && dt.year == now.year;
    final hour12 = dt.hour > 12
        ? dt.hour - 12
        : dt.hour == 0
        ? 12
        : dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    if (isToday) return 'Today $hour12:$minute $period';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}, $hour12:$minute $period';
  }

  void _selectPreset(int minutes) {
    setState(() {
      _selectedMinutes = minutes;
      _isCustomDateTime = false;
    });
  }

  Future<void> _selectCustomDateTime() async {
    final now = ServerClock.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(minutes: 30)),
      firstDate: now.add(const Duration(minutes: 5)),
      lastDate: now.add(const Duration(days: 30)),
    );
    if (selectedDate == null) return;
    if (!mounted) return;

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(minutes: 30))),
    );
    if (selectedTime == null) return;

    setState(() {
      _customDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );
      _isCustomDateTime = true;
      _customExpanded = true;
    });
  }

  Future<void> _handleAcknowledge({bool startImmediately = false}) async {
    if (_submitting) return;

    final note = _noteController.text.trim();
    final result = AcknowledgeTicketResult(
      mode: _isCustomDateTime ? 'custom' : 'preset',
      minutesFromNow: _isCustomDateTime ? null : _selectedMinutes,
      customDateTime: _customDateTime,
      readyByLabel: _readyByLabel,
      buttonLabel: 'Acknowledge $_buttonTimeLabel',
      startImmediately: startImmediately,
      notes: note.isEmpty ? null : note,
      dueAtEpochMs: _effectiveDueDateTime.millisecondsSinceEpoch,
    );

    final cb = widget.onConfirm;
    if (cb == null) {
      setState(() => _submitting = true);
      if (!mounted) return;
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

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    return PopScope(
      canPop: !_submitting,
      child: Container(
      decoration: CardDecoration.subtle(
        colors: c,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
          _Header(c: c),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SET DUE TIME',
                  style: TypographyManager.textMeta.copyWith(
                    color: c.fgSubtle,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.6,
                  ),
                  itemCount: _presets.length,
                  itemBuilder: (_, i) {
                    final p = _presets[i];
                    final isSelected =
                        !_isCustomDateTime && _selectedMinutes == p.minutes;
                    return _PresetChip(
                      option: p,
                      selected: isSelected,
                      onTap: () => _selectPreset(p.minutes),
                      colors: c,
                    );
                  },
                ),
                const SizedBox(height: 16),
                _CustomDateTimeRow(
                  expanded: _customExpanded,
                  hasValue: _isCustomDateTime && _customDateTime != null,
                  onTap: () {
                    if (!_isCustomDateTime || _customDateTime == null) {
                      _selectCustomDateTime();
                    } else {
                      setState(() => _customExpanded = !_customExpanded);
                    }
                  },
                  colors: c,
                ),
                if (_customExpanded &&
                    _isCustomDateTime &&
                    _customDateTime != null) ...[
                  const SizedBox(height: 12),
                  _DueInfoCard(
                    label: 'Due ${_formatDateTime(_customDateTime!)}',
                    onEdit: _selectCustomDateTime,
                    colors: c,
                  ),
                ],
                const SizedBox(height: 20),
                Text(
                  'Note (optional)',
                  style: TypographyManager.textBodyStrong.copyWith(
                    color: c.fgBase,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _noteController,
                  maxLines: 3,
                  style: TypographyManager.textBody.copyWith(color: c.fgBase),
                  decoration: InputDecoration(
                    hintText: 'Add a note about this ticket...',
                    hintStyle: TypographyManager.textBody.copyWith(
                      color: c.fgMuted,
                    ),
                    filled: true,
                    fillColor: c.bgBase,
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
                      borderSide: BorderSide(color: c.borderInteractive),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _ActionButtons(
              colors: c,
              submitting: _submitting,
              showAcceptAndStart: _isDueToday,
              onAccept: () => _handleAcknowledge(),
              onAcceptAndStart: () =>
                  _handleAcknowledge(startImmediately: true),
              onCancel: () => Navigator.of(context).pop(),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 24),
        ],
      ),
    ),
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }
}

class _PresetOption {
  final int minutes;
  final String label;
  final IconData icon;
  const _PresetOption({
    required this.minutes,
    required this.label,
    required this.icon,
  });
}

class _Header extends StatelessWidget {
  final AppColors c;
  const _Header({required this.c});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Acknowledge Ticket',
              style: TypographyManager.textHeading.copyWith(
                color: c.fgBase,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          GestureDetector(
            onTap: tapSound(() => Navigator.of(context).pop(), SoundCategory.back),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(LucideIcons.x, size: 20, color: c.fgSubtle),
            ),
          ),
        ],
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final _PresetOption option;
  final bool selected;
  final VoidCallback onTap;
  final AppColors colors;
  const _PresetChip({
    required this.option,
    required this.selected,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? colors.tagPurpleBg : colors.bgBase;
    final fg = selected ? colors.tagPurpleText : colors.fgSubtle;
    final border = selected ? colors.tagPurpleBorder : colors.borderBase;
    return InkWell(
      onTap: tapSound(onTap, SoundCategory.preference),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(option.icon, size: 14, color: fg),
            const SizedBox(width: 6),
            Text(
              option.label,
              style: TypographyManager.textLabel.copyWith(
                color: fg,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomDateTimeRow extends StatelessWidget {
  final bool expanded;
  final bool hasValue;
  final VoidCallback onTap;
  final AppColors colors;
  const _CustomDateTimeRow({
    required this.expanded,
    required this.hasValue,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: tapSound(onTap, SoundCategory.preference),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(
              expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
              size: 18,
              color: colors.fgSubtle,
            ),
            const SizedBox(width: 8),
            Text(
              'Set custom date/time',
              style: TypographyManager.textBodyStrong.copyWith(
                color: colors.fgBase,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Action button cluster at the bottom of the acknowledge sheet.
///
/// Two layouts depending on whether the picked due time falls within today:
///
/// * **Today** — `[Accept Ticket | Accept & Start]` row, with a separate
///   full-width `Cancel` outlined button below. Matches the original design.
/// * **Not today** — `[Cancel | Accept Ticket]` single row with leading
///   icons on each button. "Accept & Start" is suppressed because starting
///   work today on something due later is not meaningful.
class _ActionButtons extends StatelessWidget {
  final AppColors colors;
  final bool submitting;
  final bool showAcceptAndStart;
  final VoidCallback onAccept;
  final VoidCallback onAcceptAndStart;
  final VoidCallback onCancel;

  const _ActionButtons({
    required this.colors,
    required this.submitting,
    required this.showAcceptAndStart,
    required this.onAccept,
    required this.onAcceptAndStart,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = colors;

    Widget acceptButton({Widget? icon}) {
      return ElevatedButton(
        onPressed: submitting ? null : tapSound(onAccept),
        style: ElevatedButton.styleFrom(
          backgroundColor: c.buttonInverted,
          foregroundColor: c.fgOnInverted,
          disabledBackgroundColor: c.bgDisabled,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: submitting
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: c.fgOnInverted,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    icon,
                    const SizedBox(width: 8),
                  ],
                  Text(
                    l10n.ticketActionAccept,
                    style: TypographyManager.textBodyStrong.copyWith(
                      color: c.fgOnInverted,
                    ),
                  ),
                ],
              ),
      );
    }

    Widget cancelButton({Widget? icon}) {
      return OutlinedButton(
        onPressed: submitting ? null : tapSound(onCancel, SoundCategory.back),
        style: OutlinedButton.styleFrom(
          foregroundColor: c.fgBase,
          side: BorderSide(color: c.borderBase),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              icon,
              const SizedBox(width: 8),
            ],
            Text(
              l10n.ticketActionCancel,
              style: TypographyManager.textBodyStrong.copyWith(
                color: c.fgBase,
              ),
            ),
          ],
        ),
      );
    }

    if (showAcceptAndStart) {
      // Original layout: Accept + Accept & Start in a row, Cancel below.
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: acceptButton()),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: submitting ? null : tapSound(onAcceptAndStart),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.tagPurpleBg,
                    foregroundColor: c.tagPurpleText,
                    disabledBackgroundColor: c.bgDisabled,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: c.tagPurpleBorder),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                  ),
                  child: Text(
                    l10n.ticketActionAcceptAndStart,
                    style: TypographyManager.textBodyStrong.copyWith(
                      color: c.tagPurpleText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(width: double.infinity, child: cancelButton()),
        ],
      );
    }

    // Compact layout: due is not today → Cancel + Accept in one row, with
    // leading icons.
    return Row(
      children: [
        Expanded(
          child: cancelButton(
            icon: Icon(LucideIcons.x, size: 18, color: c.fgBase),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: acceptButton(
            icon: Icon(LucideIcons.check, size: 18, color: c.fgOnInverted),
          ),
        ),
      ],
    );
  }
}

class _DueInfoCard extends StatelessWidget {
  final String label;
  final VoidCallback onEdit;
  final AppColors colors;
  const _DueInfoCard({
    required this.label,
    required this.onEdit,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: tapSound(onEdit, SoundCategory.preference),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: colors.tagPurpleBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.tagPurpleBorder),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.clock, size: 16, color: colors.tagPurpleText),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TypographyManager.textBodyStrong.copyWith(
                  color: colors.tagPurpleText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
