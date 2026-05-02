import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/color_palette.dart';
import '../theme/typography_manager.dart';
import '../../shared/widgets/app_toast.dart';
import 'app_locale.dart';
import 'l10n_extension.dart';
import 'locale_controller.dart';

/// Modal bottom sheet for choosing the app language. Mirrors the layout of
/// `FilterDepartmentSheet` (handle on top, header w/ subtitle, divider,
/// scrolling list of options, divider, footer with Cancel + Apply).
///
/// Differences vs filter sheet:
///   - Single-select (radio behavior) instead of multi-select.
///   - Each row shows the localized label on the left and the native name on
///     the right, so a Spanish speaker can find "Español" even when the app
///     is currently in English.
///   - On Apply we delegate to [LocaleController.set] which persists & swaps
///     the active MaterialApp locale.
class LanguagePickerSheet {
  const LanguagePickerSheet._();

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ColorPalette.opsSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _LanguageSheetBody(),
    );
  }
}

class _LanguageSheetBody extends ConsumerStatefulWidget {
  const _LanguageSheetBody();

  @override
  ConsumerState<_LanguageSheetBody> createState() => _LanguageSheetBodyState();
}

class _LanguageSheetBodyState extends ConsumerState<_LanguageSheetBody> {
  late AppLocale _draft;

  @override
  void initState() {
    super.initState();
    _draft = ref.read(localeControllerProvider).valueOrNull ?? AppLocale.system;
  }

  void _select(AppLocale locale) {
    if (_draft == locale) return;
    setState(() => _draft = locale);
  }

  Future<void> _apply() async {
    final notifier = ref.read(localeControllerProvider.notifier);
    final toastText = context.l10n.languageChangedToast;
    final navigator = Navigator.of(context);

    await notifier.set(_draft);
    if (!mounted) return;
    navigator.pop();
    context.showInfo(toastText);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _Handle(),
            _Header(title: s.languageTitle, subtitle: s.languageSubtitle),
            const Divider(height: 1, color: ColorPalette.opsDividerSubtle),
            _LocaleList(selected: _draft, onSelect: _select),
            const Divider(height: 1, color: ColorPalette.opsDividerSubtle),
            _Footer(
              onCancel: () => Navigator.of(context).pop(),
              onApply: _apply,
            ),
          ],
        ),
      ),
    );
  }
}

class _Handle extends StatelessWidget {
  const _Handle();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: ColorPalette.opsBorder,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final String subtitle;
  const _Header({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TypographyManager.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: TypographyManager.bodySmall),
        ],
      ),
    );
  }
}

class _LocaleList extends StatelessWidget {
  final AppLocale selected;
  final ValueChanged<AppLocale> onSelect;
  const _LocaleList({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: AppLocale.values.length,
      itemBuilder: (context, i) {
        final locale = AppLocale.values[i];
        final isOn = selected == locale;
        return InkWell(
          onTap: () => onSelect(locale),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  isOn
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: isOn
                      ? ColorPalette.opsPurple
                      : ColorPalette.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    locale.label(s),
                    style: TypographyManager.bodyMedium,
                  ),
                ),
                if (locale != AppLocale.system)
                  Text(
                    locale.nativeName(s),
                    style: TypographyManager.bodySmall.copyWith(
                      color: ColorPalette.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Footer extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onApply;
  const _Footer({required this.onCancel, required this.onApply});

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        children: [
          TextButton(
            onPressed: onCancel,
            style: TextButton.styleFrom(
              foregroundColor: ColorPalette.textSecondary,
            ),
            child: Text(s.cancel),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: onApply,
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorPalette.opsPurple,
              foregroundColor: ColorPalette.white,
              minimumSize: const Size(96, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(s.filterApply),
          ),
        ],
      ),
    );
  }
}
