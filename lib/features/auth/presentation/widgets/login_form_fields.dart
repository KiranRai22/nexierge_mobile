import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/theme/typography_manager.dart';
import '../providers/login_controller.dart';
import '../utils/login_validators.dart';

/// Field group: external label with required asterisk + optional inline
/// error / helper text below the input.
class LabeledField extends StatelessWidget {
  final String label;
  final Widget child;
  final String? errorText;
  final String? helperText;

  const LabeledField({
    super.key,
    required this.label,
    required this.child,
    this.errorText,
    this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: label,
            style: TypographyManager.labelLarge.copyWith(
              fontSize: 13,
              color: ColorPalette.loginFieldLabel,
              fontWeight: FontWeight.w600,
            ),
            children: [
              TextSpan(
                text: ' *',
                style: TypographyManager.labelLarge.copyWith(
                  fontSize: 13,
                  color: ColorPalette.loginRequiredAsterisk,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        child,
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: TypographyManager.labelSmall.copyWith(
              color: ColorPalette.activityOverdueFg,
              fontWeight: FontWeight.w500,
            ),
          ),
        ] else if (helperText != null) ...[
          const SizedBox(height: 6),
          Text(
            helperText!,
            style: TypographyManager.labelSmall.copyWith(
              color: ColorPalette.loginSubtitle,
            ),
          ),
        ],
      ],
    );
  }
}

class _LoginTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final bool obscureText;
  final bool hasError;
  final bool autofocus;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final VoidCallback? onSubmitted;
  final ValueChanged<String>? onChanged;
  final String? autofillHint;
  final String semanticsLabel;
  final Widget? trailing;

  const _LoginTextField({
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    required this.semanticsLabel,
    this.obscureText = false,
    this.hasError = false,
    this.autofocus = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.onChanged,
    this.autofillHint,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = hasError
        ? ColorPalette.activityOverdueFg
        : ColorPalette.loginInputBorder;
    return Container(
      decoration: BoxDecoration(
        color: ColorPalette.loginInputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 12),
            child: Icon(
              prefixIcon,
              color: ColorPalette.loginInputIcon,
              size: 20,
            ),
          ),
          Expanded(
            child: Semantics(
              label: semanticsLabel,
              textField: true,
              child: TextField(
                controller: controller,
                autofocus: autofocus,
                obscureText: obscureText,
                keyboardType: keyboardType,
                textInputAction: textInputAction,
                onSubmitted:
                    onSubmitted == null ? null : (_) => onSubmitted!(),
                onChanged: onChanged,
                cursorColor: ColorPalette.loginInputText,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(
                      LoginValidators.maxFieldLength),
                ],
                autofillHints:
                    autofillHint == null ? null : [autofillHint!],
                style: TypographyManager.bodyMedium.copyWith(
                  color: ColorPalette.loginInputText,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  filled: false,
                  fillColor: Colors.transparent,
                  hintText: hint,
                  hintStyle: TypographyManager.bodyMedium.copyWith(
                    color: ColorPalette.loginInputHint,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Email-or-employee-code identifier field.
class IdentifierField extends StatelessWidget {
  final TextEditingController controller;
  final LoginMode mode;
  final String? errorText;
  final bool autofocus;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;

  const IdentifierField({
    super.key,
    required this.controller,
    required this.mode,
    required this.onChanged,
    required this.onSubmitted,
    this.errorText,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final isEmail = mode == LoginMode.email;
    return LabeledField(
      label: isEmail ? s.loginEmailLabel : s.loginEmployeeCodeLabel,
      errorText: errorText,
      child: _LoginTextField(
        controller: controller,
        hint: isEmail ? s.loginEmailHint : s.loginEmployeeCodeHint,
        prefixIcon: isEmail ? Icons.mail_outline : Icons.tag,
        keyboardType:
            isEmail ? TextInputType.emailAddress : TextInputType.text,
        textInputAction: TextInputAction.next,
        autofillHint: isEmail ? AutofillHints.email : AutofillHints.username,
        semanticsLabel:
            isEmail ? s.loginEmailLabel : s.loginEmployeeCodeLabel,
        hasError: errorText != null,
        autofocus: autofocus,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
      ),
    );
  }
}

/// Password-or-code field with visibility toggle and helper text.
class SecretField extends StatelessWidget {
  final TextEditingController controller;
  final LoginMode mode;
  final bool obscure;
  final String? errorText;
  final VoidCallback onToggleObscure;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;

  const SecretField({
    super.key,
    required this.controller,
    required this.mode,
    required this.obscure,
    required this.onToggleObscure,
    required this.onChanged,
    required this.onSubmitted,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final isEmail = mode == LoginMode.email;
    return LabeledField(
      label: isEmail ? s.loginPasswordLabel : s.loginCodeLabel,
      errorText: errorText,
      helperText: isEmail ? null : s.loginEmployeeHelper,
      child: _LoginTextField(
        controller: controller,
        hint: isEmail ? '' : s.loginCodeHint,
        prefixIcon: isEmail ? Icons.lock_outline : Icons.key_outlined,
        obscureText: obscure,
        keyboardType: TextInputType.visiblePassword,
        textInputAction: TextInputAction.done,
        autofillHint:
            isEmail ? AutofillHints.password : AutofillHints.oneTimeCode,
        semanticsLabel:
            isEmail ? s.loginPasswordLabel : s.loginCodeLabel,
        hasError: errorText != null,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        trailing: isEmail
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 1,
                    height: 24,
                    color: ColorPalette.loginInputDivider,
                  ),
                  IconButton(
                    onPressed: onToggleObscure,
                    splashRadius: 20,
                    icon: Icon(
                      obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: ColorPalette.loginInputIcon,
                      size: 20,
                    ),
                  ),
                ],
              )
            : null,
      ),
    );
  }
}
