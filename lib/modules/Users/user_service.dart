import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import '/modules/users/user_model.dart';

class UserService {
  final GetStorage _box = GetStorage();

  /// Build headers with optional Bearer token
  Map<String, String> _headers() {
    final token = _box.read<String>('access');
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  //*------------------ GET: Fetch User Details ------------------///
  Future<UserModel> userDetails({required String api}) async {
    final uri = Uri.parse(api);
    final res = await http
        .get(uri, headers: _headers())
        .timeout(const Duration(seconds: 20));

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return UserModel.fromJson(data);
    } else {
      throw Exception(
        "Failed to fetch user details. Status: ${res.statusCode}, Body: ${res.body}",
      );
    }
  }

  //*------------------ PATCH: Update User Profile ------------------///
  Future<UserModel> updateUserProfile({
    required String api,
    required String fullName,
    required String address,
    required String phoneNumber,
  }) async {
    final uri = Uri.parse(api);
    final payload = jsonEncode({
      "full_name": fullName,
      "address": address,
      "phone_number": phoneNumber,
    });

    final res = await http
        .patch(uri, headers: _headers(), body: payload)
        .timeout(const Duration(seconds: 20));

    if (res.statusCode == 200 || res.statusCode == 201) {
      final data = jsonDecode(res.body);
      return UserModel.fromJson(data);
    } else {
      throw Exception(
        "Failed to update user profile. Status: ${res.statusCode}, Body: ${res.body}",
      );
    }
  }
}
