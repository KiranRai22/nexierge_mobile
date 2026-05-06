import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/unified_theme_manager.dart';
import '../../../../core/theme/typography_manager.dart';

/// Section composed of an ALL-CAPS header and a card of label/value rows
/// separated by hairline dividers. Used for "Account information" and
/// "Work information" on the profile screen.
class ProfileInfoSection extends StatefulWidget {
  final String title;
  final List<ProfileInfoRow> rows;

  const ProfileInfoSection({
    super.key,
    required this.title,
    required this.rows,
  });

  @override
  State<ProfileInfoSection> createState() => _ProfileInfoSectionState();
}

class _ProfileInfoSectionState extends State<ProfileInfoSection> {
  bool _isExpanded = true;

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.title.toUpperCase(),
                  style: TypographyManager.kpiLabel.copyWith(
                    color: c.fgSubtle,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _toggle,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
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
        Container(
          decoration: BoxDecoration(
            color: c.bgBase,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.borderBase),
          ),
          child: Column(
            children: [
              // Always show first row
              if (widget.rows.isNotEmpty) widget.rows.first,
              // Animated remaining rows
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: _isExpanded && widget.rows.length > 1
                    ? Column(
                        children: [
                          for (var i = 1; i < widget.rows.length; i++) ...[
                            Divider(
                              height: 1,
                              thickness: 1,
                              color: c.borderBase,
                              indent: 16,
                              endIndent: 16,
                            ),
                            widget.rows[i],
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
