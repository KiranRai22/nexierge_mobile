import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/unified_theme_manager.dart';
import '../../../../core/theme/typography_manager.dart';

/// Result data when accepting a ticket with ETA selection
class AcceptETAResult {
  final String mode; // 'preset', 'later', 'custom'
  final int? minutesFromNow;
  final String? customTime;
  final String readyByLabel;
  final String buttonLabel;

  const AcceptETAResult({
    required this.mode,
    this.minutesFromNow,
    this.customTime,
    required this.readyByLabel,
    required this.buttonLabel,
  });
}

/// Type of ticket for ETA defaults
enum TicketAcceptType { universal, paid, manual }

/// Bottom sheet for accepting tickets with ETA selection
/// Matches TSX AcceptSheet design with time chips grid
class AcceptSheet {
  static Future<AcceptETAResult?> show({
    required BuildContext context,
    required String ticketCode,
    required String ticketTitle,
    required TicketAcceptType ticketType,
    required bool hasGuest,
  }) {
    final c = context.themeColors;
    return showModalBottomSheet<AcceptETAResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.bgSubtle,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AcceptSheetBody(
        ticketCode: ticketCode,
        ticketTitle: ticketTitle,
        ticketType: ticketType,
        hasGuest: hasGuest,
      ),
    );
  }
}

class _AcceptSheetBody extends ConsumerStatefulWidget {
  final String ticketCode;
  final String ticketTitle;
  final TicketAcceptType ticketType;
  final bool hasGuest;

  const _AcceptSheetBody({
    required this.ticketCode,
    required this.ticketTitle,
    required this.ticketType,
    required this.hasGuest,
  });

  @override
  ConsumerState<_AcceptSheetBody> createState() => _AcceptSheetBodyState();
}

class _AcceptSheetBodyState extends ConsumerState<_AcceptSheetBody> {
  late int _selectedMinutes;
  bool _isLater = false;
  String? _customTime;
  bool _submitting = false;

