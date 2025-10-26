import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import '/others/utils/api.dart';
import 'shurjopay_models.dart';

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
  Future<ShurjoInitiateResponse> initiate(Map<String, dynamic> body) async {
    final uri = Uri.parse(Api.shurjoInitiate);
    print("🟠 Initiating ShurjoPay: $uri");
    print("➡️ Payload: $body");

    try {
      final res = await client.post(uri, headers: _headers(), body: jsonEncode(body));
      print("🟢 Initiate Response [${res.statusCode}]: ${res.body}");

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return ShurjoInitiateResponse.fromJson(data);
      } else {
        throw Exception('Initiate failed: ${res.statusCode} ${res.reasonPhrase}');
      }
    } catch (e) {
      print("❌ Initiate error: $e");
      rethrow;
    }
  }

  //*______________ Verify payment (POST) ______________*//
  Future<ShurjoVerifyResponse> verify(String orderId) async {
    final uri = Uri.parse(Api.shurjoVerify);
    print("🟠 Verifying order_id: $orderId");

    try {
      final res = await client.post(
        uri,
        headers: _headers(),
        body: jsonEncode({'order_id': orderId}),
      );
      print("🟢 Verify Response [${res.statusCode}]: ${res.body}");

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return ShurjoVerifyResponse.fromJson(data);
      } else {
        throw Exception('Verify failed: ${res.statusCode} ${res.reasonPhrase}');
      }
    } catch (e) {
      print("❌ Verify error: $e");
      rethrow;
    }
  }

  //*______________ Return (GET) – browser redirect ______________*//
  /// GET /shurjopay/return/?order_id=...
  /// Your server returns:
  /// { message, order_id, verified: true/false, details: { ...verify-like payload... } }
  /// We try to parse `details` into ShurjoVerifyResponse so you can still check `isSuccess`.
  Future<ShurjoVerifyResponse?> returnUrl(String orderId) async {
    final uri = Uri.parse('${Api.shurjoReturn}?order_id=$orderId');
    print("🟠 Return URL: $uri");

    try {
      final res = await client.get(uri, headers: _headers());
      print("🟢 Return Response [${res.statusCode}]: ${res.body}");

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final details = data['details'];
        if (details is Map<String, dynamic>) {
          return ShurjoVerifyResponse.fromJson(details);
        } else {
          // Fallback: try to build from top-level if details absent
          return ShurjoVerifyResponse.fromJson(data);
        }
      } else {
        throw Exception('Return failed: ${res.statusCode} ${res.reasonPhrase}');
      }
    } catch (e) {
      print("❌ Return error: $e");
      rethrow;
    }
  }

  //*______________ Cancel (GET) – browser redirect ______________*//
  /// GET /shurjopay/cancel/?order_id=...
  /// Returns true on HTTP 200.
  Future<bool> cancel(String orderId) async {
    final uri = Uri.parse('${Api.shurjoCancel}?order_id=$orderId');
    print("🟠 Cancel URL: $uri");

    try {
      final res = await client.get(uri, headers: _headers());
      print("🟢 Cancel Response [${res.statusCode}]: ${res.body}");

      if (res.statusCode == 200) return true;
      throw Exception('Cancel failed: ${res.statusCode} ${res.reasonPhrase}');
    } catch (e) {
      print("❌ Cancel error: $e");
      rethrow;
    }
  }

  //*______________ Status (GET) – by transaction_id ______________*//
  /// GET /shurjopay/status/?transaction_id=...
  /// Returns the raw JSON as Map<String, dynamic> so you can display it.
  Future<Map<String, dynamic>> status(int transactionId) async {
    final uri = Uri.parse('${Api.shurjoStatus}?transaction_id=$transactionId');
    print("🟠 Status URL: $uri");

    try {
      final res = await client.get(uri, headers: _headers());
      print("🟢 Status Response [${res.statusCode}]: ${res.body}");

      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      } else {
        throw Exception('Status failed: ${res.statusCode} ${res.reasonPhrase}');
      }
    } catch (e) {
      print("❌ Status error: $e");
      rethrow;
    }
  }
}
