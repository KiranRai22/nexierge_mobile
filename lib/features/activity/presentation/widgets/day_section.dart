import 'package:flutter/material.dart';

import '../../../../core/theme/color_palette.dart';
import '../../../../core/theme/typography_manager.dart';

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
      color: ColorPalette.opsSurface,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(label, style: TypographyManager.sectionOverline),
    );
  }
}
