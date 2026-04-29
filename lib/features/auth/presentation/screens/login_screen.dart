import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/services/device_token_service.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/theme/typography_manager.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/login_credentials.dart';
import '../providers/login_controller.dart';
import '../utils/login_error_copy.dart';
import '../utils/login_validators.dart';
import '../widgets/auth_logo.dart';
import '../widgets/login_footer.dart';
import '../widgets/login_top_toast.dart';
import '../widgets/login_form_fields.dart';
import '../widgets/login_method_tabs.dart';
import '../widgets/login_state_dialog.dart';

/// Login screen wired to the auth API per the locked spec.
///
/// Responsibilities:
/// * own the per-mode `TextEditingController`s so input survives toggles
/// * validate fields locally before hitting the network
/// * disable the submit button while a request is in flight
/// * surface failures via toast (transient) or dialog (account state)
/// * preserve typed values on failure
///
/// Routing on success is reactive: the controller publishes the session to
/// `authSessionControllerProvider` and the root widget swaps in `HomeShell`.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  // Two pairs of controllers so each mode preserves its own values
  // (spec §4.1, §15.1 — switching tabs must not wipe the other tab).
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _employeeCodeCtrl = TextEditingController();
  final _loginCodeCtrl = TextEditingController();

  String? _identifierError;
  String? _secretError;

  @override
  void initState() {
    super.initState();
    for (final c in [
      _emailCtrl,
      _passwordCtrl,
      _employeeCodeCtrl,
      _loginCodeCtrl,
    ]) {
      c.addListener(_onAnyInputChanged);
    }
  }

  @override
  void dispose() {
    for (final c in [
      _emailCtrl,
      _passwordCtrl,
      _employeeCodeCtrl,
      _loginCodeCtrl,
    ]) {
      c
        ..removeListener(_onAnyInputChanged)
        ..dispose();
    }
    super.dispose();
  }

  void _onAnyInputChanged() {
    setState(() {});
    ref.read(loginControllerProvider.notifier).clearLastError();
  }

  // ---------------------------------------------------------------------------
  // Validation
  // ---------------------------------------------------------------------------

  bool get _canSubmit {
    final state = ref.read(loginControllerProvider);
    if (state.isSubmitting) return false;

    final s = AppLocalizations.of(context);
    final mode = state.mode;

    // Check if fields pass validation
    if (mode == LoginMode.email) {
      final emailValid = LoginValidators.email(_emailCtrl.text, s) == null;
      final passwordValid =
          LoginValidators.password(_passwordCtrl.text, s) == null;
      return emailValid && passwordValid;
    } else {
      final empCodeValid =
          LoginValidators.employeeCode(_employeeCodeCtrl.text, s) == null;
      final loginCodeValid =
          LoginValidators.loginCode(_loginCodeCtrl.text, s) == null;
      return empCodeValid && loginCodeValid;
    }
  }

  bool _validate(AppLocalizations s, LoginMode mode) {
    String? idErr;
    String? secretErr;

    if (mode == LoginMode.email) {
      idErr = LoginValidators.email(_emailCtrl.text.trim(), s);
      secretErr = LoginValidators.password(_passwordCtrl.text.trim(), s);
    } else {
      idErr = LoginValidators.employeeCode(_employeeCodeCtrl.text.trim(), s);
      secretErr = LoginValidators.loginCode(_loginCodeCtrl.text.trim(), s);
    }

    setState(() {
      _identifierError = idErr;
      _secretError = secretErr;
    });

    // Show top toast for validation errors
    if (idErr != null) {
      LoginTopToast.show(
        context,
        severity: ToastSeverity.error,
        message: idErr,
      );
      return false;
    }
    if (secretErr != null) {
      LoginTopToast.show(
        context,
        severity: ToastSeverity.error,
        message: secretErr,
      );
      return false;
    }

    return true;
  }

  void _clearInlineErrors() {
    if (_identifierError == null && _secretError == null) return;
    setState(() {
      _identifierError = null;
      _secretError = null;
    });
  }

  // ---------------------------------------------------------------------------
  // Submit
  // ---------------------------------------------------------------------------

  Future<void> _onSignInPressed() async {
    final s = context.l10n;
    final mode = ref.read(loginControllerProvider).mode;
    FocusScope.of(context).unfocus();

    if (!_validate(s, mode)) return;

    // Retrieve device token (returns empty string if unavailable)
    final deviceToken = await _getDeviceToken();

    final credentials = mode == LoginMode.email
        ? EmailPasswordCredentials(
            email: LoginValidators.normaliseEmail(_emailCtrl.text),
            password: _passwordCtrl.text,
            fcm_token: deviceToken,
          )
        : EmployeeCodeCredentials(
            employeeCode: LoginValidators.normaliseCode(_employeeCodeCtrl.text),
            loginCode: LoginValidators.normaliseCode(_loginCodeCtrl.text),
            fcm_token: deviceToken,
          );

    await ref.read(loginControllerProvider.notifier).submit(credentials);
    // Success path: the root widget reacts to `authSessionControllerProvider`.
    // Failure path: rendered by the `ref.listen` in `build`.
  }

  /// Retrieve the device token from shared preferences.
  /// Returns the saved FCM token if available, or empty string if null.
  /// The backend validates token availability and handles accordingly.
  Future<String> _getDeviceToken() async {
    final token = await DeviceTokenService.getToken();
    if (token == null) {
      debugPrint(
        '[DeviceToken] Token unavailable during login — background validation will handle',
      );
      return '';
    }
    return token;
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginControllerProvider);
    final controller = ref.read(loginControllerProvider.notifier);

    // Render API failures as toast/dialog. `ref.listen` is the right
    // shape for one-off side effects (per riverpod-guidelines).
    ref.listen(loginControllerProvider, (prev, next) {
      final value = next.submission;
      if (value is AsyncError) {
        final err = value.error;
        if (err != null) _surfaceError(err);
      }
    });

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1025), // Dark purple top
              Color(0xFF0D0612), // Almost black purple bottom
            ],
          ),
        ),
        child: SafeArea(
          child: AutofillGroup(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.vertical -
                      48,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Spacer(),
                      _Card(
                        state: state,
                        identifierError: _identifierError,
                        secretError: _secretError,
                        emailCtrl: _emailCtrl,
                        passwordCtrl: _passwordCtrl,
                        employeeCodeCtrl: _employeeCodeCtrl,
                        loginCodeCtrl: _loginCodeCtrl,
                        onModeChanged: (m) {
                          _clearInlineErrors();
                          controller.selectMode(m);
                        },
                        onTogglePassword: controller.togglePasswordVisibility,
                        onSubmit: _canSubmit ? _onSignInPressed : null,
                      ),
                      const SizedBox(height: 8),
                      const LoginAdminFooter(),
                      const Spacer(),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _surfaceError(Object error) {
    final s = context.l10n;
    final mode = ref.read(loginControllerProvider).mode;
    final copy = LoginErrorCopy.from(error: error, s: s, mode: mode);

    switch (copy.channel) {
      case LoginErrorChannel.toast:
        LoginTopToast.show(
          context,
          severity: ToastSeverity.error,
          message: copy.message,
        );
      case LoginErrorChannel.dialog:
        LoginStateDialog.show(
          context,
          title: copy.title ?? s.loginErrorGeneric,
          message: copy.message,
        );
    }
  }
}

/// The card body sits in a private widget so the long parameter list
/// stays out of `_LoginScreenState.build`.
class _Card extends StatelessWidget {
  final LoginUiState state;
  final String? identifierError;
  final String? secretError;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final TextEditingController employeeCodeCtrl;
  final TextEditingController loginCodeCtrl;
  final ValueChanged<LoginMode> onModeChanged;
  final VoidCallback onTogglePassword;
  final VoidCallback? onSubmit;

  const _Card({
    required this.state,
    required this.identifierError,
    required this.secretError,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.employeeCodeCtrl,
    required this.loginCodeCtrl,
    required this.onModeChanged,
    required this.onTogglePassword,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final isEmail = state.mode == LoginMode.email;
    final identifierCtrl = isEmail ? emailCtrl : employeeCodeCtrl;
    final secretCtrl = isEmail ? passwordCtrl : loginCodeCtrl;

    return Container(
      decoration: BoxDecoration(
        color: ColorPalette.loginCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColorPalette.loginCardBorder, width: 1),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: AuthLogo()),
          const SizedBox(height: 20),
          _Heading(),
          const SizedBox(height: 28),
          const _Divider(),
          const SizedBox(height: 28),
          LoginModeTabs(selected: state.mode, onChanged: onModeChanged),
          const SizedBox(height: 24),
          IdentifierField(
            controller: identifierCtrl,
            mode: state.mode,
            errorText: identifierError,
            autofocus: true,
            onChanged: (_) {},
            onSubmitted: () => FocusScope.of(context).nextFocus(),
          ),
          const SizedBox(height: 20),
          SecretField(
            controller: secretCtrl,
            mode: state.mode,
            obscure: state.obscurePassword,
            errorText: secretError,
            onToggleObscure: onTogglePassword,
            onChanged: (_) {},
            onSubmitted: () => onSubmit?.call(),
          ),
          const SizedBox(height: 20),
          _SignInButton(
            label: s.loginAccessButton,
            onPressed: onSubmit,
            isLoading: state.isSubmitting,
          ),
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    return Column(
      children: [
        Text(
          s.loginWelcomeTitle,
          textAlign: TextAlign.center,
          style: TypographyManager.headlineMedium.copyWith(
            color: ColorPalette.loginTitle,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          s.loginWelcomeSubtitle,
          textAlign: TextAlign.center,
          style: TypographyManager.bodyMedium.copyWith(
            color: ColorPalette.loginSubtitle,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: ColorPalette.loginDivider);
  }
}

class _SignInButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const _SignInButton({
    required this.label,
    required this.onPressed,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDisabled
              ? ColorPalette.loginButtonDisabledBg
              : ColorPalette.primary,
          foregroundColor: isDisabled
              ? ColorPalette.loginButtonDisabledFg
              : ColorPalette.white,
          disabledBackgroundColor: ColorPalette.loginButtonDisabledBg,
          disabledForegroundColor: ColorPalette.loginButtonDisabledFg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: ColorPalette.white,
                ),
              )
            : Text(
                label,
                style: TypographyManager.titleMedium.copyWith(
                  color: isDisabled
                      ? ColorPalette.loginButtonDisabledFg
                      : ColorPalette.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
