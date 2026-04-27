import 'package:flutter/foundation.dart';

import '../../l10n/generated/app_localizations.dart';
import '../i18n/locale_aware_strings.dart';

enum AppErrorType {
  network,
  timeout,
  unauthorized,
  forbidden,
  notFound,
  serverError,
  validation,
  unknown,
}

/// Domain-level error. Crucially this no longer caches a localized message —
/// it stores the [AppErrorType] and resolves the user-facing string lazily
/// via [localizedMessage]. That way an error created on locale=en still
/// displays in Spanish if the user switches before we surface it.
class AppException implements Exception {
  final AppErrorType type;
  final String? code;
  final dynamic originalError;

  /// Optional override (e.g. a server-supplied validation message that's
  /// already localized). When null we fall through to the locale-aware
  /// dictionary in [localizedMessage].
  final String? overrideMessage;

  const AppException({
    required this.type,
    this.code,
    this.originalError,
    this.overrideMessage,
  });

  /// Resolve against the supplied [AppLocalizations]. Use this from any
  /// widget that has a `BuildContext`.
  String localizedMessage(AppLocalizations s) {
    final override = overrideMessage;
    if (override != null) return override;
    switch (type) {
      case AppErrorType.network:
        return s.networkError;
      case AppErrorType.timeout:
        return s.timeoutError;
      case AppErrorType.unauthorized:
        return s.unauthorizedError;
      case AppErrorType.forbidden:
        return s.forbiddenError;
      case AppErrorType.notFound:
        return s.notFoundError;
      case AppErrorType.serverError:
        return s.serverError;
      case AppErrorType.validation:
        return s.validationError;
      case AppErrorType.unknown:
        return s.unknownError;
    }
  }

  /// Convenience for non-context callers (services, repositories,
  /// notification handlers). Resolves through [LocaleAwareStrings].
  String get localizedMessageFromActiveLocale =>
      localizedMessage(LocaleAwareStrings.instance.strings);

  @override
  String toString() => 'AppException(type: $type, code: $code)';
}

abstract class ErrorHandler {
  static AppException handle(dynamic error) {
    if (error is AppException) return error;

    debugPrint('[ErrorHandler] $error');

    if (error == null) {
      return const AppException(type: AppErrorType.unknown);
    }

    final message = error.toString().toLowerCase();

    if (message.contains('socketexception') ||
        message.contains('network') ||
        message.contains('connection')) {
      return const AppException(type: AppErrorType.network);
    }

    if (message.contains('timeout')) {
      return const AppException(type: AppErrorType.timeout);
    }

    if (message.contains('401') || message.contains('unauthorized')) {
      return const AppException(type: AppErrorType.unauthorized);
    }

    if (message.contains('403') || message.contains('forbidden')) {
      return const AppException(type: AppErrorType.forbidden);
    }

    if (message.contains('404') || message.contains('not found')) {
      return const AppException(type: AppErrorType.notFound);
    }

    if (message.contains('500') || message.contains('server')) {
      return const AppException(type: AppErrorType.serverError);
    }

    return AppException(
      type: AppErrorType.unknown,
      originalError: error,
    );
  }
}
