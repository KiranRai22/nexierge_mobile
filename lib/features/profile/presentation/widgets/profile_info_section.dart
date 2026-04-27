import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/typography_manager.dart';

/// Section composed of an ALL-CAPS header and a card of label/value rows
/// separated by hairline dividers. Used for "Account information" and
/// "Work information" on the profile screen.
class ProfileInfoSection extends StatelessWidget {
  final String title;
  final List<ProfileInfoRow> rows;

  const ProfileInfoSection({
    super.key,
    required this.title,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Text(
            title.toUpperCase(),
            style: TypographyManager.kpiLabel.copyWith(
              color: c.fgSubtle,
              letterSpacing: 0.6,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: c.bgBase,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.borderBase),
          ),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: c.borderBase,
                    indent: 16,
                    endIndent: 16,
                  ),
                rows[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// One label/value row inside a [ProfileInfoSection]. The value sits flush
/// to the right and ellipsises so long values (long department lists,
/// long emails) don't push the layout out of bounds.
class ProfileInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const ProfileInfoRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Text(
            label,
            style: TypographyManager.bodyMedium.copyWith(color: c.fgSubtle),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TypographyManager.bodyMedium.copyWith(
                color: c.fgBase,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
