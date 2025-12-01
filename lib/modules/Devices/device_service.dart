import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:fire_alarm/others/errors/app_error_handler.dart';
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

    try {
      final res = await http.get(uri, headers: _headers());
      print('Devices Response [${res.statusCode}]: ${res.body}');

      final decoded = jsonDecode(res.body);

      if (decoded is Map<String, dynamic>) {
        final results = (decoded['results'] as List?) ?? const [];
        return results
            .map((e) => DeviceModel.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ))
            .toList();
      }

      if (decoded is List) {
        return decoded
            .map((e) => DeviceModel.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ))
            .toList();
      }

      // unexpected shape
      return [];
    } on AppException {
      // already classified, just bubble up
      rethrow;
    } catch (e, st) {
      print('Error in fetchAllDevices service: $e');
      throw AppException.from(e, st);
    }
  }

  /// /devices/tree/ -> [ { master fields..., "slaves":[...] }, ... ]
  Future<List<DeviceNode>> fetchDeviceTree() async {
    final uri = Uri.parse('${Api.baseUrl}/devices/tree/');

    try {
      final res = await AppHttp.get(uri, headers: _headers());
      print('Device Tree Response [${res.statusCode}]: ${res.body}');

      final decoded = jsonDecode(res.body);

      if (decoded is List) {
        return decoded
            .map((e) => DeviceNode.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ))
            .toList();
      }

      return [];
    } on AppException {
      rethrow;
    } catch (e, st) {
      print('Error in fetchDeviceTree service: $e');
      throw AppException.from(e, st);
    }
  }

  /// POST /devices/register/  (works for master & slave)
  ///
  /// We keep the DeviceRegisterResult pattern (so you can show raw API errors),
  /// but still wrap real network/timeout failures in AppException.
  Future<DeviceRegisterResult> registerDevice({
    required String hardwareIdentifier,
    required String deviceName,
    required double latitude,
    required double longitude,
    required String deviceRole, // 'master' | 'slave'
    int? masterId, // required if deviceRole == 'slave'
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

    try {
      final res = await _client
          .post(
            uri,
            headers: _headers(),
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 20));

      final body = res.body;
      print('Register Device Response [${res.statusCode}]: $body');

      if (res.statusCode == 200 || res.statusCode == 201) {
        try {
          final data = jsonDecode(body) as Map<String, dynamic>;
          final dev = DeviceModel.fromJson(data);
          return DeviceRegisterResult(
            statusCode: res.statusCode,
            device: dev,
            rawBody: body,
          );
        } catch (e) {
          // parsing error but HTTP was OK
          print('Parsing error in registerDevice: $e');
          return DeviceRegisterResult(
            statusCode: res.statusCode,
            rawBody: body,
          );
        }
      } else {
        // HTTP error – let caller inspect status & raw body
        return DeviceRegisterResult(
          statusCode: res.statusCode,
          rawBody: body,
        );
      }
    } on SocketException catch (e, st) {
      print('Network error in registerDevice: $e');
      throw AppException.from(e, st);
    } on TimeoutException catch (e, st) {
      print('Timeout in registerDevice: $e');
      throw AppException.from(e, st);
    } catch (e, st) {
      print('Unknown error in registerDevice: $e');
      throw AppException.from(e, st);
    }
  }

  /// Helper: only masters for dropdown when registering a slave
  Future<List<DeviceModel>> fetchMasters() async {
    final all = await fetchAllDevices();
    return all.where((d) => d.deviceRole.toLowerCase() == 'master').toList();
  }
}
