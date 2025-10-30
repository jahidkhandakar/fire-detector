import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import '/others/utils/api.dart';
import 'fcm_device_model.dart';

class FcmService {
  final _client = http.Client();
  final _box = GetStorage();

  Map<String, String> _headers() {
    final token = _box.read<String>('access');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty)
        'Authorization': 'Bearer $token',
    };
  }

  //*-------- Register current device token with backend--------*//
  Future<void> registerDeviceToken(String token) async {
    final uri = Uri.parse('${Api.baseUrl}/api/fcm/devices/');
    final res = await _client.post(
      uri,
      headers: _headers(),
      body: jsonEncode({
        'registration_token': token,
        'device_name': 'FireAlarm-${DateTime.now().millisecondsSinceEpoch}',
        'device_type': 'android',
        'active': true,
      }),
    );

    if (res.statusCode == 201) {
      print('✅ FCM device registered.');
    } else if (res.statusCode == 400 &&
        res.body.contains('already exists')) {
      print('ℹ️ Device already registered.');
    } else {
      print('⚠️ FCM registration failed: ${res.statusCode} ${res.body}');
    }
  }

  //*------- Get all registered FCM devices for current user-------*//
  Future<List<FcmDeviceModel>> fetchRegisteredDevices() async {
    final uri = Uri.parse('${Api.baseUrl}/api/fcm/devices/');
    final res = await _client.get(uri, headers: _headers());
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final results = data['results'] as List;
      return results.map((e) => FcmDeviceModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to fetch FCM devices');
    }
  }
}
