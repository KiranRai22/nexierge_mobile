import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/i18n/l10n_extension.dart';
import '../../../../../core/theme/color_palette.dart';
import '../../../../../core/theme/typography_manager.dart';
import '../../../domain/entities/checked_in_guest_stay.dart';
import '../../providers/checked_in_guest_stays_provider.dart';

/// Bottom sheet for selecting a room.
///
/// Sourced from `checkedInGuestStaysProvider` — only rooms with a currently
/// checked-in guest are shown. Returns the row's `guest_stay_id` so callers
/// can look up the contact + guest name in one shot.
class RoomPickerSheet {
  static Future<String?> showCheckedIn(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ColorPalette.opsSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _CheckedInRoomSheetBody(),
    );
  }
}

class _CheckedInRoomSheetBody extends ConsumerWidget {
  const _CheckedInRoomSheetBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final async = ref.watch(checkedInGuestStaysProvider);

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: SafeArea(
        top: false,
        child: FractionallySizedBox(
          heightFactor: 0.6,
          child: Column(
            children: [
              const _Handle(),
              const _Header(),
              Expanded(
                child: async.when(
                  data: (stays) => _CheckedInGrid(
                    stays: stays,
                    onPick: (guestStayId) =>
                        Navigator.of(context).pop(guestStayId),
                  ),
                  loading: () => const Center(
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  ),
                  error: (e, _) => _ErrorView(
                    message: e.toString(),
                    onRetry: () =>
                        ref.invalidate(checkedInGuestStaysProvider),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckedInGrid extends StatelessWidget {
  final List<CheckedInGuestStay> stays;
  final ValueChanged<String> onPick;
  const _CheckedInGrid({required this.stays, required this.onPick});

  @override
  Widget build(BuildContext context) {
    if (stays.isEmpty) {
      return Center(
        child: Text(
          context.l10n.emptyState,
          style: TypographyManager.bodyMedium.copyWith(
            color: ColorPalette.textSecondary,
          ),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 52,
      ),
      itemCount: stays.length,
      itemBuilder: (_, i) {
        final s = stays[i];
        return _RoomCell(
          label: s.roomNumber,
          onTap: () => onPick(s.guestStayId),
        );
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TypographyManager.bodySmall.copyWith(
                color: ColorPalette.error,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onRetry,
              child: Text(context.l10n.retry),
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
  const _Header();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              context.l10n.roomPickerTitle,
              style: TypographyManager.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            color: ColorPalette.textSecondary,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _RoomCell extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _RoomCell({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.l10n.roomNumber(label),
      child: Material(
        color: ColorPalette.opsSurface,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ColorPalette.opsBorder),
            ),
            child: Text(
              label,
              style: TypographyManager.titleSmall.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
