// app_error_handler.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import 'app_error_messages.dart'; // <- central messages

// ----------------- AppErrorType + AppException -----------------

enum AppErrorType {
  network,
  timeout,
  server,
  notFound,
  empty,
  parsing,
  unauthorized,
  unknown,
}

class AppException implements Exception {
  final AppErrorType type;
  final String message; // internal message (can be logged)
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

  /// Public user-facing message (comes from central file)
  String toUserMessage() {
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

// ----------------- AppHttp (status mapping + JSON) -----------------

class AppHttp {
  AppHttp._();

  static Future<http.Response> get(
    Uri uri, {
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    try {
      final res = await http
          .get(uri, headers: headers)
          .timeout(timeout);

      _validateResponse(res);
      return res;
    } on Exception catch (e, st) {
      throw AppException.from(e, st);
    }
  }

  static void _validateResponse(http.Response res) {
    if (res.statusCode == 401) {
      throw AppException(
        type: AppErrorType.unauthorized,
        message: 'Unauthorized',
        raw: res,
      );
    }

    if (res.statusCode == 404) {
      throw AppException(
        type: AppErrorType.notFound,
        message: 'Resource not found',
        raw: res,
      );
    }

    if (res.statusCode >= 500) {
      throw AppException(
        type: AppErrorType.server,
        message: 'Server error (${res.statusCode})',
        raw: res,
      );
    }

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw AppException(
        type: AppErrorType.server,
        message: 'Request failed (HTTP ${res.statusCode})',
        raw: res,
      );
    }

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

// ----------------- AppErrorHandler (UI) -----------------

class AppErrorHandler {
  AppErrorHandler._();

  static void handle(
    Object error, {
    StackTrace? stackTrace,
    bool showUi = true,
  }) {
    final appEx =
        error is AppException ? error : AppException.from(error, stackTrace);

    debugPrint('❌ AppError: $appEx');
    if (stackTrace != null) {
      debugPrint(stackTrace.toString());
    }

    if (showUi) {
      _showErrorBox(appEx);
    }
  }

  static void _showErrorBox(AppException ex) {
    Get.snackbar(
      'Oops!',
      ex.toUserMessage(), // 🔥 now fully controlled via AppErrorMessages
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      backgroundColor: Colors.red.withOpacity(0.15),
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  static Future<T?> run<T>(Future<T> Function() action,
      {bool showUi = true}) async {
    try {
      return await action();
    } catch (e, st) {
      handle(e, stackTrace: st, showUi: showUi);
      return null;
    }
  }
}
