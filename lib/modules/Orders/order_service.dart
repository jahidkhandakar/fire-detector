import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:flutter/foundation.dart';
import '/others/utils/api.dart';
import 'order_model.dart';
import '/others/errors/app_error_handler.dart';

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

    try {
      final res = await AppHttp.get(uri, headers: _headers());

      debugPrint(
        '🟢 GET /orders/$userId → ${res.statusCode}\nBODY: ${res.body}',
      );

      final data = jsonDecode(res.body) as List;
      return data.map((e) => OrderModel.fromJson(e)).toList();
    } on AppException {
      // already classified by AppHttp
      rethrow;
    } catch (e, st) {
      debugPrint('❌ fetchOrders error: $e\n$st');
      throw AppException.from(e, st);
    }
  }

  /// 🔹 Get single order
  Future<OrderModel> fetchOrderById(int userId, int orderId) async {
    final uri = Uri.parse('${Api.orders}$userId/$orderId/');
    debugPrint('➡️ GET $uri');

    try {
      final res = await AppHttp.get(uri, headers: _headers());

      debugPrint(
        '🟢 GET /orders/$userId/$orderId → ${res.statusCode}\nBODY: ${res.body}',
      );

      return OrderModel.fromJson(jsonDecode(res.body));
    } on AppException {
      rethrow;
    } catch (e, st) {
      debugPrint('❌ fetchOrderById error: $e\n$st');
      throw AppException.from(e, st);
    }
  }

  /// 🔹 Create new order (verbose logs + rich errors)
  Future<OrderModel> createOrder(int userId, Map<String, dynamic> body) async {
    // Type & payload visibility
    debugPrint('🧾 CreateOrder payload (pre) => $body');
    debugPrint('   • amount type: ${body["amount"]?.runtimeType}');
    debugPrint('   • package type: ${body["package"]?.runtimeType}');
    debugPrint('   • quantity type: ${body["quantity"]?.runtimeType}');
    debugPrint(
      '   • masters/slaves: ${body["number_of_master_devices"]}/${body["number_of_slave_devices"]}',
    );

    final uri = Uri.parse('${Api.orders}$userId/');
    final headers = _headers();

    debugPrint('➡️ POST $uri');
    debugPrint('   HEADERS: $headers');
    debugPrint('   BODY: ${jsonEncode(body)}');

    http.Response res;
    try {
      res = await client
          .post(uri, headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 20));
    } on SocketException catch (e, st) {
      debugPrint('❌ Network error while POST /orders/$userId: $e\n$st');
      throw AppException.from(e, st);
    } on TimeoutException catch (e, st) {
      debugPrint('❌ Timeout while POST /orders/$userId: $e\n$st');
      throw AppException.from(e, st);
    } catch (e, st) {
      debugPrint('❌ Unknown error while POST /orders/$userId: $e\n$st');
      throw AppException.from(e, st);
    }

    debugPrint('🟢 POST /orders/$userId → ${res.statusCode}');
    debugPrint('   RESP BODY: ${res.body}');
    debugPrint('   RESP HEADERS: ${res.headers}');

    if (res.statusCode == 200 || res.statusCode == 201) {
      final parsed = jsonDecode(res.body);
      return OrderModel.fromJson(parsed);
    }

    // HTTP error → wrap into AppException with some context
    throw _mapStatusToAppException(res, context: 'Failed to create order');
  }

  //______________ 🔥 update order_status__________________//
  Future<OrderModel> updateOrderStatus({
    required int userId,
    required int orderId,
    required String status,
  }) async {
    final uri = Uri.parse('${Api.ordersUpdateStatus}$userId/$orderId/');

    debugPrint('➡️ POST $uri (update status=$status)');

    http.Response res;
    try {
      res = await client
          .post(
            uri,
            headers: _headers(),
            body: jsonEncode({'order_status': status}),
          )
          .timeout(const Duration(seconds: 20));
    } on SocketException catch (e, st) {
      debugPrint('❌ Network error while POST update status: $e\n$st');
      throw AppException.from(e, st);
    } on TimeoutException catch (e, st) {
      debugPrint('❌ Timeout while POST update status: $e\n$st');
      throw AppException.from(e, st);
    } catch (e, st) {
      debugPrint('❌ Unknown error while POST update status: $e\n$st');
      throw AppException.from(e, st);
    }

    debugPrint(
      '🟢 POST /orders/status/$userId/$orderId → ${res.statusCode}\nBODY: ${res.body}',
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return OrderModel.fromJson(data);
    }

    throw _mapStatusToAppException(res, context: 'Update status failed');
  }

  //______________ 🔔 notify payment (user API) ______________//
  Future<void> notifyPayment({
    required int orderId,
    required String transactionId,
    Map<String, dynamic>? gatewayResponse,
  }) async {
    // Make sure you have: Api.ordersPaymentNotify = '$baseUrl/orders/payment/notify/';
    final uri = Uri.parse(Api.ordersPaymentNotify);

    final body = {
      "order_id": orderId.toString(),
      "transaction_id": transactionId,
      "gateway_response": gatewayResponse ?? {}, // backend example uses {}
    };

    debugPrint('➡️ POST $uri (notify payment for order=$orderId)');

    http.Response res;
    try {
      res = await client
          .post(uri, headers: _headers(), body: jsonEncode(body))
          .timeout(const Duration(seconds: 20));
    } on SocketException catch (e, st) {
      debugPrint('❌ Network error while POST notify: $e\n$st');
      throw AppException.from(e, st);
    } on TimeoutException catch (e, st) {
      debugPrint('❌ Timeout while POST notify: $e\n$st');
      throw AppException.from(e, st);
    } catch (e, st) {
      debugPrint('❌ Unknown error while POST notify: $e\n$st');
      throw AppException.from(e, st);
    }

    debugPrint(
      '🟢 POST /orders/payment/notify/ → ${res.statusCode}\nBODY: ${res.body}',
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final markedPaid = data['marked_paid'] == true;

      if (!markedPaid) {
        throw AppException(
          type: AppErrorType.unknown,
          message: 'Payment notify did not mark order as paid',
          raw: data,
        );
      }
      return;
    }

    throw _mapStatusToAppException(res, context: 'Payment notify failed');
  }

  // 🔧 Map HTTP status → AppException with proper type
  AppException _mapStatusToAppException(
    http.Response res, {
    required String context,
  }) {
    final code = res.statusCode;
    final body = res.body;

    // You can log the body here for dev debugging
    debugPrint('❌ HTTP error $code for "$context": $body');

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
