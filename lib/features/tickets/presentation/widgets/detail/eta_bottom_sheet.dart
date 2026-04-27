import 'package:flutter/material.dart';

import '../../../../../core/i18n/l10n_extension.dart';
import '../../../../../core/theme/color_palette.dart';
import '../../../../../core/theme/typography_manager.dart';
import '../../../../../core/utils/date_utils.dart';
import '../../../../../l10n/generated/app_localizations.dart';

/// Result returned to the caller — the chosen ETA duration.
typedef EtaPick = Duration;

/// Bottom sheet for "Accept & set ETA". Returns a [Duration] or null if
/// dismissed.
class EtaBottomSheet {
  static Future<EtaPick?> show(
    BuildContext context, {
    required String ticketCode,
  }) {
    return showModalBottomSheet<EtaPick>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ColorPalette.opsSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EtaSheet(ticketCode: ticketCode),
    );
  }
}

class _EtaSheet extends StatefulWidget {
  final String ticketCode;
  const _EtaSheet({required this.ticketCode});

  @override
  State<_EtaSheet> createState() => _EtaSheetState();
}

class _EtaSheetState extends State<_EtaSheet> {
  Duration _picked = const Duration(minutes: 15);

  static const List<int> _optionMinutes = [10, 15, 30, 60];

  String _optionLabel(AppLocalizations s, int minutes) {
    switch (minutes) {
      case 10:
        return s.eta10;
      case 15:
        return s.eta15;
      case 30:
        return s.eta30;
      case 60:
        return s.eta60;
      default:
        return s.etaConfirmMinutes(minutes);
    }
  }

  String _readyByLine(AppLocalizations s) {
    final ready = DateTime.now().add(_picked);
    return s.etaReadyBy(AppDateUtils.clock(ready));
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
            _Header(ticketCode: widget.ticketCode),
            const SizedBox(height: 12),
            _OptionsGrid(
              options: [
                for (final m in _optionMinutes)
                  _Option(label: _optionLabel(s, m), minutes: m),
              ],
              selected: _picked,
              onPick: (d) => setState(() => _picked = d),
            ),
            const SizedBox(height: 12),
            _NotifyHint(readyBy: _readyByLine(s)),
            const SizedBox(height: 12),
            _ConfirmButton(
              picked: _picked,
              onTap: () => Navigator.of(context).pop(_picked),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _Option {
  final String label;
  final int minutes;
  const _Option({required this.label, required this.minutes});
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
  final String ticketCode;
  const _Header({required this.ticketCode});
  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.etaTitle,
            style: TypographyManager.titleLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            s.etaSubtitle(ticketCode),
            style: TypographyManager.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _OptionsGrid extends StatelessWidget {
  final List<_Option> options;
  final Duration selected;
  final ValueChanged<Duration> onPick;
  const _OptionsGrid({
    required this.options,
    required this.selected,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final o in options)
            _Pill(
              label: o.label,
              selected: o.minutes == selected.inMinutes,
              onTap: () => onPick(Duration(minutes: o.minutes)),
            ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? ColorPalette.opsPurpleTint
                : ColorPalette.opsSurfaceSubtle,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? ColorPalette.opsPurple
                  : ColorPalette.opsBorder,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Text(
            label,
            style: TypographyManager.titleSmall.copyWith(
              fontWeight: FontWeight.w600,
              color: selected
                  ? ColorPalette.opsPurpleDark
                  : ColorPalette.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _NotifyHint extends StatelessWidget {
  final String readyBy;
  const _NotifyHint({required this.readyBy});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(
            Icons.notifications_active_outlined,
            size: 16,
            color: ColorPalette.opsPurple,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '${context.l10n.etaGuestNotified}  ·  $readyBy',
              style: TypographyManager.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  final Duration picked;
  final VoidCallback onTap;
  const _ConfirmButton({required this.picked, required this.onTap});

  String _label(AppLocalizations s) {
    if (picked.inMinutes < 60) {
      return s.etaConfirmMinutes(picked.inMinutes);
    }
    final h = picked.inMinutes ~/ 60;
    return s.etaConfirmHours(h);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorPalette.opsPurple,
            foregroundColor: ColorPalette.white,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: TypographyManager.titleSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: ColorPalette.white,
            ),
          ),
          child: Text(_label(context.l10n)),
        ),
      ),
    );
  }
}
