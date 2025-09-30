import 'package:fire_alarm/mvc/services/auth_service.dart';
import 'package:get_storage/get_storage.dart';

class AuthController {
  final AuthService _authService = AuthService();
  final GetStorage _box = GetStorage();

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
    final data = res['data'];

    // Save tokens
    if (data is Map) {
      final access =
          (data['access'] ?? data['token'] ?? data['access_token'])?.toString();
      final refresh = (data['refresh'] ?? data['refresh_token'])?.toString();
      if (access != null && access.isNotEmpty)
        await _box.write('access', access);
      if (refresh != null && refresh.isNotEmpty)
        await _box.write('refresh', refresh);

      // Save profile fields if present
      final user = (data['user'] is Map) ? data['user'] as Map : data;
      final name =
          (user['name'] ??
                  user['full_name'] ??
                  '${(user['first_name'] ?? '').toString().trim()} ${(user['last_name'] ?? '').toString().trim()}')
              .toString()
              .trim();
      final email = (user['email'] ?? user['mail'])?.toString();
      final phone = (user['phone'] ?? user['phone_number'])?.toString();

      if (name.isNotEmpty) await _box.write('profile_name', name);
      if (email != null && email.isNotEmpty)
        await _box.write('profile_email', email);
      if (phone != null && phone.isNotEmpty)
        await _box.write('profile_phone', phone);
    }

    return res;
  }

  Future<void> logout() async {
    await _box.remove('access');
    await _box.remove('refresh');
    await _box.remove('profile_name');
    await _box.remove('profile_email');
    await _box.remove('profile_phone');
    await _box.remove('signup_name');
  }
}
