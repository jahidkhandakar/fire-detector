import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import '/others/utils/api.dart';
import 'shurjopay_models.dart';
import '/others/errors/app_error_handler.dart';

class ShurjoPayService {
  final client = http.Client();
  final GetStorage _box = GetStorage();

  Map<String, String> _headers() {
    final token = _box.read<String>('access');
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  //*______________ Initiate payment ______________*//
  Future<ShurjoInitiateResponse> initiate(
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse(Api.shurjoInitiate);
    print("🟠 Initiating ShurjoPay: $uri");
    print("➡️ Payload: $body");

    http.Response res;
    try {
      res = await client
          .post(
            uri,
            headers: _headers(),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));
      print("🟢 Initiate Response [${res.statusCode}]: ${res.body}");
    } on SocketException catch (e, st) {
      print("❌ Initiate network error: $e");
      throw AppException.from(e, st);
    } on TimeoutException catch (e, st) {
      print("❌ Initiate timeout: $e");
      throw AppException.from(e, st);
    } catch (e, st) {
      print("❌ Initiate unknown error: $e");
      throw AppException.from(e, st);
    }

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return ShurjoInitiateResponse.fromJson(data);
    }

    throw _mapStatusToAppException(
      res,
      context: 'Initiate failed',
    );
  }

  //*______________ Verify payment (POST) ______________*//
  Future<ShurjoVerifyResponse> verify(String orderId) async {
    final uri = Uri.parse(Api.shurjoVerify);
    print("🟠 Verifying order_id: $orderId");

    http.Response res;
    try {
      res = await client
          .post(
            uri,
            headers: _headers(),
            body: jsonEncode({'order_id': orderId}),
          )
          .timeout(const Duration(seconds: 20));
      print("🟢 Verify Response [${res.statusCode}]: ${res.body}");
    } on SocketException catch (e, st) {
      print("❌ Verify network error: $e");
      throw AppException.from(e, st);
    } on TimeoutException catch (e, st) {
      print("❌ Verify timeout: $e");
      throw AppException.from(e, st);
    } catch (e, st) {
      print("❌ Verify unknown error: $e");
      throw AppException.from(e, st);
    }

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return ShurjoVerifyResponse.fromJson(data);
    }

    throw _mapStatusToAppException(
      res,
      context: 'Verify failed',
    );
  }

  //*______________ Return (GET) – browser redirect ______________*//
  Future<ShurjoVerifyResponse?> returnUrl(String orderId) async {
    final uri = Uri.parse('${Api.shurjoReturn}?order_id=$orderId');
    print("🟠 Return URL: $uri");

    http.Response res;
    try {
      res = await client
          .get(
            uri,
            headers: _headers(),
          )
          .timeout(const Duration(seconds: 20));
      print("🟢 Return Response [${res.statusCode}]: ${res.body}");
    } on SocketException catch (e, st) {
      print("❌ Return network error: $e");
      throw AppException.from(e, st);
    } on TimeoutException catch (e, st) {
      print("❌ Return timeout: $e");
      throw AppException.from(e, st);
    } catch (e, st) {
      print("❌ Return unknown error: $e");
      throw AppException.from(e, st);
    }

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final details = data['details'];
      if (details is Map<String, dynamic>) {
        return ShurjoVerifyResponse.fromJson(details);
      } else {
        // Fallback: try to build from top-level if details absent
        return ShurjoVerifyResponse.fromJson(data);
      }
    }

    throw _mapStatusToAppException(
      res,
      context: 'Return failed',
    );
  }

  //*______________ Cancel (GET) – browser redirect ______________*//
  Future<bool> cancel(String orderId) async {
    final uri = Uri.parse('${Api.shurjoCancel}?order_id=$orderId');
    print("🟠 Cancel URL: $uri");

    http.Response res;
    try {
      res = await client
          .get(
            uri,
            headers: _headers(),
          )
          .timeout(const Duration(seconds: 20));
      print("🟢 Cancel Response [${res.statusCode}]: ${res.body}");
    } on SocketException catch (e, st) {
      print("❌ Cancel network error: $e");
      throw AppException.from(e, st);
    } on TimeoutException catch (e, st) {
      print("❌ Cancel timeout: $e");
      throw AppException.from(e, st);
    } catch (e, st) {
      print("❌ Cancel unknown error: $e");
      throw AppException.from(e, st);
    }

    if (res.statusCode == 200) {
      return true;
    }

    throw _mapStatusToAppException(
      res,
      context: 'Cancel failed',
    );
  }

  //*______________ Status (GET) – by transaction_id ______________*//
  Future<Map<String, dynamic>> status(int transactionId) async {
    final uri =
        Uri.parse('${Api.shurjoStatus}?transaction_id=$transactionId');
    print("🟠 Status URL: $uri");

    http.Response res;
    try {
      res = await client
          .get(
            uri,
            headers: _headers(),
          )
          .timeout(const Duration(seconds: 20));
      print("🟢 Status Response [${res.statusCode}]: ${res.body}");
    } on SocketException catch (e, st) {
      print("❌ Status network error: $e");
      throw AppException.from(e, st);
    } on TimeoutException catch (e, st) {
      print("❌ Status timeout: $e");
      throw AppException.from(e, st);
    } catch (e, st) {
      print("❌ Status unknown error: $e");
      throw AppException.from(e, st);
    }

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }

    throw _mapStatusToAppException(
      res,
      context: 'Status failed',
    );
  }

  // 🔧 Map HTTP status → AppException with proper type
  AppException _mapStatusToAppException(
    http.Response res, {
    required String context,
  }) {
    final code = res.statusCode;
    final body = res.body;

    print('❌ HTTP error $code for "$context": $body');

    if (code == 401) {
      return AppException(
        type: AppErrorType.unauthorized,
        message: '$context (unauthorized): $body',
        raw: res,
      );
    }

    if (code == 404) {
      return AppException(
        type: AppErrorType.notFound,
        message: '$context (not found): $body',
        raw: res,
      );
    }

    if (code >= 500) {
      return AppException(
        type: AppErrorType.server,
        message: '$context (server error $code): $body',
        raw: res,
      );
    }

    return AppException(
      type: AppErrorType.unknown,
      message: '$context (HTTP $code): $body',
      raw: res,
    );
  }
}
