import 'package:flutter/material.dart';

import '../../../../../core/i18n/l10n_extension.dart';
import '../../../../../core/theme/card_theme.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/typography_manager.dart';

/// Yellow callout used for the guest's freeform note. Stripe + sticky-note
/// affordance per the prototype.
class GuestNoteCallout extends StatelessWidget {
  final String note;
  const GuestNoteCallout({super.key, required this.note});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: CardDecoration.standard(
        colors: context.themeColors,
        borderRadius: BorderRadius.circular(12),
        backgroundColor: context.appColors.noteCalloutBg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.sticky_note_2_outlined,
                size: 16,
                color: context.appColors.noteCalloutFg,
              ),
              const SizedBox(width: 6),
              Text(
                context.l10n.detailGuestNoteLabel,
                style: TypographyManager.kpiLabel.copyWith(
                  color: context.appColors.noteCalloutFg,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            note,
            style: TypographyManager.bodyMedium.copyWith(
              color: context.appColors.noteCalloutFg,
            ),
          ),
        ],
      ),
    );
  }
}
