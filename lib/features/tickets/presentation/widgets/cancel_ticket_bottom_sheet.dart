import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/card_theme.dart';
import '../../../../core/theme/unified_theme_manager.dart';
import '../../../../core/theme/typography_manager.dart';

class CancelTicketBottomSheet extends StatefulWidget {
  const CancelTicketBottomSheet._();

  /// Returns the cancellation reason string, or null if dismissed.
  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CancelTicketBottomSheet._(),
    );
  }

  @override
  State<CancelTicketBottomSheet> createState() =>
      _CancelTicketBottomSheetState();
}

class _CancelTicketBottomSheetState extends State<CancelTicketBottomSheet> {
  final _reasonCtl = TextEditingController();

  @override
  void dispose() {
    _reasonCtl.dispose();
    super.dispose();
  }

  bool get _canConfirm => _reasonCtl.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return Container(
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
                  'Cancel ticket',
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
          const SizedBox(height: 8),
          Text(
            'Please provide a reason for cancelling this ticket.',
            style: TypographyManager.bodySmall.copyWith(color: c.fgMuted),
          ),
          const SizedBox(height: 16),
          // Reason field (required)
          TextField(
            controller: _reasonCtl,
            maxLines: 4,
            onChanged: (_) => setState(() {}),
            style: TypographyManager.bodyMedium.copyWith(color: c.fgBase),
            decoration: InputDecoration(
              hintText: 'Cancellation reason (required)...',
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
                borderSide: BorderSide(color: c.tagRedIcon),
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
                child: ElevatedButton.icon(
                  onPressed: _canConfirm
                      ? () => Navigator.of(context).pop(_reasonCtl.text.trim())
                      : null,
                  icon: Icon(
                    LucideIcons.circleX,
                    size: 18,
                    color: _canConfirm ? Colors.white : c.fgMuted,
                  ),
                  label: const Text('Confirm Cancel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.tagRedIcon,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: c.bgDisabled,
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
    );
  }
}
