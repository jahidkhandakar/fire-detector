import 'dart:async';
import 'dart:io';
import '/others/errors/app_error_handler.dart';
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

    try {
      final res = await http.get(
        uri,
        headers: _headers(),
      );

      print("Response: ${res.body}");

      final data = AppHttp.parseJsonObject<Map<String, dynamic>>(
        res.body,
        (json) => json,
      );

      final List alertsJson = data['results'] as List;
      return alertsJson.map((e) => AlertModel.fromJson(e)).toList();
    } on AppException {
      rethrow; // let controller/UI decide
    } catch (e, st) {
      print('Error in fetchAlerts service: $e');
      throw AppException.from(e, st);
    }
  }

  //*--- 🔹 Fetch alerts for a specific device (GET /devices/<id>/alerts)-----
  Future<List<AlertModel>> fetchAlertsByDevice({
    required String baseUrl,
    required int deviceId,
  }) async {
    final uri = Uri.parse('$baseUrl/devices/$deviceId/alerts');

    try {
      final res = await AppHttp.get(
        uri,
        headers: _headers(),
      );

      print("Device Alerts Response: ${res.body}");

      final data = AppHttp.parseJsonObject<Map<String, dynamic>>(
        res.body,
        (json) => json,
      );

      final List alertsJson = data['results'] as List;
      return alertsJson.map((e) => AlertModel.fromJson(e)).toList();
    } on AppException {
      rethrow;
    } catch (e, st) {
      print('Error in fetchAlertsByDevice service: $e');
      throw AppException.from(e, st);
    }
  }

  //*------- 🔹 Resolve an alert (POST /alerts/<id>/resolve/)-------
  Future<bool> resolveAlert({
    required String baseUrl,
    required int alertId,
  }) async {
    final uri = Uri.parse('$baseUrl/alerts/$alertId/resolve/');

    try {
      final response = await http
          .post(uri, headers: _headers())
          .timeout(const Duration(seconds: 20));

      print(
          "Resolve Alert Response (${response.statusCode}): ${response.body}");

      if (response.statusCode == 200) {
        return true;
      }

      throw _mapStatusToAppException(
        response,
        context: 'Failed to resolve alert #$alertId',
      );
    } on AppException {
      rethrow;
    } on SocketException catch (e, st) {
      print('Network error in resolveAlert: $e');
      throw AppException.from(e, st);
    } on TimeoutException catch (e, st) {
      print('Timeout in resolveAlert: $e');
      throw AppException.from(e, st);
    } catch (e, st) {
      print('Unknown error in resolveAlert: $e');
      throw AppException.from(e, st);
    }
  }

  //*------- 🔹 Acknowledge an alert (POST /alerts/<id>/acknowledge/)-------
  Future<bool> acknowledgeAlert({
    required String baseUrl,
    required int alertId,
  }) async {
    final uri = Uri.parse('$baseUrl/alerts/$alertId/acknowledge/');

    try {
      final response = await http
          .post(uri, headers: _headers())
          .timeout(const Duration(seconds: 20));

      print(
          "Acknowledge Alert Response (${response.statusCode}): ${response.body}");

      if (response.statusCode == 200) {
        return true;
      }

      throw _mapStatusToAppException(
        response,
        context: 'Failed to acknowledge alert #$alertId',
      );
    } on AppException {
      rethrow;
    } on SocketException catch (e, st) {
      print('Network error in acknowledgeAlert: $e');
      throw AppException.from(e, st);
    } on TimeoutException catch (e, st) {
      print('Timeout in acknowledgeAlert: $e');
      throw AppException.from(e, st);
    } catch (e, st) {
      print('Unknown error in acknowledgeAlert: $e');
      throw AppException.from(e, st);
    }
  }

  // 🔧 Map HTTP status → AppException with proper type
  AppException _mapStatusToAppException(
    http.Response res, {
    required String context,
  }) {
    final code = res.statusCode;

    if (code == 401) {
      return AppException(
        type: AppErrorType.unauthorized,
        message: '$context (unauthorized)',
        raw: res,
      );
    }

    if (code == 404) {
      return AppException(
        type: AppErrorType.notFound,
        message: '$context (not found)',
        raw: res,
      );
    }

    if (code >= 500) {
      return AppException(
        type: AppErrorType.server,
        message: '$context (server error $code)',
        raw: res,
      );
    }

    return AppException(
      type: AppErrorType.unknown,
      message: '$context (HTTP $code)',
      raw: res,
    );
  }
}
