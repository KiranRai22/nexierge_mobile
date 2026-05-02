import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/color_palette.dart';
import '../../../../core/theme/typography_manager.dart';

/// Result data when acknowledging a ticket with ETA selection
class AcknowledgeTicketResult {
  final String mode; // 'preset', 'custom'
  final int? minutesFromNow;
  final DateTime? customDateTime;
  final String readyByLabel;
  final String buttonLabel;

  const AcknowledgeTicketResult({
    required this.mode,
    this.minutesFromNow,
    this.customDateTime,
    required this.readyByLabel,
    required this.buttonLabel,
  });
}

/// Bottom sheet for acknowledging tickets with ETA selection
class AcknowledgeTicketBottomSheet {
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
}

class _AcknowledgeTicketSheetBody extends StatefulWidget {
  final String ticketCode;
  final String ticketTitle;
  final bool hasGuest;

  const _AcknowledgeTicketSheetBody({
    required this.ticketCode,
    required this.ticketTitle,
    required this.hasGuest,
  });

  @override
  State<_AcknowledgeTicketSheetBody> createState() => _AcknowledgeTicketSheetBodyState();
}

class _AcknowledgeTicketSheetBodyState extends State<_AcknowledgeTicketSheetBody> {
  int _selectedMinutes = 15;
  DateTime? _customDateTime;
  bool _isCustomDateTime = false;
  final TextEditingController _noteController = TextEditingController();
  bool _submitting = false;

  final List<Map<String, dynamic>> _presetOptions = [
    {'minutes': 15, 'label': '+15 min', 'icon': LucideIcons.clock},
    {'minutes': 30, 'label': '+30 min', 'icon': LucideIcons.clock},
    {'minutes': 60, 'label': '+1 hour', 'icon': LucideIcons.clock},
    {'minutes': 180, 'label': '+3 hours', 'icon': LucideIcons.clock},
    {'minutes': 1440, 'label': '+1 day', 'icon': LucideIcons.calendar},
    {'minutes': 4320, 'label': '+3 days', 'icon': LucideIcons.calendar},
  ];

  @override
  void initState() {
    super.initState();
  }

  String get _readyByLabel {
    if (_isCustomDateTime && _customDateTime != null) {
      return 'Ready by ${_formatDateTime(_customDateTime!)}';
    }
    return 'Ready by ${_formatDateTime(DateTime.now().add(Duration(minutes: _selectedMinutes)))}';
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

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final isToday = dateTime.day == now.day && dateTime.month == now.month && dateTime.year == now.year;
    
    final time = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    
    if (isToday) {
      final period = dateTime.hour >= 12 ? 'PM' : 'AM';
      final hour12 = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour == 0 ? 12 : dateTime.hour;
      return 'Today $hour12:${dateTime.minute.toString().padLeft(2, '0')} $period';
    }
    
    return '${dateTime.day}/${dateTime.month} $time';
  }

  void _selectPreset(int minutes) {
    setState(() {
      _selectedMinutes = minutes;
      _isCustomDateTime = false;
      _customDateTime = null;
    });
  }

  Future<void> _selectCustomDateTime() async {
    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(minutes: 30)),
      firstDate: now.add(const Duration(minutes: 5)),
      lastDate: now.add(const Duration(days: 30)),
    );
    
    if (selectedDate == null) return;
    
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(minutes: 30))),
    );
    
    if (selectedTime == null) return;
    
    final finalDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );
    
    setState(() {
      _customDateTime = finalDateTime;
      _isCustomDateTime = true;
    });
  }

  Future<void> _handleAcknowledge() async {
    if (_submitting) return;

    setState(() => _submitting = true);

    // Simulate network call
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    final result = AcknowledgeTicketResult(
      mode: _isCustomDateTime ? 'custom' : 'preset',
      minutesFromNow: _isCustomDateTime ? null : _selectedMinutes,
      customDateTime: _customDateTime,
      readyByLabel: _readyByLabel,
      buttonLabel: 'Acknowledge $_buttonTimeLabel',
    );

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
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
              color: ColorPalette.textSecondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Acknowledge Ticket',
              style: TypographyManager.headlineSmall.copyWith(
                fontWeight: FontWeight.w600,
                color: ColorPalette.textPrimary,
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Subtitle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              '${widget.ticketCode} · ${widget.ticketTitle}',
              style: TypographyManager.bodyMedium.copyWith(
                color: ColorPalette.textSecondary,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Time selection options
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Set due time',
                  style: TypographyManager.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: ColorPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Preset options grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.5,
                  ),
                  itemCount: _presetOptions.length,
                  itemBuilder: (context, index) {
                    final option = _presetOptions[index];
                    final isSelected = !_isCustomDateTime && _selectedMinutes == option['minutes'];
                    
                    return GestureDetector(
                      onTap: () => _selectPreset(option['minutes']),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? ColorPalette.chipCatalogFg : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? ColorPalette.chipCatalogFg : ColorPalette.textSecondary.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              option['icon'],
                              size: 16,
                              color: isSelected ? Colors.white : ColorPalette.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              option['label'],
                              style: TypographyManager.bodySmall.copyWith(
                                color: isSelected ? Colors.white : ColorPalette.textSecondary,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Custom date/time option
                GestureDetector(
                  onTap: _selectCustomDateTime,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _isCustomDateTime ? ColorPalette.chipCatalogFg.withOpacity(0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isCustomDateTime ? ColorPalette.chipCatalogFg : ColorPalette.textSecondary.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              LucideIcons.calendar,
                              size: 20,
                              color: _isCustomDateTime ? ColorPalette.chipCatalogFg : ColorPalette.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Set custom date/time',
                              style: TypographyManager.bodyMedium.copyWith(
                                color: _isCustomDateTime ? ColorPalette.chipCatalogFg : ColorPalette.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              LucideIcons.chevronRight,
                              size: 16,
                              color: _isCustomDateTime ? ColorPalette.chipCatalogFg : ColorPalette.textSecondary,
                            ),
                          ],
                        ),
                        if (_customDateTime != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _formatDateTime(_customDateTime!),
                            style: TypographyManager.bodySmall.copyWith(
                              color: ColorPalette.chipCatalogFg,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Note field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Note (optional)',
                hintStyle: TypographyManager.bodyMedium.copyWith(
                  color: ColorPalette.textSecondary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: ColorPalette.textSecondary.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: ColorPalette.chipCatalogFg,
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                // Cancel button
                Expanded(
                  child: OutlinedButton(
                    onPressed: _submitting ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: ColorPalette.textSecondary.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'Cancel',
                      style: TypographyManager.labelLarge.copyWith(
                        color: ColorPalette.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Acknowledge button
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _handleAcknowledge,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorPalette.chipCatalogFg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Acknowledge',
                            style: TypographyManager.labelLarge.copyWith(
                              color: Colors.white,
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
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }
}
