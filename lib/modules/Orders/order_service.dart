import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:flutter/foundation.dart';
import '/others/utils/api.dart';
import 'order_model.dart';

class OrderService {
  final client = http.Client();
  final _box = GetStorage();

  /// 🔹 Prepare headers with auth token
  Map<String, String> _headers() {
    final token = _box.read<String>('access');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
    debugPrint('🧩 OrderService._headers => $headers');
    return headers;
  }

  /// 🔹 Get all orders for a user
  Future<List<OrderModel>> fetchOrders(int userId) async {
    final uri = Uri.parse('${Api.orders}$userId/');
    debugPrint('➡️ GET $uri');
    final res = await client.get(uri, headers: _headers());
    debugPrint('🟢 GET /orders/$userId → ${res.statusCode}\nBODY: ${res.body}');
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as List;
      return data.map((e) => OrderModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to fetch orders (${res.statusCode}): ${res.body}');
    }
  }

  /// 🔹 Get single order
  Future<OrderModel> fetchOrderById(int userId, int orderId) async {
    final uri = Uri.parse('${Api.orders}$userId/$orderId/');
    debugPrint('➡️ GET $uri');
    final res = await client.get(uri, headers: _headers());
    debugPrint('🟢 GET /orders/$userId/$orderId → ${res.statusCode}\nBODY: ${res.body}');
    if (res.statusCode == 200) {
      return OrderModel.fromJson(jsonDecode(res.body));
    } else {
      throw Exception('Failed to fetch order details (${res.statusCode}): ${res.body}');
    }
  }

  /// 🔹 Create new order (verbose logs + rich errors)
  Future<OrderModel> createOrder(int userId, Map<String, dynamic> body) async {
    // Type & payload visibility
    debugPrint('🧾 CreateOrder payload (pre) => $body');
    debugPrint('   • amount type: ${body["amount"]?.runtimeType}');
    debugPrint('   • package type: ${body["package"]?.runtimeType}');
    debugPrint('   • quantity type: ${body["quantity"]?.runtimeType}');
    debugPrint('   • masters/slaves: ${body["number_of_master_devices"]}/${body["number_of_slave_devices"]}');

    final uri = Uri.parse('${Api.orders}$userId/');
    final headers = _headers();

    debugPrint('➡️ POST $uri');
    debugPrint('   HEADERS: $headers');
    debugPrint('   BODY: ${jsonEncode(body)}');

    http.Response res;
    try {
      res = await client.post(uri, headers: headers, body: jsonEncode(body));
    } catch (e, st) {
      debugPrint('❌ Network error while POST /orders/$userId: $e\n$st');
      rethrow;
    }

    debugPrint('🟢 POST /orders/$userId → ${res.statusCode}');
    debugPrint('   RESP BODY: ${res.body}');
    debugPrint('   RESP HEADERS: ${res.headers}');

    if (res.statusCode == 200 || res.statusCode == 201) {
      final parsed = jsonDecode(res.body);
      return OrderModel.fromJson(parsed);
    }

    // Parse server validation for clarity
    try {
      final err = jsonDecode(res.body);
      throw Exception('Failed to create order (${res.statusCode}): $err');
    } catch (_) {
      throw Exception('Failed to create order (${res.statusCode}): ${res.body}');
    }
  }
}
