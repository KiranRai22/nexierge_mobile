import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/i18n/app_locale.dart';
import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/i18n/locale_controller.dart';
import '../../../../core/providers/sound_preferences_provider.dart';
import '../../../../core/providers/vibration_preferences_provider.dart';
import '../../../../core/services/app_info_service.dart';
import '../../../../core/services/sound_manager.dart';
import '../../../../core/services/vibration_manager.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/theme/theme_mode_controller.dart';
import '../../../../core/theme/unified_theme_manager.dart';
import '../../../../core/theme/typography_manager.dart';
import '../../../../core/utils/name_validator.dart';
import '../../../../core/utils/string_utils.dart';
import '../../../../core/widgets/widget_manager.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../data/services/image_picker_service.dart';
import '../../data/services/media_permission_service.dart';
import '../../domain/entities/user_profile.dart';
import '../providers/user_profile_controller.dart';
import '../widgets/change_profile_picture_sheet.dart';
import '../widgets/profile_header_card_animated.dart';
import '../widgets/profile_logout_button.dart';
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
            versionLabel: ref.read(appInfoServiceProvider).versionLabel,
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
  final String versionLabel;

  const _ProfileBody({
    required this.profile,
    required this.uploadingAvatar,
    required this.updatingName,
    required this.onChangeAvatar,
    required this.onEditName,
    required this.versionLabel,
  });

  @override
  State<_ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends State<_ProfileBody>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _headerController = ProfileHeaderController();
  bool _headerCollapsed = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _toggleHeader() {
    if (_headerCollapsed) {
      _headerController.expand();
    } else {
      _headerController.collapse();
    }
    setState(() => _headerCollapsed = !_headerCollapsed);
  }

  String _statusLabel(AppLocalizations s, UserStatus status) {
    switch (status) {
      case UserStatus.active:
        return s.profileStatusActive;
      case UserStatus.inactive:
        return s.profileStatusInactive;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final c = context.themeColors;
    final p = widget.profile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Header card with collapse/expand toggle ──────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Stack(
            children: [
              ProfileHeaderCardAnimated(
                profile: p,
                uploadingAvatar: widget.uploadingAvatar,
                updatingName: widget.updatingName,
                onChangeAvatar: widget.onChangeAvatar,
                onEditName: widget.onEditName,
                scrollController: ScrollController(),
                controller: _headerController,
              ),
              // Collapse / expand button — top-right corner
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: c.bgSubtle,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: tapSound(_toggleHeader, SoundCategory.preference),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          _headerCollapsed
                              ? LucideIcons.chevronDown
                              : LucideIcons.chevronUp,
                          key: ValueKey(_headerCollapsed),
                          size: 16,
                          color: c.fgMuted,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Tab bar ──────────────────────────────────────────────────────────
        TabBar(
          controller: _tabController,
          labelColor: ColorPalette.opsPurple,
          unselectedLabelColor: c.fgMuted,
          indicatorColor: ColorPalette.opsPurple,
          indicatorSize: TabBarIndicatorSize.tab,
          labelStyle: TypographyManager.labelSmall.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: TypographyManager.labelSmall.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          tabs: [
            Tab(text: s.profileTabAccount),
            Tab(text: s.profileTabWork),
            Tab(text: s.profileTabPreferences),
            Tab(text: s.profileTabAbout),
          ],
        ),
        Divider(height: 1, color: c.borderBase),

        // ── Tab content (logout included in each tab's scroll) ──────────────
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _AccountTab(profile: p, statusLabel: _statusLabel),
              _WorkTab(profile: p, statusLabel: _statusLabel),
              const _PreferencesTab(),
              _AboutTab(versionLabel: widget.versionLabel),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Account tab ───────────────────────────────────────────────────────────────

class _AccountTab extends StatelessWidget {
  final UserProfile profile;
  final String Function(AppLocalizations, UserStatus) statusLabel;
  const _AccountTab({required this.profile, required this.statusLabel});

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final c = context.themeColors;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
      children: [
        _InfoCard(rows: [
          _InfoRow(label: s.profileFieldName, value: profile.fullName, c: c),
          _InfoRow(label: s.profileFieldEmail, value: profile.email, c: c),
          if (profile.phone != null && profile.phone!.isNotEmpty)
            _InfoRow(label: s.profileFieldPhone, value: profile.phone!, c: c),
          _InfoRow(label: s.profileFieldEmployeeCode, value: profile.employeeCode ?? s.profileFieldEmptyValue, c: c),
          _InfoRow(label: s.profileFieldRole, value: StringUtils.formatRoleWithMapping(profile.role), c: c, isLast: true),
        ]),
        const SizedBox(height: 24),
        const ProfileLogoutButton(),
      ],
    );
  }
}

// ── Work tab ──────────────────────────────────────────────────────────────────

class _WorkTab extends StatelessWidget {
  final UserProfile profile;
  final String Function(AppLocalizations, UserStatus) statusLabel;
  const _WorkTab({required this.profile, required this.statusLabel});

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final c = context.themeColors;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
      children: [
        _InfoCard(rows: [
          if (profile.hotelName != null && profile.hotelName!.isNotEmpty)
            _InfoRow(label: s.profileFieldHotel, value: profile.hotelName!, c: c),
          _InfoRow(
            label: s.profileFieldDepartments,
            value: profile.departments.isNotEmpty
                ? profile.departments.join(', ')
                : s.profileFieldEmptyValue,
            c: c,
          ),
          _InfoRow(label: s.profileFieldStatus, value: statusLabel(s, profile.status), c: c, isLast: true),
        ]),
        const SizedBox(height: 24),
        const ProfileLogoutButton(),
      ],
    );
  }
}

