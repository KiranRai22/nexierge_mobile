import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/services/sound_manager.dart';
import '../../../../core/theme/card_theme.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/theme/unified_theme_manager.dart';
import '../../../../core/theme/typography_manager.dart';
import '../../../../core/utils/name_validator.dart';
import '../../../../core/widgets/widget_manager.dart';
import '../../../../core/utils/string_utils.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../data/services/image_picker_service.dart';
import '../../data/services/media_permission_service.dart';
import '../../domain/entities/user_profile.dart';
import '../providers/user_profile_controller.dart';
import '../widgets/change_profile_picture_sheet.dart';
import '../providers/profile_section_expansion_provider.dart';
import '../widgets/profile_footer.dart';
import '../widgets/profile_header_card_animated.dart';
import '../widgets/profile_info_section.dart';
import '../widgets/profile_logout_button.dart';
import '../widgets/profile_preferences_section.dart';
import '../widgets/skeletons/profile_screen_skeleton.dart';

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

    final permission = await const MediaPermissionService().ensure(source);
    if (!mounted) return;
    switch (permission) {
      case MediaPermissionResult.granted:
        break;
      case MediaPermissionResult.denied:
        _showPermissionDeniedToast(source);
        return;
      case MediaPermissionResult.permanentlyDenied:
        await _showPermissionBlockedDialog(source);
        return;
    }

    final picker = ImagePickerService();
    final file = await picker.pickAndCompress(source);
    if (file == null || !mounted) return;

    setState(() => _uploadingAvatar = true);
    final s = context.l10n;

    try {
      final success = await ref
          .read(userProfileControllerProvider.notifier)
          .updateAvatar(file);
      if (!mounted) return;
      if (success) {
        context.showSuccess(s.profileUpdateAvatarSuccess);
      } else {
        context.showFailure(s.profileUpdateAvatarFailed);
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  void _showPermissionDeniedToast(ImageSource$ source) {
    final s = context.l10n;
    final msg = source == ImageSource$.camera
        ? s.profileAvatarPermissionDeniedCamera
        : s.profileAvatarPermissionDeniedGallery;
    context.showFailure(msg);
  }

  Future<void> _showPermissionBlockedDialog(ImageSource$ source) async {
    final s = context.l10n;
    final c = context.themeColors;
    final body = source == ImageSource$.camera
        ? s.profileAvatarPermissionBlockedCameraBody
        : s.profileAvatarPermissionBlockedGalleryBody;

    final shouldOpen = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.bgBase,
        title: Text(s.profileAvatarPermissionBlockedTitle),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: tapSound(
              () => Navigator.of(ctx).pop(false),
              SoundCategory.back,
            ),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: tapSound(() => Navigator.of(ctx).pop(true)),
            child: Text(s.profileAvatarPermissionOpenSettings),
          ),
        ],
      ),
    );
    if (shouldOpen ?? false) {
      await const MediaPermissionService().openSettings();
    }
  }

  // ── Name edit ──────────────────────────────────────────────────────────────

  Future<void> _onEditName(UserProfile profile) async {
    if (_updatingName) return;

    final parts = profile.fullName.trim().split(RegExp(r'\s+'));
    final originalFirst = parts.isNotEmpty ? parts.first : '';
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
    final s = context.l10n;

    try {
      // Format names using StringUtils before submission
      final formattedFirstName = StringUtils.formatName(firstName.trim());
      final formattedLastName = StringUtils.formatName(lastName.trim());

      final success = await ref
          .read(userProfileControllerProvider.notifier)
          .updateName(formattedFirstName, formattedLastName);
      if (!mounted) return;
      if (success) {
        context.showSuccess(s.profileUpdateNameSuccess);
      } else {
        context.showFailure(s.profileUpdateNameFailed);
      }
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
          loading: () => const ProfileScreenSkeleton(),
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

class _ProfileBody extends StatefulWidget {
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
  State<_ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends State<_ProfileBody> {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;
  static const double _shrinkThreshold = 50;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset.clamp(0, _shrinkThreshold);
    });
  }

  double get _shrinkProgress => (_scrollOffset / _shrinkThreshold).clamp(0, 1);

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: ProfileHeaderCardAnimated(
            profile: widget.profile,
            uploadingAvatar: widget.uploadingAvatar,
            updatingName: widget.updatingName,
            onChangeAvatar: widget.onChangeAvatar,
            onEditName: widget.onEditName,
            scrollController: _scrollController,
          ),
        ),
        Expanded(
          child: ListView(
            controller: _scrollController,
            padding: EdgeInsets.fromLTRB(
              16,
              16 +
                  (_shrinkProgress *
                      20), // Dynamic top padding when card shrinks
              16,
              120,
            ), // Increased bottom padding for bottom nav
            children: [
              ProfileInfoSection(
                key: const ValueKey(ProfileSectionId.account),
                sectionId: ProfileSectionId.account,
                title: s.profileSectionAccountInformation,
                summary: _buildAccountSummary(widget.profile),
                rows: [
                  ProfileInfoRow(
                    label: s.profileFieldName,
                    value: widget.profile.fullName,
                  ),
                  ProfileInfoRow(
                    label: s.profileFieldEmail,
                    value: widget.profile.email,
                  ),
                  if (widget.profile.phone != null &&
                      widget.profile.phone!.isNotEmpty)
                    ProfileInfoRow(
                      label: s.profileFieldPhone,
                      value: widget.profile.phone!,
                    ),
                  ProfileInfoRow(
                    label: s.profileFieldEmployeeCode,
                    value:
                        widget.profile.employeeCode ?? s.profileFieldEmptyValue,
                  ),
                  ProfileInfoRow(
                    label: s.profileFieldRole,
                    value: StringUtils.formatRoleWithMapping(
                      widget.profile.role,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ProfileInfoSection(
                key: const ValueKey(ProfileSectionId.work),
                sectionId: ProfileSectionId.work,
                title: s.profileSectionWorkInformation,
                summary: _buildWorkSummary(widget.profile),
                rows: [
                  if (widget.profile.hotelName != null &&
                      widget.profile.hotelName!.isNotEmpty)
                    ProfileInfoRow(
                      label: s.profileFieldHotel,
                      value: widget.profile.hotelName!,
                    ),
                  ProfileInfoRow(
                    label: s.profileFieldDepartments,
                    value: widget.profile.departments.isNotEmpty
                        ? widget.profile.departments.join(', ')
                        : s.profileFieldEmptyValue,
                  ),
                  ProfileInfoRow(
                    label: s.profileFieldStatus,
                    value: _statusLabel(s, widget.profile.status),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ProfileInfoSection(
                key: const ValueKey(ProfileSectionId.hotel),
                sectionId: ProfileSectionId.hotel,
                title: 'Hotel Details',
                summary: _buildHotelSummary(widget.profile),
                rows: [
                  if (widget.profile.hotelBusinessEmail != null &&
                      widget.profile.hotelBusinessEmail!.isNotEmpty)
                    ProfileInfoRow(
                      label: 'Business Email',
                      value: widget.profile.hotelBusinessEmail!,
                    ),
                  if (widget.profile.hotelBusinessPhone != null &&
                      widget.profile.hotelBusinessPhone!.isNotEmpty)
                    ProfileInfoRow(
                      label: 'Business Phone',
                      value: widget.profile.hotelBusinessPhone!,
                    ),
                  if (widget.profile.hotelWebsite != null &&
                      widget.profile.hotelWebsite!.isNotEmpty)
                    ProfileInfoRow(
                      label: 'Website',
                      value: widget.profile.hotelWebsite!,
                    ),
                  if (widget.profile.hotelAddress != null &&
                      widget.profile.hotelAddress!.isNotEmpty)
                    ProfileInfoRow(
                      label: 'Address',
                      value: widget.profile.hotelAddress!,
                    ),
                  if (widget.profile.hotelTimezone != null &&
                      widget.profile.hotelTimezone!.isNotEmpty)
                    ProfileInfoRow(
                      label: 'Timezone',
                      value: widget.profile.hotelTimezone!,
                    ),
                ],
              ),
              const SizedBox(height: 24),
              ProfileInfoSection(
                key: const ValueKey(ProfileSectionId.subscription),
                sectionId: ProfileSectionId.subscription,
                title: 'Subscription',
                summary: _buildSubscriptionSummary(widget.profile),
                rows: [
                  ProfileInfoRow(
                    label: 'Plan',
                    value: widget.profile.subscriptionPlan ?? 'Not available',
                  ),
                  ProfileInfoRow(
                    label: 'Status',
                    value: widget.profile.subscriptionActive ?? false
                        ? 'Active'
                        : 'Inactive',
                  ),
                  if (widget.profile.subscriptionStartDate != null)
                    ProfileInfoRow(
                      label: 'Start Date',
                      value: _formatDate(widget.profile.subscriptionStartDate!),
                    ),
                  if (widget.profile.subscriptionEndDate != null)
                    ProfileInfoRow(
                      label: 'End Date',
                      value: _formatDate(widget.profile.subscriptionEndDate!),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              ProfileInfoSection(
                key: const ValueKey(ProfileSectionId.systemAccess),
                sectionId: ProfileSectionId.systemAccess,
                title: 'System Access',
                summary: _buildAccessSummary(widget.profile),
                rows: [
                  ProfileInfoRow(
                    label: 'Login Method',
                    value: widget.profile.authMethod ?? 'Password',
                  ),
                  ProfileInfoRow(
                    label: 'Interface Access',
                    value: widget.profile.interfaceAccess ?? 'Web',
                  ),
                  if (widget.profile.hubAccess.isNotEmpty)
                    ProfileInfoRow(
                      label: 'Hub Access',
                      value: widget.profile.hubAccess.join(', '),
                    ),
                  if (widget.profile.lastLoginAt != null)
                    ProfileInfoRow(
                      label: 'Last Login',
                      value: _formatDate(widget.profile.lastLoginAt!),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              ProfilePreferencesSection(),
              const SizedBox(height: 24),
              const ProfileLogoutButton(),
              const SizedBox(height: 16),
              // Terms & Conditions and Privacy Policy buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // TODO: Navigate to Terms & Conditions
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ColorPalette.opsPurple,
                        side: const BorderSide(color: ColorPalette.opsPurple),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Terms & Conditions',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // TODO: Navigate to Privacy Policy
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ColorPalette.opsPurple,
                        side: const BorderSide(color: ColorPalette.opsPurple),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Privacy Policy',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ],
              ),
              const ProfileFooter(version: '1.0.0'),
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

  String _buildAccountSummary(UserProfile profile) {
    final parts = profile.fullName.trim().split(RegExp(r'\s+'));
    final firstName = parts.isNotEmpty
        ? StringUtils.formatName(parts.first)
        : '';
    final employeeCode = profile.employeeCode ?? '';
    final role = StringUtils.formatRoleWithMapping(profile.role);

    return 'Name: $firstName, ECode: $employeeCode, Role: $role';
  }

  String _buildWorkSummary(UserProfile profile) {
    final hotelName = StringUtils.formatName(profile.hotelName ?? '');
    final status = _statusLabel(context.l10n, profile.status);

    final List<String> summaryParts = [
      'Property: $hotelName',
      'Status: $status',
    ];

    // Only add department if it's not empty
    if (profile.departments.isNotEmpty) {
      final formattedDepartments = profile.departments
          .map((dept) => StringUtils.formatName(dept))
          .join(', ');
      summaryParts.insert(1, 'Department: $formattedDepartments');
    }

    return summaryParts.join(', ');
  }

  String _buildHotelSummary(UserProfile profile) {
    final parts = <String>[];

    if (profile.hotelBusinessEmail != null &&
        profile.hotelBusinessEmail!.isNotEmpty) {
      parts.add('Email: ${profile.hotelBusinessEmail}');
    }
    if (profile.hotelBusinessPhone != null &&
        profile.hotelBusinessPhone!.isNotEmpty) {
      parts.add('Phone: ${profile.hotelBusinessPhone}');
    }
    if (profile.hotelTimezone != null && profile.hotelTimezone!.isNotEmpty) {
      parts.add('Timezone: ${profile.hotelTimezone}');
    }

    return parts.isNotEmpty ? parts.join(', ') : 'Hotel details available';
  }

  String _buildSubscriptionSummary(UserProfile profile) {
    final plan = profile.subscriptionPlan ?? 'No plan';
    final status = profile.subscriptionActive ?? false ? 'Active' : 'Inactive';
    return 'Plan: $plan, Status: $status';
  }

  String _buildAccessSummary(UserProfile profile) {
    final parts = <String>[];

    if (profile.authMethod != null) {
      parts.add('Auth: ${profile.authMethod}');
    }
    if (profile.interfaceAccess != null) {
      parts.add('Interface: ${profile.interfaceAccess}');
    }
    if (profile.hubAccess.isNotEmpty) {
      parts.add('Hubs: ${profile.hubAccess.length}');
    }

    return parts.isNotEmpty ? parts.join(', ') : 'Standard access';
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
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
  String? _firstError;
  String? _lastError;

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

  /// Validates name using the NameValidator utility
  String? _validateName(String value, String fieldName) {
    return NameValidator.validateName(value, fieldName);
  }

  void _validateFields() {
    setState(() {
      _firstError = _validateName(_firstCtl.text, 'First name');
      _lastError = _validateName(_lastCtl.text, 'Last name');

      // Clear general error if both fields are valid
      if (_firstError == null && _lastError == null) {
        _errorText = null;
      }
    });
  }

  bool _isValid() {
    _validateFields();

    if (_firstError != null || _lastError != null) {
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

    return true;
  }

  void _onSave() {
    if (_isValid()) {
      // Format names before saving
      final formattedNames = NameValidator.formatFullName(
        _firstCtl.text,
        _lastCtl.text,
      );
      Navigator.of(
        context,
      ).pop((formattedNames['firstName']!, formattedNames['lastName']!));
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
              errorText: _firstError,
            ),
            autofocus: true,
            onChanged: (_) => _validateFields(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _lastCtl,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: s.profileLastName,
              errorText: _lastError,
            ),
            onChanged: (_) => _validateFields(),
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
            AppOutlinedButton(
              label: s.cancel,
              onPressed: tapSound(
                () => Navigator.of(context).pop(null),
                SoundCategory.back,
              ),
              width: 120,
            ),
            const SizedBox(width: 16),
            AppPrimaryButton(
              label: s.profileEditNameSave,
              onPressed: tapSound(_onSave),
              width: 120,
              leadingIcon: const Icon(Icons.check, size: 18),
            ),
          ],
        ),
      ],
    );
  }
}
