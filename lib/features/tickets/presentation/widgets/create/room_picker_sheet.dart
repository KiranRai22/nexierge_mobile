import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/i18n/l10n_extension.dart';
import '../../../../../core/theme/color_palette.dart';
import '../../../../../core/theme/typography_manager.dart';
import '../../../domain/models/ticket.dart';
import '../../providers/universal_create_controller.dart';

/// Bottom sheet for selecting a room. Returns the [Room.id] or null.
class RoomPickerSheet {
  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ColorPalette.opsSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _RoomSheetBody(),
    );
  }
}

class _RoomSheetBody extends ConsumerWidget {
  const _RoomSheetBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final rooms = ref.watch(availableRoomsProvider);

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
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: 52,
                  ),
                  itemCount: rooms.length,
                  itemBuilder: (_, i) {
                    final r = rooms[i];
                    return _RoomCell(
                      room: r,
                      onTap: () => Navigator.of(context).pop(r.id),
                    );
                  },
                ),
              ),
            ],
          ),
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
  final Room room;
  final VoidCallback onTap;
  const _RoomCell({required this.room, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.l10n.roomNumber(room.number),
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
              room.number,
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
