import '../../../../core/error/error_handler.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/login_credentials.dart';
import '../../domain/exceptions/auth_exception.dart';

/// What surface should host the error.
enum LoginErrorChannel { toast, dialog }

class LoginErrorCopy {
  final LoginErrorChannel channel;

  /// Title for the dialog channel; ignored for toast.
  final String? title;

  /// Body for both channels.
  final String message;

  const LoginErrorCopy._({
    required this.channel,
    required this.message,
    this.title,
  });

  /// Map any thrown failure into user-facing copy. Lives outside the
  /// widget so unit tests can pin the contract per spec §10 / §11.
  factory LoginErrorCopy.from({
    required Object error,
    required AppLocalizations s,
    required LoginMode mode,
  }) {
    if (error is AuthException) {
      switch (error.reason) {
        case AuthFailureReason.invalidCredentials:
          return LoginErrorCopy._(
            channel: LoginErrorChannel.toast,
            message: error.serverMessage ??
                (mode == LoginMode.email
                    ? s.loginErrorInvalidEmail
                    : s.loginErrorInvalidCode),
          );
        case AuthFailureReason.codeExpired:
          return LoginErrorCopy._(
            channel: LoginErrorChannel.toast,
            message: error.serverMessage ?? s.loginErrorCodeExpired,
          );
        case AuthFailureReason.pendingReview:
          return LoginErrorCopy._(
            channel: LoginErrorChannel.dialog,
            title: s.loginErrorPendingReviewTitle,
            message: error.serverMessage ?? s.loginErrorPendingReviewBody,
          );
        case AuthFailureReason.rejected:
          return LoginErrorCopy._(
            channel: LoginErrorChannel.dialog,
            title: s.loginErrorRejectedTitle,
            message: error.serverMessage ?? s.loginErrorRejectedBody,
          );
        case AuthFailureReason.disabled:
          return LoginErrorCopy._(
            channel: LoginErrorChannel.dialog,
            title: s.loginErrorDisabledTitle,
            message: error.serverMessage ?? s.loginErrorDisabledBody,
          );
        case AuthFailureReason.inactiveHotel:
          return LoginErrorCopy._(
            channel: LoginErrorChannel.dialog,
            title: s.loginErrorInactiveHotelTitle,
            message: error.serverMessage ?? s.loginErrorInactiveHotelBody,
          );
        case AuthFailureReason.generic:
          return LoginErrorCopy._(
            channel: LoginErrorChannel.toast,
            message: error.serverMessage ?? s.loginErrorGeneric,
          );
      }
    }

    if (error is AppException) {
      // Network / timeout / 5xx → "We couldn't sign you in right now".
      if (error.type == AppErrorType.network ||
          error.type == AppErrorType.timeout) {
        return LoginErrorCopy._(
          channel: LoginErrorChannel.toast,
          message: error.overrideMessage ?? s.loginErrorSignInFailed,
        );
      }
      return LoginErrorCopy._(
        channel: LoginErrorChannel.toast,
        message: error.overrideMessage ?? error.localizedMessage(s),
      );
    }

    return LoginErrorCopy._(
      channel: LoginErrorChannel.toast,
      message: s.loginErrorSignInFailed,
    );
  }
}
