// device_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import '/others/utils/api.dart';
import 'device_model.dart';
import 'device_node.dart';

class DeviceRegisterResult {
  final int statusCode;
  final DeviceModel? device;
  final String? rawBody;

  DeviceRegisterResult({
    required this.statusCode,
    this.device,
    this.rawBody,
  });

  bool get isSuccess => statusCode == 200 || statusCode == 201;
}

class DeviceService {
  final http.Client _client = http.Client();
  final GetStorage _box = GetStorage();

  Map<String, String> _headers() {
    final token = _box.read<String>('access');
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// /devices/  -> { count, next, previous, results:[...] } or [ ... ]
  Future<List<DeviceModel>> fetchAllDevices() async {
    final uri = Uri.parse(Api.devices);
    final res = await _client.get(uri, headers: _headers());
    if (res.statusCode != 200) {
      throw Exception('Devices fetch failed: ${res.statusCode}');
    }
    final decoded = jsonDecode(res.body);
    if (decoded is Map<String, dynamic>) {
      final results = (decoded['results'] as List?) ?? const [];
      return results
          .map((e) => DeviceModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    if (decoded is List) {
      return decoded
          .map((e) => DeviceModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    return [];
  }

  /// /devices/tree/ -> [ { master fields..., "slaves":[...] }, ... ]
  Future<List<DeviceNode>> fetchDeviceTree() async {
    final uri = Uri.parse('${Api.baseUrl}/devices/tree/');
    final res = await _client.get(uri, headers: _headers());
    if (res.statusCode != 200) {
      throw Exception('Device tree fetch failed: ${res.statusCode}');
    }
    final decoded = jsonDecode(res.body);
    if (decoded is List) {
      return decoded
          .map((e) => DeviceNode.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    return [];
  }

  /// POST /devices/register/  (works for master & slave)
  Future<DeviceRegisterResult> registerDevice({
    required String hardwareIdentifier,
    required String deviceName,
    required double latitude,
    required double longitude,
    required String deviceRole, // 'master' | 'slave'
    int? masterId,              // required if deviceRole == 'slave'
  }) async {
    final uri = Uri.parse('${Api.baseUrl}/devices/register/');
    final payload = <String, dynamic>{
      'hardware_identifier': hardwareIdentifier,
      'device_name': deviceName,
      'latitude': latitude,
      'longitude': longitude,
      'device_role': deviceRole,
      if (deviceRole == 'slave' && masterId != null) 'master_id': masterId,
    };

    final res = await _client.post(
      uri,
      headers: _headers(),
      body: jsonEncode(payload),
    );

    final body = res.body;
    print('Register Device Response [${res.statusCode}]: $body');
    try {
      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(body) as Map<String, dynamic>;
        final dev = DeviceModel.fromJson(data);
        return DeviceRegisterResult(statusCode: res.statusCode, device: dev, rawBody: body);
      } else {
        return DeviceRegisterResult(statusCode: res.statusCode, rawBody: body);
      }
    } catch (_) {
      return DeviceRegisterResult(statusCode: res.statusCode, rawBody: body);
    }
  }

  /// Helper: only masters for dropdown when registering a slave
  Future<List<DeviceModel>> fetchMasters() async {
    final all = await fetchAllDevices();
    return all.where((d) => d.deviceRole.toLowerCase() == 'master').toList();
  }
}
