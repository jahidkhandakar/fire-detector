import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import '/others/utils/api.dart';
import 'order_model.dart';

class OrderService {
  final client = http.Client();
  final _box = GetStorage();

  Map<String, String> _headers() {
    final token = _box.read<String>('access');
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty)
        'Authorization': 'Bearer $token',
    };
  }

  /// 🔹 Get all orders for a user
  Future<List<OrderModel>> fetchOrders(int userId) async {
    final uri = Uri.parse('${Api.orders}$userId/');
    final res = await client.get(uri, headers: _headers());
    print('🟢 GET /orders/$userId → ${res.statusCode}');
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as List;
      return data.map((e) => OrderModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to fetch orders');
    }
  }

  /// 🔹 Get single order
  Future<OrderModel> fetchOrderById(int userId, int orderId) async {
    final uri = Uri.parse('${Api.orders}$userId/$orderId/');
    final res = await client.get(uri, headers: _headers());
    print('🟢 GET /orders/$userId/$orderId → ${res.statusCode}');
    if (res.statusCode == 200) {
      return OrderModel.fromJson(jsonDecode(res.body));
    } else {
      throw Exception('Failed to fetch order details');
    }
  }

  /// 🔹 Create new order
  Future<OrderModel> createOrder(int userId, Map<String, dynamic> body) async {
    final uri = Uri.parse('${Api.orders}$userId/');
    final res = await client.post(uri, headers: _headers(), body: jsonEncode(body));
    print('🟢 POST /orders/$userId → ${res.statusCode}');
    if (res.statusCode == 200 || res.statusCode == 201) {
      return OrderModel.fromJson(jsonDecode(res.body));
    } else {
      throw Exception('Failed to create order (${res.statusCode})');
    }
  }
}
