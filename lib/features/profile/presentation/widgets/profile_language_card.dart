import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/app_locale.dart';
import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/i18n/locale_controller.dart';
import '../../../../core/theme/card_theme.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/theme/unified_theme_manager.dart';
import '../../../../core/theme/typography_manager.dart';

/// Settings card with the language title/subtitle on the left and a binary
/// EN/ES segmented control on the right. The segmented control writes
/// through `localeControllerProvider` so the change is persisted and
/// rebroadcast to the rest of the app immediately.
class ProfileLanguageCard extends ConsumerStatefulWidget {
  const ProfileLanguageCard({super.key});

  @override
  ConsumerState<ProfileLanguageCard> createState() =>
      _ProfileLanguageCardState();
}

class _ProfileLanguageCardState extends ConsumerState<ProfileLanguageCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.value = 1.0; // Start expanded
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  AppLocale _resolveSelected(BuildContext context, AppLocale current) {
    if (current == AppLocale.english) return AppLocale.english;
    if (current == AppLocale.spanish) return AppLocale.spanish;
    // System: pick whichever side reflects what the user is actually seeing.
    final code = Localizations.localeOf(context).languageCode;
    return code == 'es' ? AppLocale.spanish : AppLocale.english;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final c = context.themeColors;
    final current =
        ref.watch(localeControllerProvider).valueOrNull ?? AppLocale.system;
    final selected = _resolveSelected(context, current);
    final languageCode = selected == AppLocale.spanish ? 'ES' : 'EN';

    return Container(
      decoration: CardDecoration.standard(
        colors: c,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Header with collapse button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.profileLanguageTitle,
                        style: TypographyManager.bodyMedium.copyWith(
                          color: c.fgBase,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_isExpanded) ...[
                        const SizedBox(height: 2),
                        Text(
                          s.profileLanguageSubtitle,
                          style: TypographyManager.bodySmall.copyWith(
                            color: c.fgSubtle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!_isExpanded)
                  Text(
                    languageCode,
                    style: TypographyManager.bodyMedium.copyWith(
                      color: c.fgBase,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _toggle,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: AnimatedIcon(
                      icon: AnimatedIcons.menu_close,
                      progress: _animation,
                      size: 20,
                      color: c.fgSubtle,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Animated content
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _isExpanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: _LanguageSegmented(
                      selected: selected,
                      onChanged: (next) =>
                          ref.read(localeControllerProvider.notifier).set(next),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _LanguageSegmented extends StatelessWidget {
  final AppLocale selected;
  final ValueChanged<AppLocale> onChanged;

  const _LanguageSegmented({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: c.tagNeutralBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SegmentChip(
            label: 'EN',
            isSelected: selected == AppLocale.english,
            onTap: () => onChanged(AppLocale.english),
          ),
          _SegmentChip(
            label: 'ES',
            isSelected: selected == AppLocale.spanish,
            onTap: () => onChanged(AppLocale.spanish),
          ),
        ],
      ),
    );
  }
}

class _SegmentChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SegmentChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    return Material(
      // Brand purple selected state — intentionally NOT theme-aware.
      color: isSelected ? ColorPalette.opsPurple : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: TypographyManager.labelLarge.copyWith(
              color: isSelected ? Colors.white : c.fgSubtle,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ),
    );
  }
}
