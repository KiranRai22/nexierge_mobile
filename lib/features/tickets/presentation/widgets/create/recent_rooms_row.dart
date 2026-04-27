import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/i18n/l10n_extension.dart';
import '../../../../../core/theme/color_palette.dart';
import '../../../../../core/theme/typography_manager.dart';
import '../../providers/universal_create_controller.dart';

/// Horizontal strip of recent rooms shown above the room field. Tap to
/// select. Shows the first 6 rooms from the repo (proxy for "recent" until
/// real recents are stored).
class RecentRoomsRow extends ConsumerWidget {
  const RecentRoomsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.l10n;
    final rooms = ref.watch(availableRoomsProvider).take(6).toList();
    final draft = ref.watch(universalDraftControllerProvider);
    final ctl = ref.read(universalDraftControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.roomRecentHelper,
          style: TypographyManager.bodySmall,
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: rooms.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final r = rooms[i];
              final selected = r.id == draft.selectedRoomId;
              return Semantics(
                button: true,
                selected: selected,
                label: s.roomNumber(r.number),
                child: GestureDetector(
                  onTap: () => ctl.selectRoom(r.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected
                          ? ColorPalette.opsPurpleTint
                          : ColorPalette.opsSurfaceSubtle,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected
                            ? ColorPalette.opsPurple
                            : ColorPalette.opsBorder,
                      ),
                    ),
                    child: Text(
                      r.number,
                      style: TypographyManager.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? ColorPalette.opsPurpleDark
                            : ColorPalette.textPrimary,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
