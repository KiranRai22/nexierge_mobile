import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/i18n/l10n_extension.dart';
import '../../../../../core/theme/color_palette.dart';
import '../../../../../core/theme/typography_manager.dart';
import '../../../../../core/widgets/dotted_divider.dart';
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

class _RoomSheetBody extends ConsumerStatefulWidget {
  const _RoomSheetBody();

  @override
  ConsumerState<_RoomSheetBody> createState() => _RoomSheetBodyState();
}

class _RoomSheetBodyState extends ConsumerState<_RoomSheetBody> {
  late final TextEditingController _searchCtl;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchCtl = TextEditingController();
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  List<Room> _filtered(List<Room> all) {
    if (_query.isEmpty) return all;
    final q = _query.toLowerCase();
    return all.where((r) =>
        r.number.toLowerCase().contains(q) ||
        (r.type ?? '').toLowerCase().contains(q)).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final rooms = _filtered(ref.watch(availableRoomsProvider));
    final byFloor = <int, List<Room>>{};
    for (final r in rooms) {
      byFloor.putIfAbsent(r.floor, () => []).add(r);
    }
    final floors = byFloor.keys.toList()..sort();

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: SafeArea(
        top: false,
        child: FractionallySizedBox(
          heightFactor: 0.78,
          child: Column(
            children: [
              const _Handle(),
              const _Header(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: _Search(
                  controller: _searchCtl,
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              DottedDivider(color: ColorPalette.opsDividerSubtle, thickness: 1, height: 8, dashWidth: 6, gap: 4),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: floors.length,
                  itemBuilder: (context, i) {
                    final f = floors[i];
                    return _FloorSection(
                      floor: f,
                      rooms: byFloor[f]!,
                      onPick: (id) => Navigator.of(context).pop(id),
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
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          context.l10n.roomPickerTitle,
          style: TypographyManager.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _Search extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _Search({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: TypographyManager.bodyMedium,
      decoration: InputDecoration(
        hintText: context.l10n.roomSearchHint,
        hintStyle: TypographyManager.bodyMedium.copyWith(
          color: ColorPalette.textSecondary,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: ColorPalette.textSecondary,
        ),
        filled: true,
        fillColor: ColorPalette.opsSurfaceSubtle,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ColorPalette.opsBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ColorPalette.opsBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ColorPalette.opsPurple),
        ),
      ),
    );
  }
}

class _FloorSection extends StatelessWidget {
  final int floor;
  final List<Room> rooms;
  final ValueChanged<String> onPick;
  const _FloorSection({
    required this.floor,
    required this.rooms,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            context.l10n.roomFloor(floor),
            style: TypographyManager.sectionOverline,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final r in rooms)
                _RoomChip(room: r, onTap: () => onPick(r.id)),
            ],
          ),
        ),
      ],
    );
  }
}

class _RoomChip extends StatelessWidget {
  final Room room;
  final VoidCallback onTap;
  const _RoomChip({required this.room, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.l10n.roomNumber(room.number),
      child: Material(
        color: ColorPalette.opsSurfaceSubtle,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ColorPalette.opsBorder),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room.number,
                  style: TypographyManager.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (room.type != null)
                  Text(
                    room.type!,
                    style: TypographyManager.bodySmall,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
