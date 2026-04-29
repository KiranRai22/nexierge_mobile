import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/theme/unified_theme_manager.dart';
import '../../../../core/theme/typography_manager.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../data/services/image_picker_service.dart';
import '../../domain/entities/user_profile.dart';
import '../providers/user_profile_controller.dart';
import '../widgets/change_profile_picture_sheet.dart';
import '../widgets/profile_header_card.dart';
import '../widgets/profile_info_section.dart';
import '../widgets/profile_language_card.dart';
import '../widgets/profile_logout_button.dart';
import '../widgets/profile_theme_card.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _uploadingAvatar = false;
  bool _updatingName = false;

  // ── Avatar upload ──────────────────────────────────────────────────────────

  Future<void> _onChangeAvatar() async {
    if (_uploadingAvatar) return;

    final source = await ChangeProfilePictureSheet.show(context);
    if (source == null || !mounted) return;

    final picker = ImagePickerService();
    final file = await picker.pickAndCompress(source);
    if (file == null || !mounted) return;

    setState(() => _uploadingAvatar = true);
    final messenger = ScaffoldMessenger.of(context);
    final s = context.l10n;

    try {
      final success = await ref
          .read(userProfileControllerProvider.notifier)
          .updateAvatar(file);
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? s.profileUpdateAvatarSuccess
                  : s.profileUpdateAvatarFailed,
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  // ── Name edit ──────────────────────────────────────────────────────────────

  Future<void> _onEditName(UserProfile profile) async {
    if (_updatingName) return;

    final parts = profile.fullName.trim().split(RegExp(r'\s+'));
    final originalFirst = parts.first;
    final originalLast = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    final result = await showDialog<(String, String)?>(
      context: context,
      builder: (ctx) => _EditNameDialog(
        initialFirstName: originalFirst,
        initialLastName: originalLast,
      ),
    );

    if (result == null || !mounted) return;
    final (firstName, lastName) = result;
    if (firstName.trim().isEmpty) return;

    setState(() => _updatingName = true);
    final messenger = ScaffoldMessenger.of(context);
    final s = context.l10n;

    try {
      final success = await ref
          .read(userProfileControllerProvider.notifier)
          .updateName(firstName.trim(), lastName.trim());
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              success ? s.profileUpdateNameSuccess : s.profileUpdateNameFailed,
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => _updatingName = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    final asyncProfile = ref.watch(userProfileControllerProvider);

    return Container(
      color: c.bgSubtle,
      child: SafeArea(
        bottom: false,
        child: asyncProfile.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                e.toString(),
                textAlign: TextAlign.center,
                style: TypographyManager.bodyMedium.copyWith(color: c.fgSubtle),
              ),
            ),
          ),
          data: (profile) => _ProfileBody(
            profile: profile,
            uploadingAvatar: _uploadingAvatar,
            updatingName: _updatingName,
            onChangeAvatar: _onChangeAvatar,
            onEditName: () => _onEditName(profile),
          ),
        ),
      ),
    );
  }
}

// ── Body ─────────────────────────────────────────────────────────────────────

class _ProfileBody extends StatelessWidget {
  final UserProfile profile;
  final bool uploadingAvatar;
  final bool updatingName;
  final VoidCallback onChangeAvatar;
  final VoidCallback onEditName;

