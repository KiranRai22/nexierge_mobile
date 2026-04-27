import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../error/error_handler.dart';
import 'api_endpoints.dart';

/// Single configured [Dio] instance — the chassis for every backend call.
///
/// Centralised so we can attach the bearer token, log in debug, and
/// translate `DioException` → `AppException` in one place. UI must NEVER
/// import this directly; data sources / repositories sit between.
Dio _buildDio({String? authToken}) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: APIEndpoints.connectTimeout,
      receiveTimeout: APIEndpoints.receiveTimeout,
      sendTimeout: APIEndpoints.sendTimeout,
      contentType: APIEndpoints.contentTypeJson,
      responseType: ResponseType.json,
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        if (authToken != null && authToken.isNotEmpty) {
          options.headers[APIEndpoints.authorizationHeader] =
              '${APIEndpoints.bearerPrefix}$authToken';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        if (kDebugMode) {
          debugPrint(
            '[ApiClient] ${error.requestOptions.method} '
            '${error.requestOptions.uri} → ${error.message}',
          );
        }
        handler.next(error);
      },
    ),
  );

  return dio;
}

/// Riverpod accessor. The token-less client is the default; data sources
/// for authenticated endpoints will eventually depend on a token-aware
/// variant (`authedDioProvider`) once the session is wired in.
final dioProvider = Provider<Dio>((ref) => _buildDio());

/// Translates a [DioException] into the project's `AppException`. Keeps
/// HTTP semantics out of repositories and UI.
AppException mapDioError(DioException error) {
  final response = error.response;
  final status = response?.statusCode;

  // Pull a server-supplied message when present so we don't override real
  // backend error copy with a generic localized fallback.
  final serverMessage = _readMessage(response?.data);

  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return const AppException(type: AppErrorType.timeout);
    case DioExceptionType.connectionError:
      return const AppException(type: AppErrorType.network);
    case DioExceptionType.badCertificate:
    case DioExceptionType.cancel:
    case DioExceptionType.unknown:
    case DioExceptionType.badResponse:
      return _fromStatus(status, serverMessage);
  }
}

AppException _fromStatus(int? status, String? message) {
  if (status == null) {
    return AppException(type: AppErrorType.unknown, overrideMessage: message);
  }
  if (status == 401) {
    return AppException(
      type: AppErrorType.unauthorized,
      overrideMessage: message,
    );
  }
  if (status == 403) {
    return AppException(
      type: AppErrorType.forbidden,
      overrideMessage: message,
    );
  }
  if (status == 404) {
    return AppException(
      type: AppErrorType.notFound,
      overrideMessage: message,
    );
  }
  if (status >= 400 && status < 500) {
    return AppException(
      type: AppErrorType.validation,
      overrideMessage: message,
    );
  }
  return AppException(
    type: AppErrorType.serverError,
    overrideMessage: message,
  );
}

String? _readMessage(dynamic data) {
  if (data is Map) {
    final m = data['message'] ?? data['error'] ?? data['detail'];
    if (m is String && m.isNotEmpty) return m;
  }
  return null;
}
