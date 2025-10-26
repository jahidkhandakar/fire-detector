import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'alert_model.dart';

class AlertService {
  final GetStorage _box = GetStorage();

  Map<String, String> _headers() {
    final token = _box.read<String>('access');
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  //*---------- 🔹 Fetch all alerts (paginated API)------------
  Future<List<AlertModel>> fetchAlerts({required String apiUrl}) async {
    final uri = Uri.parse(apiUrl);
    final response = await http.get(uri, headers: _headers()).timeout(const Duration(seconds: 20));

    print("Response: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List alertsJson = data['results'];
      return alertsJson.map((e) => AlertModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load alerts. Status: ${response.statusCode}');
    }
  }

  //*--- 🔹 Fetch alerts for a specific device (GET /devices/<id>/alerts)-----
  Future<List<AlertModel>> fetchAlertsByDevice({
    required String baseUrl,
    required int deviceId,
  }) async {
    final uri = Uri.parse('$baseUrl/devices/$deviceId/alerts');
    final response = await http.get(uri, headers: _headers()).timeout(const Duration(seconds: 20));

    print("Device Alerts Response: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List alertsJson = data['results'];
      return alertsJson.map((e) => AlertModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load alerts for device $deviceId');
    }
  }

  //*------- 🔹 Resolve an alert (POST /alerts/<id>/resolve/)-------
  Future<bool> resolveAlert({
    required String baseUrl,
    required int alertId,
  }) async {
    final uri = Uri.parse('$baseUrl/alerts/$alertId/resolve/');
    final response = await http.post(uri, headers: _headers());

    print("Resolve Alert Response (${response.statusCode}): ${response.body}");

    if (response.statusCode == 200) return true;
    throw Exception('Failed to resolve alert #$alertId (${response.statusCode})');
  }
}
