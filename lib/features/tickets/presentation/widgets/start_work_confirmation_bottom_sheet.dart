import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/color_palette.dart';
import '../../../../core/theme/typography_manager.dart';

class StartWorkConfirmationBottomSheet extends StatelessWidget {
  const StartWorkConfirmationBottomSheet({
    super.key,
    required this.onCancel,
    required this.onStartWork,
  });

  final VoidCallback onCancel;
  final VoidCallback onStartWork;

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
              'Start working on this ticket?',
              style: TypographyManager.headlineSmall.copyWith(
                fontWeight: FontWeight.w600,
                color: ColorPalette.textPrimary,
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'This will notify that the team has started preparing or resolving the request.',
              style: TypographyManager.bodyMedium.copyWith(
                color: ColorPalette.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Countdown section
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ColorPalette.chipCatalogFg.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ColorPalette.chipCatalogFg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    LucideIcons.play,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Countdown will start now',
                        style: TypographyManager.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: ColorPalette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'The preparation timer begins the moment you confirm.',
                        style: TypographyManager.bodySmall.copyWith(
                          color: ColorPalette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                // Cancel button
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onCancel();
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: ColorPalette.chipCatalogFg),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'Cancel',
                      style: TypographyManager.labelLarge.copyWith(
                        color: ColorPalette.chipCatalogFg,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Start Work button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onStartWork();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorPalette.chipCatalogFg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'Start Work',
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
}

/// Utility function to show the start work confirmation bottom sheet
void showStartWorkConfirmation({
  required BuildContext context,
  required VoidCallback onCancel,
  required VoidCallback onStartWork,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => StartWorkConfirmationBottomSheet(
      onCancel: onCancel,
      onStartWork: onStartWork,
    ),
  );
}
