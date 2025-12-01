import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import '/others/utils/api.dart';
import '/others/errors/app_error_handler.dart';

class AuthService {
  final GetStorage _box = GetStorage();

  Map<String, String> _headers({bool withAuth = false}) {
    final token = _box.read<String>('access');
    return {
      'Content-Type': 'application/json',
      if (withAuth && token != null && token.isNotEmpty)
        'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> _postJson(
    String url,
    Map<String, dynamic> body, {
    bool withAuth = false,
  }) async {
    final uri = Uri.parse(url);
    final headers = _headers(withAuth: withAuth);
    final payload = jsonEncode(body);

    debugPrint('➡️ POST $uri');
    debugPrint('   HEADERS: $headers');
    debugPrint('   BODY: $payload');

    try {
      final res = await http
          .post(uri, headers: headers, body: payload)
          .timeout(const Duration(seconds: 20));

      debugPrint('🟢 POST $uri → ${res.statusCode}');
      debugPrint('   RESP BODY: ${res.body}');

      final decoded = res.body.isEmpty ? {} : jsonDecode(res.body);

      return {
        'statusCode': res.statusCode,
        'data': decoded,
      };
    } catch (e, st) {
      debugPrint('❌ _postJson error for $url: $e\n$st');
      throw AppException.from(e, st);
    }
  }

  /// STEP 1: Begin registration (send OTP)
  /// POST /auth/register/init
  Future<Map<String, dynamic>> register({
    required String api,
    required String mail,
    required String pass,
    required String phone,
    required String name,
  }) {
    return _postJson(
      api, // Api.register
      {
        "email": mail,
        "phone_number": phone,
        "password": pass,
        "confirm_password": pass,
        "full_name": name,
        "address": "", // TODO: attach real address when you add it in UI
      },
    );
  }

  /// STEP 2: Complete registration with OTP
  /// POST /auth/register/verify
  Future<Map<String, dynamic>> verifyRegistration({
    required String sessionId,
    required String code,
  }) {
    return _postJson(
      Api.regVerify,
      {
        "session_id": sessionId,
        "code": code,
      },
    );
  }

  /// STEP 1: Login (email/phone + password) => sends OTP
  /// POST /auth/login
  Future<Map<String, dynamic>> login({
    required String api,
    required String mail,
    required String pass,
  }) {
    return _postJson(
      api, // Api.login
      {
        "email": mail,
        "password": pass,
      },
    );
  }

  /// STEP 2: Complete login with OTP
  /// POST /auth/login/verify
  Future<Map<String, dynamic>> verifyLogin({
    required String sessionId,
    required String code,
  }) {
    return _postJson(
      Api.logVerify,
      {
        "session_id": sessionId,
        "code": code,
      },
    );
  }

  /// Refresh access token using stored refresh token
  /// POST /auth/refresh
  Future<Map<String, dynamic>> refreshAccessToken() async {
    final refresh = _box.read<String>('refresh')?.toString();

    if (refresh == null || refresh.isEmpty) {
      throw AppException(
        type: AppErrorType.unauthorized,
        message: 'No refresh token found in storage',
      );
    }

    return _postJson(
      Api.refreshToken,
      {
        "refresh": refresh,
      },
      withAuth: false,
    );
  }

  /// Forgot password - init (send OTP)
  /// POST /auth/password/forgot/init
  Future<Map<String, dynamic>> forgotPasswordInit({
    required String identifier,
  }) {
    return _postJson(
      Api.forgotPass,
      {
        "identifier": identifier,
      },
    );
  }

  /// Forgot password - complete (with OTP + new password)
  /// POST /auth/password/forgot/complete
  Future<Map<String, dynamic>> forgotPasswordComplete({
    required String sessionId,
    required String code,
    required String newPassword,
    required String confirmPassword,
  }) {
    return _postJson(
      Api.forgotComplete,
      {
        "session_id": sessionId,
        "code": code,
        "new_password": newPassword,
        "confirm_password": confirmPassword,
      },
    );
  }

  /// Change password for logged-in user
  /// POST /auth/change-password
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) {
    return _postJson(
      Api.resetPass,
      {
        "current_password": currentPassword,
        "new_password": newPassword,
        "confirm_new_password": confirmNewPassword,
      },
      withAuth: true,
    );
  }
}