// ── Preferences tab ───────────────────────────────────────────────────────────

class _PreferencesTab extends ConsumerWidget {
  const _PreferencesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.l10n;
    final c = context.themeColors;
    final locale = ref.watch(localeControllerProvider).valueOrNull ?? AppLocale.system;
    final themeMode = ref.watch(themeModeControllerProvider).valueOrNull ?? ThemeMode.system;
    final soundOn = ref.watch(soundPreferencesProvider);
    final vibrationOn = ref.watch(vibrationPreferencesProvider);

    String resolvedLocale() {
      if (locale == AppLocale.spanish) return 'ES';
      if (locale == AppLocale.english) return 'EN';
      final code = Localizations.localeOf(context).languageCode;
      return code == 'es' ? 'ES' : 'EN';
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        // Language
        _PrefCard(
          title: s.profileLanguageTitle,
          subtitle: s.profileLanguageSubtitle,
          trailing: _SegmentToggle(
            options: const ['EN', 'ES'],
            selected: resolvedLocale(),
            onChanged: (v) => ref.read(localeControllerProvider.notifier)
                .set(v == 'ES' ? AppLocale.spanish : AppLocale.english),
            c: c,
          ),
        ),
        const SizedBox(height: 12),
        // Theme
        _PrefCard(
          title: s.profileThemeTitle,
          subtitle: s.profileThemeSubtitle,
          child: _ThemeToggle(mode: themeMode, c: c, ref: ref),
        ),
        const SizedBox(height: 12),
        // Sound
        _PrefCard(
          title: 'Sound',
          subtitle: 'Enable or disable app sound effects',
          trailing: _OnOffToggle(
            value: soundOn,
            onChanged: (v) async {
              await SoundManager.instance.play(SoundCategory.preference);
              await ref.read(soundPreferencesProvider.notifier).setEnabled(v);
              SoundManager.instance.setEnabled(v);
            },
            c: c,
          ),
        ),
        const SizedBox(height: 12),
        // Vibration
        _PrefCard(
          title: s.profileVibrationTitle,
          subtitle: s.profileVibrationSubtitle,
          trailing: _OnOffToggle(
            value: vibrationOn,
            onChanged: (v) {
              ref.read(vibrationPreferencesProvider.notifier).setEnabled(v);
              if (v) VibrationManager.instance.trigger();
            },
            c: c,
          ),
        ),
        const SizedBox(height: 24),
        const ProfileLogoutButton(),
      ],
    );
  }
}

// ── About tab ─────────────────────────────────────────────────────────────────

