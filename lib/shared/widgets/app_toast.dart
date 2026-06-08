import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/typography_manager.dart';

/// Toast types supported by the app
enum ToastType { success, failure, info, warning }

/// Toast position on screen
enum ToastPosition { top, bottom }

/// Generic app toast manager - reusable across the entire application.
///
/// Every color comes from [AppColors] via [BuildContext.appColors], so the
/// toast flips automatically with [ThemeMode]. Add new tokens to
/// `lib/core/theme/app_colors.dart` (light + dark) if a new shade is needed.
///
/// Usage:
/// ```dart
/// AppToast.show(
///   context,
///   title: context.l10n.successTitle,
///   subtitle: 'Ticket created successfully',
///   type: ToastType.success,
///   position: ToastPosition.top,
///   duration: Duration(seconds: 3),
/// );
/// ```
class AppToast {
  static OverlayEntry? _currentOverlay;

  static void show(
    BuildContext context, {
    required String title,
    String? subtitle,
    ToastType type = ToastType.info,
    ToastPosition position = ToastPosition.top,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onClose,
    VoidCallback? onTap,
  }) {
    hide();

    final overlay = Overlay.of(context);
    final palette = _ToastPalette.fromType(context.appColors, type);
    final shadow = context.appShadows.card;

    _currentOverlay = OverlayEntry(
      builder: (context) => Positioned(
        top: position == ToastPosition.top
            ? MediaQuery.of(context).padding.top + 16
            : null,
        bottom: position == ToastPosition.bottom
            ? MediaQuery.of(context).padding.bottom + 16
            : null,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap == null
                ? null
                : () {
                    hide();
                    onTap();
                  },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: palette.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: palette.border, width: 1),
                boxShadow: shadow,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: palette.iconBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      palette.icon,
                      color: palette.iconColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: TypographyManager.bodyMedium.copyWith(
                            color: palette.text,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (subtitle != null && subtitle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: TypographyManager.bodySmall.copyWith(
                              color: palette.subtitle,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      hide();
                      onClose?.call();
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: palette.closeBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.close,
                        color: palette.closeIcon,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(_currentOverlay!);

    Future.delayed(duration, () => hide());
  }

  static void hide() {
    _currentOverlay?.remove();
    _currentOverlay = null;
  }
}

/// Palette per toast type, derived entirely from [AppColors] so it flips
/// with the active theme. No hardcoded hex values.
class _ToastPalette {
  final Color background;
  final Color border;
  final Color iconBg;
  final Color iconColor;
  final Color text;
  final Color subtitle;
  final Color closeBg;
  final Color closeIcon;
  final IconData icon;

  const _ToastPalette({
    required this.background,
    required this.border,
    required this.iconBg,
    required this.iconColor,
    required this.text,
    required this.subtitle,
    required this.closeBg,
    required this.closeIcon,
    required this.icon,
  });

  factory _ToastPalette.fromType(AppColors c, ToastType type) {
    switch (type) {
      case ToastType.success:
        return _ToastPalette(
          background: c.bgSuccess,
          border: c.borderSuccess,
          iconBg: c.fgSuccess,
          iconColor: c.fgOnBrand,
          text: c.fgBase,
          subtitle: c.fgSubtle,
          closeBg: c.bgSuccessSubtle,
          closeIcon: c.fgSuccess,
          icon: Icons.check,
        );
      case ToastType.failure:
        return _ToastPalette(
          background: c.bgError,
          border: c.borderError,
          iconBg: c.fgError,
          iconColor: c.fgOnBrand,
          text: c.fgBase,
          subtitle: c.fgSubtle,
          closeBg: c.bgErrorSubtle,
          closeIcon: c.fgError,
          icon: Icons.close,
        );
      case ToastType.info:
        return _ToastPalette(
          background: c.bgInfo,
          border: c.borderInfo,
          iconBg: c.fgInfo,
          iconColor: c.fgOnBrand,
          text: c.fgBase,
          subtitle: c.fgSubtle,
          closeBg: c.bgInfoSubtle,
          closeIcon: c.fgInfo,
          icon: Icons.info_outline,
        );
      case ToastType.warning:
        return _ToastPalette(
          background: c.bgWarning,
          border: c.borderWarning,
          iconBg: c.fgWarning,
          iconColor: c.fgOnBrand,
          text: c.fgBase,
          subtitle: c.fgSubtle,
          closeBg: c.bgWarningSubtle,
          closeIcon: c.fgWarning,
          icon: Icons.warning_amber_rounded,
        );
    }
  }
}

/// Extension for easier toast access from BuildContext
extension AppToastExtension on BuildContext {
  void showSuccess(
    String title, {
    String? subtitle,
    ToastPosition position = ToastPosition.top,
  }) {
    AppToast.show(
      this,
      title: title,
      subtitle: subtitle,
      type: ToastType.success,
      position: position,
    );
  }

  void showFailure(
    String title, {
    String? subtitle,
    ToastPosition position = ToastPosition.top,
  }) {
    AppToast.show(
      this,
      title: title,
      subtitle: subtitle,
      type: ToastType.failure,
      position: position,
    );
  }

  void showInfo(
    String title, {
    String? subtitle,
    ToastPosition position = ToastPosition.top,
  }) {
    AppToast.show(
      this,
      title: title,
      subtitle: subtitle,
      type: ToastType.info,
      position: position,
    );
  }

  void showWarning(
    String title, {
    String? subtitle,
    ToastPosition position = ToastPosition.top,
  }) {
    AppToast.show(
      this,
      title: title,
      subtitle: subtitle,
      type: ToastType.warning,
      position: position,
    );
  }
}
