part of 'create_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MANUAL TAB
// ─────────────────────────────────────────────────────────────────────────────

class _ManualTabBody extends ConsumerStatefulWidget {
  const _ManualTabBody();

  @override
  ConsumerState<_ManualTabBody> createState() => _ManualTabBodyState();
}

class _ManualTabBodyState extends ConsumerState<_ManualTabBody> {
  late final TextEditingController _summaryCtl;
  late final TextEditingController _guestCtl;
  late final TextEditingController _notesCtl;

  @override
  void initState() {
    super.initState();
    final state = ref.read(manualDraftControllerProvider);
    _summaryCtl = TextEditingController(text: state.summary);
    _guestCtl = TextEditingController(text: state.guestName);
    _notesCtl = TextEditingController(text: state.notes);
  }

  @override
  void dispose() {
    _summaryCtl.dispose();
    _guestCtl.dispose();
    _notesCtl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    try {
      final id = await ref
          .read(manualDraftControllerProvider.notifier)
          .submit();
      if (id == null || !mounted) {
        context.showFailure(context.l10n.serverError);
        return;
      }
      Navigator.of(context).pop(true);
      context.showSuccess(context.l10n.createSuccessToast);
    } on AppException catch (e) {
      if (!mounted) return;
      context.showFailure(e.localizedMessage(context.l10n));
    } catch (e) {
      if (!mounted) return;
      context.showFailure(context.l10n.unknownError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final draft = ref.watch(manualDraftControllerProvider);
    final ctl = ref.read(manualDraftControllerProvider.notifier);
    // Keep the read-only guest field synced with the auto-populated name
    // sourced from the picked checked-in stay.
    if (_guestCtl.text != draft.guestName) {
      _guestCtl.value = TextEditingValue(
        text: draft.guestName,
        selection: TextSelection.collapsed(offset: draft.guestName.length),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            children: [
              // Summary
              _FieldLabel(s.createSummaryLabel, required: true),
              const SizedBox(height: 6),
              TextField(
                controller: _summaryCtl,
                onChanged: ctl.setSummary,
                minLines: 2,
                maxLines: 3,
                style: TypographyManager.bodyMedium,
                decoration: _inputDecoration(hint: s.createSummaryHint),
              ),
              const SizedBox(height: 16),

              // Room + Guest row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FieldLabel(s.createRoomLabel, required: true),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () async {
                            final picked =
                                await RoomPickerSheet.showCheckedIn(context);
                            if (picked != null) ctl.selectGuestStay(picked);
                          },
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: ColorPalette.opsSurfaceSubtle,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: ColorPalette.opsBorder),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    draft.selectedRoomNumber != null
                                        ? s.roomNumber(draft.selectedRoomNumber!)
                                        : s.roomPickerTitle,
                                    style: TypographyManager.bodyMedium
                                        .copyWith(
                                          color: draft.selectedRoomNumber != null
                                              ? ColorPalette.textPrimary
                                              : ColorPalette.textSecondary,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  size: 16,
                                  color: ColorPalette.textSecondary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FieldLabel(
                          s.createGuestOptionalLabel,
                          required: false,
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _guestCtl,
                          readOnly: true,
                          style: TypographyManager.bodyMedium,
                          decoration: _inputDecoration(
                            hint: s.createGuestHint,
                            prefixIcon: const Icon(
                              Icons.person_outline,
                              size: 18,
                              color: ColorPalette.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Department picker
              _FieldLabel(s.createDepartmentLabel, required: true),
              const SizedBox(height: 6),
              _DepartmentField(
                value: draft.department,
                onChanged: ctl.setDepartment,
                hint: s.createDepartmentHint,
              ),
              const SizedBox(height: 16),

              // Source chips
              _FieldLabel(s.createSourceLabel, required: true),
              const SizedBox(height: 8),
              _SourceChips(selected: draft.source, onSelect: ctl.setSource),
              const SizedBox(height: 16),

              // Notes
              _FieldLabel(s.createNotesOptionalLabel, required: false),
              const SizedBox(height: 6),
              TextField(
                controller: _notesCtl,
                onChanged: ctl.setNotes,
                minLines: 3,
                maxLines: 5,
                style: TypographyManager.bodyMedium,
                decoration: _inputDecoration(hint: s.createNotesHint),
              ),
            ],
          ),
        ),

        // Bottom actions
        _ManualBottomBar(draft: draft, onSubmit: _submit),
      ],
    );
  }

  InputDecoration _inputDecoration({required String hint, Widget? prefixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TypographyManager.bodyMedium.copyWith(
        color: ColorPalette.textSecondary,
      ),
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: ColorPalette.opsSurfaceSubtle,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: ColorPalette.opsBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: ColorPalette.opsBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: ColorPalette.opsPurple),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  final bool required;
  const _FieldLabel(this.text, {required this.required});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: text,
        style: TypographyManager.labelMedium.copyWith(
          color: ColorPalette.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        children: required
            ? const [
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: ColorPalette.error),
                ),
              ]
            : null,
      ),
    );
  }
}

