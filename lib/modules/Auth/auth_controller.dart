import 'package:flutter/material.dart';
import '/modules/auth/auth_service.dart';
import '/others/errors/app_error_handler.dart';

class AuthController {
  final AuthService _authService = AuthService();

  /// Registration init
  Future<Map<String, dynamic>> userRegistration({
    required String api,
    required String mail,
    required String pass,
    required String phone,
    required String name,
  }) async {
    try {
      final res = await _authService.register(
        api: api,
        mail: mail,
        pass: pass,
        phone: phone,
        name: name,
      );
      debugPrint('Register(init) Response: $res');
      return res;
    } catch (e, st) {
      debugPrint('userRegistration error: $e\n$st');
      throw AppException.from(e, st);
    }
  }

  /// Registration verify
  Future<Map<String, dynamic>> verifyRegistration({
    required String sessionId,
    required String code,
  }) async {
    try {
      final res = await _authService.verifyRegistration(
        sessionId: sessionId,
        code: code,
      );
      debugPrint('Register(verify) Response: $res');
      return res;
    } catch (e, st) {
      debugPrint('verifyRegistration error: $e\n$st');
      throw AppException.from(e, st);
    }
  }

  /// Login init
  Future<Map<String, dynamic>> userLogin({
    required String api,
    required String mail,
    required String pass,
  }) async {
    try {
      final res = await _authService.login(
        api: api,
        mail: mail.trim(),
        pass: pass,
      );
      debugPrint('Login(init) Response: $res');
      return res;
    } catch (e, st) {
      debugPrint('userLogin error: $e\n$st');
      throw AppException.from(e, st);
    }
  }

  /// Login verify
  Future<Map<String, dynamic>> verifyLogin({
    required String sessionId,
    required String code,
  }) async {
    try {
      final res = await _authService.verifyLogin(
        sessionId: sessionId,
        code: code,
      );
      debugPrint('Login(verify) Response: $res');
      return res;
    } catch (e, st) {
      debugPrint('verifyLogin error: $e\n$st');
      throw AppException.from(e, st);
    }
  }

  Future<Map<String, dynamic>> refreshAccessToken() async {
    try {
      final res = await _authService.refreshAccessToken();
      debugPrint('Refresh Response: $res');
      return res;
    } catch (e, st) {
      debugPrint('refreshAccessToken error: $e\n$st');
      throw AppException.from(e, st);
    }
  }

  Future<Map<String, dynamic>> forgotPasswordInit({
    required String identifier,
  }) async {
    try {
      final res = await _authService.forgotPasswordInit(
        identifier: identifier,
      );
      debugPrint('ForgotPassword(init) Response: $res');
      return res;
    } catch (e, st) {
      debugPrint('forgotPasswordInit error: $e\n$st');
      throw AppException.from(e, st);
    }
  }

  Future<Map<String, dynamic>> forgotPasswordComplete({
    required String sessionId,
    required String code,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final res = await _authService.forgotPasswordComplete(
        sessionId: sessionId,
        code: code,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
      debugPrint('ForgotPassword(complete) Response: $res');
      return res;
    } catch (e, st) {
      debugPrint('forgotPasswordComplete error: $e\n$st');
      throw AppException.from(e, st);
    }
  }

  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    try {
      final res = await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmNewPassword: confirmNewPassword,
      );
      debugPrint('ChangePassword Response: $res');
      return res;
    } catch (e, st) {
      debugPrint('changePassword error: $e\n$st');
      throw AppException.from(e, st);
    }
  }
}
