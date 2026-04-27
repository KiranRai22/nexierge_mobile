import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/theme/typography_manager.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/models/ticket.dart';
import '../providers/universal_create_controller.dart';
import '../widgets/create/item_grid.dart';
import '../widgets/create/recent_rooms_row.dart';
import '../widgets/create/room_picker_sheet.dart';

/// Universal create screen — quick operational asks (towels, pillows, etc.).
class UniversalCreateScreen extends ConsumerWidget {
  const UniversalCreateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(universalDraftControllerProvider);

    return Scaffold(
      backgroundColor: ColorPalette.opsSurface,
      appBar: AppBar(
        backgroundColor: ColorPalette.opsSurface,
        foregroundColor: ColorPalette.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          context.l10n.universalHeading,
          style: TypographyManager.screenTitle,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: const [
                  _Subheading(),
                  SizedBox(height: 12),
                  ItemGrid(),
                  SizedBox(height: 20),
                  _RoomBlock(),
                  SizedBox(height: 20),
                  _NoteBlock(),
                ],
              ),
            ),
            _CreateButton(state: draft),
          ],
        ),
      ),
    );
  }
}

class _Subheading extends StatelessWidget {
  const _Subheading();
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        context.l10n.universalSubheading,
        style: TypographyManager.bodyMedium,
      ),
    );
  }
}

class _RoomBlock extends ConsumerWidget {
  const _RoomBlock();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.l10n;
    final draft = ref.watch(universalDraftControllerProvider);
    final ctl = ref.read(universalDraftControllerProvider.notifier);
    final rooms = ref.watch(availableRoomsProvider);
    final selected = draft.selectedRoomId == null
        ? null
        : rooms.firstWhere(
            (r) => r.id == draft.selectedRoomId,
            orElse: () => rooms.first,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              s.roomLabel,
              style: TypographyManager.sectionOverline,
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () async {
                final picked = await RoomPickerSheet.show(context);
                if (picked != null) ctl.selectRoom(picked);
              },
              icon: const Icon(Icons.search_rounded, size: 16),
              label: Text(s.roomFind),
              style: TextButton.styleFrom(
                foregroundColor: ColorPalette.opsPurple,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (selected != null)
          _SelectedRoomTile(
            room: selected,
            onClear: ctl.clearRoom,
          )
        else
          const RecentRoomsRow(),
      ],
    );
  }
}

class _SelectedRoomTile extends StatelessWidget {
  final Room room;
  final VoidCallback onClear;
  const _SelectedRoomTile({required this.room, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: ColorPalette.opsPurpleTint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorPalette.opsPurple),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.meeting_room_outlined,
            color: ColorPalette.opsPurpleDark,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  s.roomNumber(room.number),
                  style: TypographyManager.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: ColorPalette.opsPurpleDark,
                  ),
                ),
                Text(
                  room.type ?? s.roomFloor(room.floor),
                  style: TypographyManager.bodySmall.copyWith(
                    color: ColorPalette.opsPurpleDark,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: s.cancel,
            onPressed: onClear,
            icon: const Icon(
              Icons.close_rounded,
              color: ColorPalette.opsPurpleDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteBlock extends ConsumerStatefulWidget {
  const _NoteBlock();

  @override
  ConsumerState<_NoteBlock> createState() => _NoteBlockState();
}

class _NoteBlockState extends ConsumerState<_NoteBlock> {
  late final TextEditingController _ctl;

  @override
  void initState() {
    super.initState();
    _ctl = TextEditingController(
      text: ref.read(universalDraftControllerProvider).note,
    );
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.noteLabel,
          style: TypographyManager.sectionOverline,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _ctl,
          minLines: 2,
          maxLines: 4,
          textInputAction: TextInputAction.newline,
          onChanged: (v) => ref
              .read(universalDraftControllerProvider.notifier)
              .setNote(v),
          style: TypographyManager.bodyMedium,
          decoration: InputDecoration(
            hintText: s.noteHint,
            hintStyle: TypographyManager.bodyMedium.copyWith(
              color: ColorPalette.textSecondary,
            ),
            filled: true,
            fillColor: ColorPalette.opsSurfaceSubtle,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
        ),
      ],
    );
  }
}

class _CreateButton extends ConsumerWidget {
  final UniversalDraftState state;
  const _CreateButton({required this.state});

  String _hint(AppLocalizations s) {
    if (state.picks.isEmpty) return s.pickItemHint;
    if (state.selectedRoomId == null) return s.pickRoomHint;
    return s.itemsSelected(state.picks.length);
  }

  Future<void> _submit(BuildContext context, WidgetRef ref) async {
    final id = await ref
        .read(universalDraftControllerProvider.notifier)
        .submit();
    if (id == null || !context.mounted) return;
    final toast = context.l10n.createSuccessToast;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(toast)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.l10n;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              _hint(s),
              style: TypographyManager.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
          ElevatedButton(
            onPressed:
                state.canSubmit ? () => _submit(context, ref) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorPalette.opsPurple,
              foregroundColor: ColorPalette.white,
              disabledBackgroundColor: ColorPalette.opsBorder,
              disabledForegroundColor: ColorPalette.textDisabled,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: TypographyManager.titleSmall.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            child: state.submitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(ColorPalette.white),
                    ),
                  )
                : Text(s.createCta),
          ),
        ],
      ),
    );
  }
}
