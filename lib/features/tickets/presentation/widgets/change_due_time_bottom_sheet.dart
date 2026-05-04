import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/unified_theme_manager.dart';
import '../../../../core/theme/typography_manager.dart';

class ChangeDueResult {
  final int newDueAt;
  final String reason;
  const ChangeDueResult({required this.newDueAt, required this.reason});
}

class ChangeDueTimeBottomSheet extends StatefulWidget {
  const ChangeDueTimeBottomSheet._();

  static Future<ChangeDueResult?> show(BuildContext context) {
    return showModalBottomSheet<ChangeDueResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ChangeDueTimeBottomSheet._(),
    );
  }

  @override
  State<ChangeDueTimeBottomSheet> createState() =>
      _ChangeDueTimeBottomSheetState();
}

class _ChangeDueTimeBottomSheetState extends State<ChangeDueTimeBottomSheet> {
  static const _chips = [
    (label: '+15 min', minutes: 15),
    (label: '+30 min', minutes: 30),
    (label: '+1 hour', minutes: 60),
    (label: '+3 hours', minutes: 180),
    (label: '+1 day', minutes: 1440),
    (label: '+3 days', minutes: 4320),
  ];

  int? _selectedMinutes;
  DateTime? _customDue;
  final _reasonCtl = TextEditingController();

  @override
  void dispose() {
    _reasonCtl.dispose();
    super.dispose();
  }

  DateTime get _resolvedDue {
    if (_customDue != null) return _customDue!;
    if (_selectedMinutes != null) {
      return DateTime.now().add(Duration(minutes: _selectedMinutes!));
    }
    return DateTime.now();
  }

  bool get _canSave =>
      (_selectedMinutes != null || _customDue != null) &&
      _reasonCtl.text.trim().isNotEmpty;

  String _formatDue(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = h >= 12 ? 'PM' : 'AM';
    final hour12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}, $hour12:$m $ampm';
  }

  Future<void> _pickCustom() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null || !mounted) return;
    setState(() {
      _customDue = DateTime(
        date.year, date.month, date.day, time.hour, time.minute,
      );
      _selectedMinutes = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return Container(
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
                  'Change Due Time',
                  style: TypographyManager.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: c.fgBase,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(LucideIcons.x, size: 20, color: c.fgMuted),
                onPressed: () => Navigator.of(context).pop(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'SET DUE TIME',
            style: TypographyManager.labelSmall.copyWith(
              color: c.fgMuted,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          // Chips grid: 3 per row
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _chips.map((chip) {
              final selected = _selectedMinutes == chip.minutes;
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedMinutes = chip.minutes;
                  _customDue = null;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? c.tagPurpleBg : c.bgSubtle,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected ? c.tagPurpleIcon : c.borderBase,
                      width: selected ? 1.4 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.clock,
                        size: 13,
                        color: selected ? c.tagPurpleIcon : c.fgMuted,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        chip.label,
                        style: TypographyManager.labelSmall.copyWith(
                          color: selected ? c.tagPurpleText : c.fgBase,
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
            onTap: _pickCustom,
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: c.tagPurpleBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: c.tagPurpleIcon),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.clock, size: 14, color: c.tagPurpleIcon),
                  const SizedBox(width: 8),
                  Text(
                    'Due ${_formatDue(_resolvedDue)}',
                    style: TypographyManager.bodySmall.copyWith(
                      color: c.tagPurpleText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          // Reason field (required)
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
              hintStyle: TypographyManager.bodyMedium.copyWith(color: c.fgMuted),
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
                  onPressed: () => Navigator.of(context).pop(),
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
                  onPressed: _canSave
                      ? () => Navigator.of(context).pop(
                            ChangeDueResult(
                              newDueAt:
                                  _resolvedDue.millisecondsSinceEpoch,
                              reason: _reasonCtl.text.trim(),
                            ),
                          )
                      : null,
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
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
