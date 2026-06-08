import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/services/sound_manager.dart';
import '../../../../core/theme/card_theme.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/typography_manager.dart';
import '../providers/profile_section_expansion_provider.dart';

/// Section composed of an ALL-CAPS header and a card of label/value rows
/// separated by hairline dividers. Used for "Account information" and
/// "Work information" on the profile screen. Shows summary when collapsed.
///
/// [sectionId] keys this section's expand/collapse state in the
/// [profileSectionExpansionProvider] — keep it stable across rebuilds.
class ProfileInfoSection extends ConsumerWidget {
  final String sectionId;
  final String title;
  final List<ProfileInfoRow> rows;
  final String? summary;

  const ProfileInfoSection({
    super.key,
    required this.sectionId,
    required this.title,
    required this.rows,
    this.summary,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.themeColors;
    final isExpanded = ref.watch(profileSectionExpandedProvider(sectionId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: TypographyManager.kpiLabel.copyWith(
                    color: c.fgSubtle,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              GestureDetector(
                onTap: tapSound(() => ref
                    .read(profileSectionExpansionProvider.notifier)
                    .toggle(sectionId), SoundCategory.card),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      LucideIcons.chevronDown,
                      size: 20,
                      color: c.fgSubtle,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isExpanded && summary != null)
          _SummaryCard(summary: summary!)
        else
          Container(
            decoration: CardDecoration.subtle(
              colors: c,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                if (rows.isNotEmpty) rows.first,
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: isExpanded && rows.length > 1
                      ? Column(
                          children: [
                            for (var i = 1; i < rows.length; i++) ...[
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
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String summary;
  const _SummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    return Container(
      decoration: CardDecoration.subtle(
        colors: c,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              summary,
              style: TypographyManager.bodyMedium.copyWith(color: c.fgBase),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
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
    final c = context.themeColors;
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
