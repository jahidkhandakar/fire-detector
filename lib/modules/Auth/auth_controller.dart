import 'package:flutter/material.dart';
import '/modules/auth/auth_service.dart';

class AuthController {
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> userRegistration({
    required String api,
    required String mail,
    required String pass,
    required String phone,
    required String name,
  }) {
    return _authService.register(
      api: api,
      mail: mail,
      pass: pass,
      phone: phone,
      name: name,
    );
  }

  Future<Map<String, dynamic>> userLogin({
    required String api,
    required String mail,
    required String pass,
  }) async {
    final res = await _authService.login(
      api: api,
      mail: mail.trim(),
      pass: pass,
    );
    debugPrint('Login Response: $res');
    final access = res['access'];
    final refresh = res['refresh'];

    debugPrint('Access Token: $access');
    debugPrint('Refresh Token: $refresh');

    return res;
  }

}