  const _ProfileBody({
    required this.profile,
    required this.uploadingAvatar,
    required this.updatingName,
    required this.onChangeAvatar,
    required this.onEditName,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: ProfileHeaderCard(
            profile: profile,
            uploadingAvatar: uploadingAvatar,
            updatingName: updatingName,
            onChangeAvatar: onChangeAvatar,
            onEditName: onEditName,
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 96),
            children: [
              ProfileInfoSection(
                title: s.profileSectionAccountInformation,
                rows: [
                  ProfileInfoRow(
                    label: s.profileFieldName,
                    value: profile.fullName,
                  ),
                  ProfileInfoRow(
                    label: s.profileFieldEmail,
                    value: profile.email,
                  ),
                  if (profile.phone != null && profile.phone!.isNotEmpty)
                    ProfileInfoRow(
                      label: s.profileFieldPhone,
                      value: profile.phone!,
                    ),
                  ProfileInfoRow(
                    label: s.profileFieldEmployeeCode,
                    value: profile.employeeCode ?? s.profileFieldEmptyValue,
                  ),
                  ProfileInfoRow(
                    label: s.profileFieldRole,
                    value: profile.role,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ProfileInfoSection(
                title: s.profileSectionWorkInformation,
                rows: [
                  if (profile.hotelName != null &&
                      profile.hotelName!.isNotEmpty)
                    ProfileInfoRow(
                      label: s.profileFieldHotel,
                      value: profile.hotelName!,
                    ),
                  ProfileInfoRow(
                    label: s.profileFieldDepartments,
                    value: profile.departments.isNotEmpty
                        ? profile.departments.join(', ')
                        : s.profileFieldEmptyValue,
                  ),
                  ProfileInfoRow(
                    label: s.profileFieldStatus,
                    value: _statusLabel(s, profile.status),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                child: Builder(
                  builder: (context) => Text(
                    s.profileSectionPreferences.toUpperCase(),
                    style: TypographyManager.kpiLabel.copyWith(
                      color: context.themeColors.fgSubtle,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),
              const ProfileLanguageCard(),
              const SizedBox(height: 12),
              const ProfileThemeCard(),
              const SizedBox(height: 24),
              const ProfileLogoutButton(),
            ],
          ),
        ),
      ],
    );
  }

  String _statusLabel(AppLocalizations s, UserStatus status) {
    switch (status) {
      case UserStatus.active:
        return s.profileStatusActive;
      case UserStatus.inactive:
        return s.profileStatusInactive;
    }
  }
}

// ── Edit name dialog ──────────────────────────────────────────────────────────

class _EditNameDialog extends StatefulWidget {
  final String initialFirstName;
  final String initialLastName;

  const _EditNameDialog({
    required this.initialFirstName,
    required this.initialLastName,
  });

  @override
  State<_EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<_EditNameDialog> {
  late final TextEditingController _firstCtl;
  late final TextEditingController _lastCtl;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _firstCtl = TextEditingController(text: widget.initialFirstName);
    _lastCtl = TextEditingController(text: widget.initialLastName);
  }

  @override
  void dispose() {
    _firstCtl.dispose();
    _lastCtl.dispose();
    super.dispose();
  }

  /// Validates name according to rules:
  /// - Only alphabets and single space allowed
  /// - Cannot start with space or special characters
  /// - Max 1 space between letters
  /// - Min 3 characters
  String? _validateName(String value, String fieldName) {
    final trimmed = value.trim();

    if (trimmed.length < 3) {
      return '$fieldName must be at least 3 characters';
    }

    // Check if starts with space
    if (value.startsWith(' ')) {
      return '$fieldName cannot start with space';
    }

    // Check for valid characters (alphabets and single space only)
    final validCharsRegex = RegExp(r'^[a-zA-Z]+( [a-zA-Z]+)*$');
    if (!validCharsRegex.hasMatch(trimmed)) {
      return '$fieldName can only contain letters and single spaces';
    }

    // Check for multiple consecutive spaces
    if (trimmed.contains('  ')) {
      return '$fieldName cannot have multiple spaces';
    }

    return null;
  }

  bool _isValid() {
    final firstError = _validateName(_firstCtl.text, 'First name');
    final lastError = _validateName(_lastCtl.text, 'Last name');

    if (firstError != null || lastError != null) {
      setState(() {
        _errorText = firstError ?? lastError;
      });
      return false;
    }

    // Check if name is unchanged
    final currentFirst = _firstCtl.text.trim();
    final currentLast = _lastCtl.text.trim();

    if (currentFirst == widget.initialFirstName.trim() &&
        currentLast == widget.initialLastName.trim()) {
      setState(() {
        _errorText = 'No changes detected. Please modify the name to save.';
      });
      return false;
    }

    setState(() => _errorText = null);
    return true;
  }

  void _onSave() {
    if (_isValid()) {
      Navigator.of(context).pop((_firstCtl.text.trim(), _lastCtl.text.trim()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final c = context.themeColors;

    return AlertDialog(
      title: Text(s.profileEditNameTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _firstCtl,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: s.profileFirstName,
              errorText: _errorText?.contains('First') == true
                  ? _errorText
                  : null,
            ),
            autofocus: true,
            onChanged: (_) => setState(() => _errorText = null),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _lastCtl,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: s.profileLastName,
              errorText: _errorText?.contains('Last') == true
                  ? _errorText
                  : null,
            ),
            onChanged: (_) => setState(() => _errorText = null),
          ),
          if (_errorText != null &&
              !_errorText!.contains('First') &&
              !_errorText!.contains('Last')) ...[
            const SizedBox(height: 8),
            Text(
              _errorText!,
              style: TypographyManager.bodySmall.copyWith(color: c.tagRedIcon),
            ),
          ],
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      actions: [
        Row(
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: Text(
                s.cancel,
                style: TypographyManager.bodyMedium.copyWith(color: c.fgMuted),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: c.tagPurpleIcon,
                foregroundColor: Colors.white,
                minimumSize: const Size(96, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                s.profileEditNameSave,
                style: TypographyManager.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
