

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Change this one line when you move to a real backend.
const String kApiBaseUrl = 'https://jsonplaceholder.typicode.com';

// ============================================================
// ERROR TYPE
// ============================================================

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  /// Turns anything (DioException, ApiException, other errors) into an
  /// ApiException with a message that is safe to show to the user.
  factory ApiException.from(Object error) {
    if (error is ApiException) return error;
    if (error is DioException) {
      final inner = error.error;
      if (inner is ApiException) return inner;
      return _fromDio(error);
    }
    return ApiException(error.toString().replaceFirst('Exception: ', ''));
  }

  static ApiException _fromDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          'Connection timed out. Check your internet and try again.',
        );
      case DioExceptionType.connectionError:
        return const ApiException(
          'No internet connection. Connect and try again.',
        );
      case DioExceptionType.badResponse:
        {
          final code = e.response?.statusCode;
          if (code != null && code >= 500) {
            return ApiException('Server error ($code). Try again.',
                statusCode: code);
          }
          return ApiException('Request failed (${code ?? 'unknown'}).',
              statusCode: code);
        }
      case DioExceptionType.cancel:
        return const ApiException('Request cancelled.');
      case DioExceptionType.badCertificate:
        return const ApiException('Secure connection failed.');
      case DioExceptionType.unknown:
        if (e.error is SocketException) {
          return const ApiException(
            'No internet connection. Connect and try again.',
          );
        }
        return const ApiException('Something went wrong. Please try again.');
      case DioExceptionType.transformTimeout:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  /// toString returns just the message, so existing code that does
  /// error.toString() keeps showing clean text.
  @override
  String toString() => message;
}

// ============================================================
// 1. AUTH INTERCEPTOR
// ============================================================

/// Adds `Authorization: Bearer <token>` to every request when a token exists.
/// jsonplaceholder needs no token, so by default nothing is added. When you
/// have a real backend, pass a reader:
///   AuthInterceptor(tokenReader: () async => await storage.read('token'))
class AuthInterceptor extends Interceptor {
  AuthInterceptor({this.tokenReader});

  final Future<String?> Function()? tokenReader;

  @override
  Future<void> onRequest(
      RequestOptions options,
      RequestInterceptorHandler handler,
      ) async {
    final token = await tokenReader?.call();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

// ============================================================
// 2. LOGGING INTERCEPTOR
// ============================================================

/// Debug-only. Logs method, url, status code and duration.
/// Request/response BODIES are deliberately not logged because they contain
/// CNIC, salary and bank details.
class LoggingInterceptor extends Interceptor {
  static const _startKey = 'startedAtMs';

  int _elapsed(RequestOptions o) {
    final start = o.extra[_startKey] as int?;
    return start == null
        ? 0
        : DateTime.now().millisecondsSinceEpoch - start;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startKey] = DateTime.now().millisecondsSinceEpoch;
    if (kDebugMode) {
      debugPrint('[API] --> ${options.method} ${options.uri}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      final o = response.requestOptions;
      debugPrint(
        '[API] <-- ${response.statusCode} ${o.method} ${o.uri} '
            '(${_elapsed(o)} ms)',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      final o = err.requestOptions;
      debugPrint(
        '[API] <-- ERROR ${err.type.name} ${o.method} ${o.uri} '
            '(${_elapsed(o)} ms)',
      );
    }
    handler.next(err);
  }
}

// ============================================================
// 3. RETRY INTERCEPTOR
// ============================================================

/// Retries a request when the network fails (no connection / timeout).
/// Only GET, HEAD, PUT and DELETE are retried. POST is never retried, so an
/// employee or department can't be created twice by accident.
/// Skip retry for one call with: Options(extra: {'noRetry': true})
class RetryInterceptor extends Interceptor {
  RetryInterceptor(
      this._dio, {
        this.maxRetries = 1,
        this.delay = const Duration(milliseconds: 600),
      });

  final Dio _dio;
  final int maxRetries;
  final Duration delay;

  static const _retryableMethods = {'GET', 'HEAD', 'PUT', 'DELETE'};

  bool _shouldRetry(DioException e) {
    final o = e.requestOptions;
    if (o.extra['noRetry'] == true) return false;
    if (!_retryableMethods.contains(o.method.toUpperCase())) return false;

    return e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError;
  }

  @override
  Future<void> onError(
      DioException err,
      ErrorInterceptorHandler handler,
      ) async {
    final attempt = (err.requestOptions.extra['retryCount'] as int?) ?? 0;

    if (attempt < maxRetries && _shouldRetry(err)) {
      await Future.delayed(delay);
      err.requestOptions.extra['retryCount'] = attempt + 1;
      try {
        final response = await _dio.fetch(err.requestOptions);
        return handler.resolve(response);
      } on DioException catch (e) {
        return handler.next(e);
      }
    }

    handler.next(err);
  }
}

// ============================================================
// 4. ERROR MAPPER INTERCEPTOR
// ============================================================

/// Last in the chain: wraps every failure in an ApiException so the rest of
/// the app only ever sees a readable message.
class ErrorMapperInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // already mapped (e.g. a retried request failed again)
    if (err.error is ApiException) {
      handler.next(err);
      return;
    }

    final apiError = ApiException._fromDio(err);
    handler.next(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: apiError,
        stackTrace: err.stackTrace,
        message: apiError.message,
      ),
    );
  }
}

// ============================================================
// PROVIDER
// ============================================================

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: kApiBaseUrl,
      connectTimeout: const Duration(seconds: 8),
      sendTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
      contentType: Headers.jsonContentType,
      headers: {'Accept': 'application/json'},
      // default validateStatus: only 2xx counts as success, everything
      // else becomes a DioException(badResponse)
    ),
  );

  dio.interceptors.addAll([
    AuthInterceptor(),
    LoggingInterceptor(),
    RetryInterceptor(dio),
    ErrorMapperInterceptor(),
  ]);

  return dio;
});



