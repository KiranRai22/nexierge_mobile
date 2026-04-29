import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/unified_theme_manager.dart';
import '../../../../core/theme/typography_manager.dart';
import '../../domain/entities/user_profile.dart';
import '../providers/user_profile_controller.dart';

/// Reusable profile avatar widget that shows profile image when available,
/// with initials fallback when no profile picture is set.
/// Automatically updates when profile picture changes.
class ProfileAvatar extends ConsumerWidget {
  final double size;
  final VoidCallback? onTap;
  final bool showBorder;
  final double? borderWidth;
  final Color? borderColor;

  const ProfileAvatar({
    super.key,
    this.size = 36,
    this.onTap,
    this.showBorder = true,
    this.borderWidth,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(userProfileControllerProvider);
    final c = context.themeColors;

    // Handle loading state
    if (profileState.isLoading && profileState.profile == null) {
      return _AvatarPlaceholder(
        size: size,
        onTap: onTap,
        showBorder: showBorder,
        borderWidth: borderWidth,
        borderColor: borderColor,
      );
    }

    // Handle error state
    if (profileState.error != null && profileState.profile == null) {
      return _AvatarPlaceholder(
        size: size,
        onTap: onTap,
        showBorder: showBorder,
        borderWidth: borderWidth,
        borderColor: borderColor,
      );
    }

    // Handle null profile
    if (profileState.profile == null) {
      return _AvatarPlaceholder(
        size: size,
        onTap: onTap,
        showBorder: showBorder,
        borderWidth: borderWidth,
        borderColor: borderColor,
      );
    }

    final profile = profileState.profile!;
    final profileImageUrl = profile.pictureProfile?.url;
    final initials = '${profile.firstName[0]}${profile.lastName[0]}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: showBorder
              ? Border.all(
                  color: borderColor ?? c.borderBase,
                  width: borderWidth ?? 1,
                )
              : null,
        ),
        child: ClipOval(
          child: profileImageUrl != null && profileImageUrl.isNotEmpty
              ? Image.network(
                  profileImageUrl,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _AvatarPlaceholder(
                      size: size,
                      initials: initials,
                      showBorder: false,
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return _AvatarPlaceholder(
                      size: size,
                      initials: initials,
                      showBorder: false,
                    );
                  },
                )
              : _AvatarPlaceholder(
                  size: size,
                  initials: initials,
                  showBorder: false,
                ),
        ),
      ),
    );
  }
}

/// Placeholder widget that shows initials when no profile image is available
class _AvatarPlaceholder extends StatelessWidget {
  final double size;
  final String? initials;
  final VoidCallback? onTap;
  final bool showBorder;
  final double? borderWidth;
  final Color? borderColor;

  const _AvatarPlaceholder({
    required this.size,
    this.initials,
    this.onTap,
    this.showBorder = true,
    this.borderWidth,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    final displayInitials = initials ?? '?';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: c.bgSubtle,
          shape: BoxShape.circle,
          border: showBorder
              ? Border.all(
                  color: borderColor ?? c.borderBase,
                  width: borderWidth ?? 1,
                )
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          displayInitials,
          style: TypographyManager.labelSmall.copyWith(
            color: c.fgBase,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            fontSize: size * 0.35, // Scale font size with avatar size
          ),
        ),
      ),
    );
  }
}

/// Profile avatar with online status indicator
class ProfileAvatarWithStatus extends ConsumerWidget {
  final double size;
  final VoidCallback? onTap;
  final bool isOnline;
  final bool showBorder;
  final double? borderWidth;
  final Color? borderColor;

  const ProfileAvatarWithStatus({
    super.key,
    this.size = 36,
    this.onTap,
    this.isOnline = false,
    this.showBorder = true,
    this.borderWidth,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ProfileAvatar(
          size: size,
          onTap: onTap,
          showBorder: showBorder,
          borderWidth: borderWidth,
          borderColor: borderColor,
        ),
        if (isOnline)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: size * 0.25,
              height: size * 0.25,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: context.themeColors.bgBase, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}