class _DepartmentField extends ConsumerWidget {
  final HotelDepartment? value;
  final ValueChanged<HotelDepartment> onChanged;
  final String hint;
  const _DepartmentField({
    required this.value,
    required this.onChanged,
    required this.hint,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.themeColors;
    final asyncOptions = ref.watch(ticketFormOptionsProvider);
    final depts = asyncOptions.maybeWhen(
      data: (o) => o.departments,
      orElse: () => const <HotelDepartment>[],
    );
    final isLoading = asyncOptions.isLoading && depts.isEmpty;

    return GestureDetector(
      onTap: isLoading
          ? null
          : () async {
              final pickedId = await DepartmentPickerSheet.show(context);
              if (pickedId != null) {
                final picked = depts.firstWhere((d) => d.id == pickedId);
                onChanged(picked);
              }
            },
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: c.bgField,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: c.borderBase),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value?.name ?? (isLoading ? '${context.l10n.loading} ' : hint),
                style: TypographyManager.bodyMedium.copyWith(
                  color: value != null ? c.fgBase : c.fgSubtle,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.chevron_right_rounded, color: c.fgMuted, size: 18),
          ],
        ),
      ),
    );
  }
}

class _SourceChips extends StatelessWidget {
  final TicketSource? selected;
  final ValueChanged<TicketSource> onSelect;
  const _SourceChips({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final sources = [
      (TicketSource.whatsApp, '💬', s.createSourceWhatsApp),
      (TicketSource.phone, '📞', s.createSourcePhone),
      (TicketSource.frontDesk, '🔔', s.createSourceFrontDesk),
      (TicketSource.walkIn, '🧑', s.createSourceInPerson),
      (TicketSource.system, '⚙️', s.createSourceInternal),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: sources.map((entry) {
        final (src, emoji, label) = entry;
        final isSelected = selected == src;
        return GestureDetector(
          onTap: () => onSelect(src),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? ColorPalette.opsPurpleTint
                  : ColorPalette.opsSurfaceSubtle,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? ColorPalette.opsPurple
                    : ColorPalette.opsBorder,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TypographyManager.labelMedium.copyWith(
                    color: isSelected
                        ? ColorPalette.opsPurpleDark
                        : ColorPalette.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ManualBottomBar extends StatelessWidget {
  final ManualDraftState draft;
  final VoidCallback onSubmit;
  const _ManualBottomBar({required this.draft, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: ColorPalette.textPrimary,
                side: BorderSide(color: ColorPalette.opsBorder),
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: TypographyManager.titleSmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: Text(s.cancel),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: draft.canSubmit ? onSubmit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorPalette.opsPurple,
                foregroundColor: ColorPalette.white,
                disabledBackgroundColor: ColorPalette.opsBorder,
                disabledForegroundColor: ColorPalette.textDisabled,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: TypographyManager.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: draft.submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          ColorPalette.white,
                        ),
                      ),
                    )
                  : Text(s.createTicketCta),
            ),
          ),
        ],
      ),
    );
  }
}
