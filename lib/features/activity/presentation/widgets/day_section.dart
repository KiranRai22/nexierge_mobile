import 'package:flutter/material.dart';

import '../../../../core/theme/typography_manager.dart';
import '../../../../core/theme/app_colors.dart';

/// Sticky-style day header used in the activity feed (TODAY · YESTERDAY ·
/// OLDER). Implemented as a list item — sliver-pinning is overkill for the
/// current shape of the data.
class DaySection extends StatelessWidget {
  final String label;
  const DaySection({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: context.appColors.bgBase,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(label, style: TypographyManager.sectionOverline),
    );
  }
}