class _AboutTab extends StatelessWidget {
  final String versionLabel;
  const _AboutTab({required this.versionLabel});

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    final s = context.l10n;
    final year = DateTime.now().year;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 24),
      children: [
        Center(
          child: Container(
            width: 88,
            height: 88,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.bgBase,
              shape: BoxShape.circle,
              border: Border.all(color: c.borderBase, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Image.asset('assets/images/app_logo.png', fit: BoxFit.contain),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Nexierge',
          textAlign: TextAlign.center,
          style: TypographyManager.textHeading.copyWith(
            color: c.fgBase,
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          s.profileFooterVersion(versionLabel),
          textAlign: TextAlign.center,
          style: TypographyManager.bodyMedium.copyWith(color: c.fgMuted),
        ),
        const SizedBox(height: 4),
        Text(
          s.profileFooterCopyright(year),
          textAlign: TextAlign.center,
          style: TypographyManager.bodySmall.copyWith(color: c.fgSubtle, fontSize: 11),
        ),
        const SizedBox(height: 32),
        const ProfileLogoutButton(),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: tapSound(() => launchUrl(
                  Uri.parse('https://app.nexierge.io/terms'),
                  mode: LaunchMode.inAppBrowserView,
                )),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ColorPalette.opsPurple,
                  side: const BorderSide(color: ColorPalette.opsPurple),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  textStyle: TypographyManager.labelSmall.copyWith(fontWeight: FontWeight.w500),
                ),
                child: const Text('Terms & Conditions'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: tapSound(() => launchUrl(
                  Uri.parse('https://app.nexierge.io/privacy'),
                  mode: LaunchMode.inAppBrowserView,
                )),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ColorPalette.opsPurple,
                  side: const BorderSide(color: ColorPalette.opsPurple),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  textStyle: TypographyManager.labelSmall.copyWith(fontWeight: FontWeight.w500),
                ),
                child: const Text('Privacy Policy'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Shared info card / row ────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final List<Widget> rows;
  const _InfoCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    return Container(
      decoration: BoxDecoration(
        color: c.bgBase,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.borderBase),
      ),
      child: Column(children: rows),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final AppColors c;
  final bool isLast;
  const _InfoRow({required this.label, required this.value, required this.c, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Text(label, style: TypographyManager.bodySmall.copyWith(color: c.fgMuted)),
              const Spacer(),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: TypographyManager.bodyMedium.copyWith(color: c.fgBase, fontWeight: FontWeight.w500),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, indent: 16, endIndent: 16, color: c.borderBase),
      ],
    );
  }
}

// ── Shared preference card ────────────────────────────────────────────────────

class _PrefCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;
  final Widget? child;
  const _PrefCard({required this.title, required this.subtitle, this.trailing, this.child});

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    return Container(
      decoration: BoxDecoration(
        color: c.bgBase,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.borderBase),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TypographyManager.bodyMedium.copyWith(color: c.fgBase, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TypographyManager.bodySmall.copyWith(color: c.fgSubtle)),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 12), trailing!],
            ],
          ),
          if (child != null) ...[const SizedBox(height: 12), child!],
        ],
      ),
    );
  }
}

class _SegmentToggle extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onChanged;
  final AppColors c;
  const _SegmentToggle({required this.options, required this.selected, required this.onChanged, required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(color: c.tagNeutralBg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((opt) {
          final sel = opt == selected;
          return Material(
            color: sel ? ColorPalette.opsPurple : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              onTap: tapSound(() => onChanged(opt), SoundCategory.preference),
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Text(opt, style: TypographyManager.labelSmall.copyWith(
                  color: sel ? Colors.white : c.fgSubtle,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                )),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _OnOffToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final AppColors c;
  const _OnOffToggle({required this.value, required this.onChanged, required this.c});

  @override
  Widget build(BuildContext context) {
    return _SegmentToggle(
      options: const ['OFF', 'ON'],
      selected: value ? 'ON' : 'OFF',
      onChanged: (v) => onChanged(v == 'ON'),
      c: c,
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  final ThemeMode mode;
  final AppColors c;
  final WidgetRef ref;
  const _ThemeToggle({required this.mode, required this.c, required this.ref});

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(color: c.tagNeutralBg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        children: [
          _ThemeChip(icon: LucideIcons.sun, label: s.profileThemeLight, selected: mode == ThemeMode.light,
              onTap: () => ref.read(themeModeControllerProvider.notifier).set(ThemeMode.light)),
          _ThemeChip(icon: LucideIcons.moon, label: s.profileThemeDark, selected: mode == ThemeMode.dark,
              onTap: () => ref.read(themeModeControllerProvider.notifier).set(ThemeMode.dark)),
          _ThemeChip(icon: LucideIcons.monitor, label: s.profileThemeSystem, selected: mode == ThemeMode.system,
              onTap: () => ref.read(themeModeControllerProvider.notifier).set(ThemeMode.system)),
        ],
      ),
    );
  }
}

class _ThemeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ThemeChip({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    return Expanded(
      child: Material(
        color: selected ? ColorPalette.opsPurple : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: tapSound(onTap, SoundCategory.preference),
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: selected ? Colors.white : c.fgSubtle),
                const SizedBox(width: 4),
                Flexible(child: Text(label, style: TypographyManager.labelSmall.copyWith(
                  color: selected ? Colors.white : c.fgSubtle,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ), overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
        ),
      ),
    );
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
