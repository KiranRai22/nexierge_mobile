import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../i18n/l10n_extension.dart';
import '../theme/typography_manager.dart';
import '../../core/theme/app_colors.dart';

/// Full-width primary action button with optional loading state and leading icon.
class AppPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;
  final Widget? leadingIcon;

  const AppPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.width,
    this.leadingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: context.appColors.fgBase,
          foregroundColor: context.appColors.fgOnBrand,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: context.appColors.fgOnBrand,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (leadingIcon != null) ...[
                    IconTheme.merge(
                      data: IconThemeData(color: context.appColors.fgOnBrand),
                      child: leadingIcon!,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: TypographyManager.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.appColors.fgOnBrand,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Full-width outlined secondary button.
class AppOutlinedButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final double? width;

  const AppOutlinedButton({
    super.key,
    required this.label,
    this.onPressed,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: context.appColors.fgOnBrand,
          foregroundColor: context.appColors.fgBase,
          side: BorderSide(color: context.appColors.borderStrong),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: TypographyManager.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Themed text form field with label, hint, validation, and optional icons.
class AppTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int maxLines;
  final void Function(String)? onChanged;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.validator,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
      ),
    );
  }
}

/// Centered circular progress indicator.
class AppLoader extends StatelessWidget {
  final Color? color;
  final double size;

  const AppLoader({super.key, this.color, this.size = 32});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: color ?? context.appColors.brandPrimary,
        ),
      ),
    );
  }
}

/// Centered empty-state illustration with optional CTA.
class AppEmptyState extends StatelessWidget {
  /// If null, falls back to the localized "Nothing here yet." string.
  final String? message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppEmptyState({
    super.key,
    this.message,
    this.icon = LucideIcons.inbox,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final resolved = message ?? context.l10n.emptyState;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: context.appColors.fgMuted),
            const SizedBox(height: 16),
            Text(
              resolved,
              style: TypographyManager.bodyMedium.copyWith(
                color: context.appColors.fgSubtle,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              AppPrimaryButton(
                label: actionLabel!,
                onPressed: onAction,
                width: 200,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Centered error display with optional retry action.
class AppErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const AppErrorWidget({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.triangleAlert,
              size: 64,
              color: context.appColors.fgError,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TypographyManager.bodyMedium.copyWith(
                color: context.appColors.fgSubtle,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              AppOutlinedButton(
                label: context.l10n.retry,
                onPressed: onRetry,
                width: 200,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
