import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'app_error_messages.dart';

// --------------------------------------------------
// 1) Error types + AppException
// --------------------------------------------------

enum AppErrorType {
  network,
  timeout,
  server,
  notFound,
  empty,
  parsing,
  unauthorized,
  unknown,
  validation,
}

class AppException implements Exception {
  final AppErrorType type;
  final String message; // backend / internal message
  final Object? raw;
  final StackTrace? stackTrace;

  AppException({
    required this.type,
    required this.message,
    this.raw,
    this.stackTrace,
  });

  @override
  String toString() => 'AppException($type): $message';

  /// Public user-facing message
  String toUserMessage() {
    // If backend gave us something meaningful, show that for most errors
    if (message.isNotEmpty &&
        type != AppErrorType.network &&
        type != AppErrorType.timeout &&
        type != AppErrorType.parsing) {
      return message;
    }

    switch (type) {
      case AppErrorType.network:
        return AppErrorMessages.network;
      case AppErrorType.timeout:
        return AppErrorMessages.timeout;
      case AppErrorType.server:
        return AppErrorMessages.server;
      case AppErrorType.notFound:
        return AppErrorMessages.notFound;
      case AppErrorType.empty:
        return AppErrorMessages.empty;
      case AppErrorType.parsing:
        return AppErrorMessages.parsing;
      case AppErrorType.unauthorized:
        return AppErrorMessages.unauthorized;
      case AppErrorType.unknown:
        return AppErrorMessages.unknown;
      case AppErrorType.validation:
        return AppErrorMessages.validation;
    }
  }

  factory AppException.from(Object error, [StackTrace? st]) {
    if (error is AppException) return error;

    if (error is SocketException) {
      return AppException(
        type: AppErrorType.network,
        message: 'No internet connection',
        raw: error,
        stackTrace: st,
      );
    }

    if (error is TimeoutException) {
      return AppException(
        type: AppErrorType.timeout,
        message: 'Request timed out',
        raw: error,
        stackTrace: st,
      );
    }

    if (error is FormatException) {
      return AppException(
        type: AppErrorType.parsing,
        message: 'Failed to parse response',
        raw: error,
        stackTrace: st,
      );
    }

    return AppException(
      type: AppErrorType.unknown,
      message: error.toString(),
      raw: error,
      stackTrace: st,
    );
  }
}

// --------------------------------------------------
// 2) AppHttp – common HTTP client + status mapping
// --------------------------------------------------

class AppHttp {
  AppHttp._();

  // Simple GET wrapper
  static Future<http.Response> get(
    Uri uri, {
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    try {
      final res = await http.get(uri, headers: headers).timeout(timeout);

      _validateResponse(res);
      return res;
    } on Exception catch (e, st) {
      throw AppException.from(e, st);
    }
  }

  // Simple POST wrapper (handy for auth)
  static Future<http.Response> post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    try {
      final finalHeaders = <String, String>{
        'Content-Type': 'application/json',
        if (headers != null) ...headers,
      };

      final encodedBody =
          body is String ? body : jsonEncode(body ?? <String, dynamic>{});

      final res = await http
          .post(uri, headers: finalHeaders, body: encodedBody)
          .timeout(timeout);

      _validateResponse(res);
      return res;
    } on Exception catch (e, st) {
      throw AppException.from(e, st);
    }
  }

  // 🔥 Central response validation
  static void _validateResponse(http.Response res) {
    // -------------- 401 Unauthorized (e.g. wrong password) --------------
    if (res.statusCode == 401) {
      String msg = 'Unauthorized';

      try {
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) {
          if (decoded['detail'] is String) {
            msg = decoded['detail'] as String;
          } else {
            // fallback: pick first list error
            for (final value in decoded.values) {
              if (value is List && value.isNotEmpty && value[0] is String) {
                msg = value[0] as String;
                break;
              }
            }
          }
        }
      } catch (_) {
        // ignore, keep default
      }

      throw AppException(
        type: AppErrorType.unauthorized,
        message: msg, // e.g. "Incorrect email or password"
        raw: res,
      );
    }

    // -------------- 404 Not Found --------------
    if (res.statusCode == 404) {
      throw AppException(
        type: AppErrorType.notFound,
        message: 'Resource not found',
        raw: res,
      );
    }

    // -------------- 5xx Server Errors --------------
    if (res.statusCode >= 500) {
      throw AppException(
        type: AppErrorType.server,
        message: 'Server error (${res.statusCode})',
        raw: res,
      );
    }

    // -------------- 400 Validation Errors --------------
    if (res.statusCode == 400) {
      String msg = 'Request failed (400)';

      try {
        final decoded = jsonDecode(res.body);

        if (decoded is Map<String, dynamic>) {
          // Prefer "detail"
          if (decoded['detail'] is String) {
            msg = decoded['detail'] as String;
          } else {
            // Else take first ["error message"] in any field
            for (final value in decoded.values) {
              if (value is List && value.isNotEmpty && value[0] is String) {
                msg = value[0] as String;
                break;
              }
            }
          }
        }
      } catch (_) {
        // ignore, keep default msg
      }

      throw AppException(
        type: AppErrorType.server,
        message: msg, // e.g. "Email is already registered."
        raw: res,
      );
    }

    // -------------- Other non-2xx --------------
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw AppException(
        type: AppErrorType.server,
        message: 'Request failed (HTTP ${res.statusCode})',
        raw: res,
      );
    }

    // -------------- Empty body --------------
    if (res.body.isEmpty) {
      throw AppException(
        type: AppErrorType.empty,
        message: 'Empty response from server',
        raw: res,
      );
    }
  }

  static T parseJsonObject<T>(
    String body,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    try {
      final decoded = jsonDecode(body);

      if (decoded is! Map) {
        throw const FormatException('Response is not a JSON object');
      }

      return fromJson(
        Map<String, dynamic>.from(decoded),
      );
    } on Exception catch (e, st) {
      throw AppException.from(e, st);
    }
  }
}

// --------------------------------------------------
// 3) AppErrorHandler – logging + SnackBar UI
// --------------------------------------------------

class AppErrorHandler {
  AppErrorHandler._();

  static void handle(
    Object error, {
    StackTrace? stackTrace,
    bool showUi = true,
    BuildContext? context,
  }) {
    final appEx =
        error is AppException ? error : AppException.from(error, stackTrace);

    debugPrint('❌ AppError: $appEx');
    if (stackTrace != null) {
      debugPrint(stackTrace.toString());
    }

    if (showUi && context != null) {
      _showErrorBox(context, appEx);
    }
  }

  static void _showErrorBox(BuildContext context, AppException ex) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(ex.toUserMessage()),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
  }

  /// Wrapper to run async code with automatic error handling
  static Future<T?> run<T>(
    Future<T> Function() action, {
    bool showUi = true,
    BuildContext? context,
  }) async {
    try {
      return await action();
    } catch (e, st) {
      handle(e, stackTrace: st, showUi: showUi, context: context);
      return null;
    }
  }
}