  int get _defaultMinutes {
    switch (widget.ticketType) {
      case TicketAcceptType.universal:
        return 15;
      case TicketAcceptType.paid:
        return 30;
      case TicketAcceptType.manual:
        return 60;
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedMinutes = _defaultMinutes;
  }

  String get _readyByLabel {
    if (_isLater) return 'Ready later today';
    if (_customTime != null) {
      return 'Ready by ${_formatTime12(_customTime!)}';
    }
    return 'Ready by ${_computeReadyBy(_selectedMinutes)}';
  }

  String get _buttonTimeLabel {
    if (_isLater) return '· Later today';
    if (_customTime != null) {
      return '· at ${_formatTime12(_customTime!)}';
    }
    if (_selectedMinutes >= 60) {
      final hours = _selectedMinutes ~/ 60;
      return '· $hours hour${hours > 1 ? 's' : ''}';
    }
    return '· $_selectedMinutes min';
  }

  String _computeReadyBy(int minutes) {
    final now = DateTime.now();
    final then = now.add(Duration(minutes: minutes));
    return _formatTime12('${then.hour}:${then.minute}');
  }

  String _formatTime12(String time) {
    final parts = time.split(':');
    final h24 = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    final period = h24 >= 12 ? 'PM' : 'AM';
    final h12 = h24 > 12 ? h24 - 12 : h24 == 0 ? 12 : h24;
    return '$h12:${m.toString().padLeft(2, '0')} $period';
  }

  void _selectPreset(int minutes) {
    setState(() {
      _selectedMinutes = minutes;
      _isLater = false;
      _customTime = null;
    });
  }

  void _selectLater() {
    setState(() {
      _isLater = true;
      _customTime = null;
    });
  }

  Future<void> _handleConfirm() async {
    if (_submitting) return;

    setState(() => _submitting = true);

    // Simulate network
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    final result = AcceptETAResult(
      mode: _isLater
          ? 'later'
          : _customTime != null
              ? 'custom'
              : 'preset',
      minutesFromNow: _isLater || _customTime != null ? null : _selectedMinutes,
      customTime: _customTime,
      readyByLabel: _readyByLabel,
      buttonLabel: 'Accept $_buttonTimeLabel',
    );

    Navigator.of(context).pop(result);
  }

  bool _isPresetSelected(int minutes) {
    return !_isLater && _customTime == null && _selectedMinutes == minutes;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: c.borderBase,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Title
            Text(
              'When will this be done?',
              style: TypographyManager.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: c.fgBase,
              ),
            ),
            const SizedBox(height: 4),
            // Subtitle
            Text(
              'Accepting ${widget.ticketCode} · ${widget.ticketTitle}',
              style: TypographyManager.bodySmall.copyWith(color: c.fgMuted),
            ),
            const SizedBox(height: 16),
            // Chip grid - 3 columns
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _TimeChip(
                  primary: '10',
                  secondary: 'minutes',
                  selected: _isPresetSelected(10),
                  onTap: () => _selectPreset(10),
                ),
                _TimeChip(
                  primary: '15',
                  secondary: 'minutes',
                  selected: _isPresetSelected(15),
                  onTap: () => _selectPreset(15),
                ),
                _TimeChip(
                  primary: '30',
                  secondary: 'minutes',
                  selected: _isPresetSelected(30),
                  onTap: () => _selectPreset(30),
                ),
                _TimeChip(
                  primary: '1',
                  secondary: 'hour',
                  selected: _isPresetSelected(60),
                  onTap: () => _selectPreset(60),
                ),
                _TimeChip(
                  primary: 'Later',
                  secondary: 'today',
                  selected: _isLater,
                  onTap: _selectLater,
                ),
                _CustomTimeChip(
                  onTimeSelected: (time) {
                    setState(() {
                      _customTime = time;
                      _isLater = false;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Notification preview
            _NotificationPreview(
              label: widget.hasGuest
                  ? 'Guest will be notified'
                  : 'Ticket owner will be notified',
              value: _readyByLabel,
            ),
            const SizedBox(height: 16),
            // Confirm button
            _ConfirmButton(
              label: 'Accept',
              timeLabel: _buttonTimeLabel,
              onPressed: _handleConfirm,
              loading: _submitting,
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  final String primary;
  final String secondary;
  final bool selected;
  final VoidCallback onTap;

  const _TimeChip({
    required this.primary,
    required this.secondary,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    final width = (MediaQuery.of(context).size.width - 52) / 3;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? c.tagPurpleIcon : c.bgBase,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? c.tagPurpleIcon : c.borderBase,
          ),
        ),
        child: Column(
          children: [
            Text(
              primary,
              style: TypographyManager.titleMedium.copyWith(
                color: selected ? Colors.white : c.fgBase,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              secondary,
              style: TypographyManager.bodySmall.copyWith(
                color: selected ? Colors.white.withValues(alpha: 0.8) : c.fgMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomTimeChip extends StatefulWidget {
  final ValueChanged<String> onTimeSelected;

  const _CustomTimeChip({required this.onTimeSelected});

  @override
  State<_CustomTimeChip> createState() => _CustomTimeChipState();
}

class _CustomTimeChipState extends State<_CustomTimeChip> {
  TimeOfDay? _selectedTime;

  Future<void> _pickTime() async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: now,
      builder: (context, child) {
        final c = context.themeColors;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: c.tagPurpleIcon,
              surface: c.bgBase,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final nowMinutes = now.hour * 60 + now.minute;
      final pickedMinutes = picked.hour * 60 + picked.minute;

      if (pickedMinutes <= nowMinutes) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please pick a time in the future')),
          );
        }
        return;
      }

      setState(() => _selectedTime = picked);
      widget.onTimeSelected('${picked.hour}:${picked.minute}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    final width = (MediaQuery.of(context).size.width - 52) / 3;
    final hasSelection = _selectedTime != null;

    return GestureDetector(
      onTap: _pickTime,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: hasSelection ? c.tagPurpleIcon : c.bgBase,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasSelection ? c.tagPurpleIcon : c.borderBase,
          ),
        ),
        child: Column(
          children: [
            Icon(
              LucideIcons.clock,
              size: 20,
              color: hasSelection ? Colors.white : c.fgMuted,
            ),
            const SizedBox(height: 4),
            Text(
              hasSelection
                  ? '${_selectedTime!.hour}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                  : 'Custom',
              style: TypographyManager.bodySmall.copyWith(
                color: hasSelection ? Colors.white.withValues(alpha: 0.8) : c.fgMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationPreview extends StatelessWidget {
  final String label;
  final String value;

  const _NotificationPreview({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.bgBase,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.borderBase),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.clock, size: 16, color: c.fgMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TypographyManager.bodySmall.copyWith(
                    color: c.fgMuted,
                  ),
                ),
                Text(
                  value,
                  style: TypographyManager.bodyMedium.copyWith(
                    color: c.fgBase,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  final String label;
  final String timeLabel;
  final VoidCallback onPressed;
  final bool loading;

  const _ConfirmButton({
    required this.label,
    required this.timeLabel,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;

    return GestureDetector(
      onTap: loading ? null : onPressed,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          color: c.tagPurpleIcon,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: c.tagPurpleIcon.withValues(alpha: .35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: c.tagPurpleIcon.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    c.fgOnColor,
                  ),
                ),
              )
            else
              Icon(LucideIcons.check, size: 18, color: c.fgOnColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: TypographyManager.bodyLarge.copyWith(
                color: c.fgOnColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              timeLabel,
              style: TypographyManager.bodyLarge.copyWith(
                color: c.fgOnColor.withValues(alpha: 0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
