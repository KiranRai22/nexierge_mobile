import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/theme/card_theme.dart';
import '../../../../core/theme/unified_theme_manager.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/theme/typography_manager.dart';
import '../../domain/entities/user_profile.dart';

/// Animated header that shrinks on scroll.
/// Starts as column (big avatar, name, role), shrinks to row (avatar | name+role).
class ProfileHeaderCardAnimated extends StatefulWidget {
  final UserProfile profile;
  final bool uploadingAvatar;
  final bool updatingName;
  final VoidCallback? onChangeAvatar;
  final VoidCallback? onEditName;
  final ScrollController scrollController;

  const ProfileHeaderCardAnimated({
    super.key,
    required this.profile,
    this.uploadingAvatar = false,
    this.updatingName = false,
    this.onChangeAvatar,
    this.onEditName,
    required this.scrollController,
  });

  @override
  State<ProfileHeaderCardAnimated> createState() =>
      _ProfileHeaderCardAnimatedState();
}

class _ProfileHeaderCardAnimatedState extends State<ProfileHeaderCardAnimated> {
  double _scrollOffset = 0;
  static const double _shrinkThreshold = 50;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = widget.scrollController.offset.clamp(0, _shrinkThreshold);
    });
  }

  double get _shrinkProgress => (_scrollOffset / _shrinkThreshold).clamp(0, 1);

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    final p = _shrinkProgress;

    // Continuous interpolation values
    final avatarSize = Tween<double>(begin: 96, end: 56).transform(p);
    final nameFontSize = Tween<double>(begin: 20, end: 16).transform(p);
    final verticalPadding = Tween<double>(begin: 28, end: 12).transform(p);
    final horizontalPadding = Tween<double>(begin: 24, end: 16).transform(p);
    final avatarNameSpacing = Tween<double>(begin: 16, end: 12).transform(p);

    return Container(
      decoration: CardDecoration.standard(
        colors: c,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        verticalPadding,
        horizontalPadding,
        verticalPadding - 4,
      ),
      child: p > 0.5
          ? _buildCollapsedLayout(
              avatarSize: avatarSize,
              nameFontSize: nameFontSize,
            )
          : _buildExpandedLayout(
              avatarSize: avatarSize,
              nameFontSize: nameFontSize,
              avatarNameSpacing: avatarNameSpacing,
            ),
    );
  }

  Widget _buildExpandedLayout({
    required double avatarSize,
    required double nameFontSize,
    required double avatarNameSpacing,
  }) {
    return Column(
      children: [
        _Avatar(
          initials: widget.profile.initials,
          avatarUrl: widget.profile.avatarUrl,
          uploading: widget.uploadingAvatar,
          onChange: widget.onChangeAvatar,
          size: avatarSize,
        ),
        SizedBox(height: avatarNameSpacing),
        _buildNameRow(fontSize: nameFontSize),
        const SizedBox(height: 8),
        _RolePill(label: widget.profile.role),
        if (widget.profile.departments.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            widget.profile.departments.join(' · '),
            textAlign: TextAlign.center,
            style: TypographyManager.bodyMedium.copyWith(
              color: context.themeColors.fgSubtle,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCollapsedLayout({
    required double avatarSize,
    required double nameFontSize,
  }) {
    return Row(
      children: [
        // Avatar column - 40%
        SizedBox(
          width: Tween<double>(begin: 100, end: 80).transform(_shrinkProgress),
          child: Center(
            child: _Avatar(
              initials: widget.profile.initials,
              avatarUrl: widget.profile.avatarUrl,
              uploading: widget.uploadingAvatar,
              onChange: widget.onChangeAvatar,
              size: avatarSize,
              showCameraBadge: false,
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Name + role column - 60%
        Expanded(
          flex: 60,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      widget.profile.fullName,
                      style: TypographyManager.titleMedium.copyWith(
                        color: context.themeColors.fgBase,
                        fontWeight: FontWeight.w700,
                        fontSize: nameFontSize,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  widget.updatingName
                      ? SizedBox(
                          width: Tween<double>(
                            begin: 16,
                            end: 14,
                          ).transform(_shrinkProgress),
                          height: Tween<double>(
                            begin: 16,
                            end: 14,
                          ).transform(_shrinkProgress),
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : GestureDetector(
                          onTap: widget.onEditName,
                          child: Icon(
                            LucideIcons.pencil,
                            size: Tween<double>(
                              begin: 16,
                              end: 14,
                            ).transform(_shrinkProgress),
                            color: context.themeColors.fgSubtle,
                          ),
                        ),
                ],
              ),
              const SizedBox(height: 4),
              _RolePill(label: widget.profile.role, compact: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNameRow({required double fontSize}) {
    final c = context.themeColors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            widget.profile.fullName,
            textAlign: TextAlign.center,
            style: TypographyManager.headlineSmall.copyWith(
              color: c.fgBase,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              fontSize: fontSize,
            ),
          ),
        ),
        const SizedBox(width: 6),
        widget.updatingName
            ? SizedBox(
                width: Tween<double>(
                  begin: 18,
                  end: 16,
                ).transform(_shrinkProgress),
                height: Tween<double>(
                  begin: 18,
                  end: 16,
                ).transform(_shrinkProgress),
                child: const CircularProgressIndicator(strokeWidth: 2),
              )
            : GestureDetector(
                onTap: widget.onEditName,
                child: Tooltip(
                  message: context.l10n.profileEditNameTitle,
                  child: Icon(
                    LucideIcons.pencil,
                    size: Tween<double>(
                      begin: 16,
                      end: 14,
                    ).transform(_shrinkProgress),
                    color: c.fgSubtle,
                  ),
                ),
              ),
      ],
    );
  }
}

// ── Avatar ───────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String initials;
  final String? avatarUrl;
  final bool uploading;
  final VoidCallback? onChange;
  final double size;
  final bool showCameraBadge;

  const _Avatar({
    required this.initials,
    this.avatarUrl,
    this.uploading = false,
    this.onChange,
    required this.size,
    this.showCameraBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final c = context.themeColors;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipOval(
            child: uploading
                ? Container(
                    width: size,
                    height: size,
                    color: ColorPalette.opsPurple,
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: size * 0.33,
                      height: size * 0.33,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    ),
                  )
                : avatarUrl != null && avatarUrl!.isNotEmpty
                ? Image.network(
                    avatarUrl!,
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _InitialsDisc(initials: initials, size: size),
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        width: size,
                        height: size,
                        color: ColorPalette.opsPurple,
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: size * 0.25,
                          height: size * 0.25,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  )
                : _InitialsDisc(initials: initials, size: size),
          ),
          if (!uploading && showCameraBadge)
            Positioned(
              right: -2,
              bottom: -2,
              child: Material(
                color: c.bgBase,
                shape: CircleBorder(
                  side: BorderSide(color: c.borderBase, width: 1),
                ),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onChange,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Tooltip(
                      message: s.profileChangeAvatar,
                      child: Icon(
                        LucideIcons.camera,
                        size: 14,
                        color: c.fgSubtle,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InitialsDisc extends StatelessWidget {
  final String initials;
  final double size;

  const _InitialsDisc({required this.initials, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: ColorPalette.opsPurple,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TypographyManager.headlineMedium.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          fontSize: size * 0.4,
        ),
      ),
    );
  }
}

// ── Role pill ─────────────────────────────────────────────────────────────────

class _RolePill extends StatelessWidget {
  final String label;
  final bool compact;

  const _RolePill({required this.label, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: ColorPalette.opsPurpleSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TypographyManager.labelSmall.copyWith(
          color: ColorPalette.opsPurpleDark,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
          fontSize: compact ? 11 : 12,
        ),
      ),
    );
  }
}
