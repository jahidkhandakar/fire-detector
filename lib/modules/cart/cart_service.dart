import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import '/others/utils/api.dart';
import '/modules/cart/cart_model.dart';
import '/modules/orders/order_model.dart';
import '/others/errors/app_error_handler.dart';

class CartService {
  final client = http.Client();
  final GetStorage _box = GetStorage();

  Map<String, String> _headers() {
    final token = _box.read<String>('access');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
    debugPrint('🧩 CartService._headers => $headers');
    return headers;
  }

  // GET /cart/
  Future<CartModel?> fetchCart() async {
    final uri = Uri.parse(Api.cart);
    debugPrint('➡️ GET $uri (cart)');

    http.Response res;
    try {
      res = await client
          .get(uri, headers: _headers())
          .timeout(const Duration(seconds: 20));
    } on SocketException catch (e, st) {
      debugPrint('❌ fetchCart network error: $e\n$st');
      throw AppException.from(e, st);
    } on TimeoutException catch (e, st) {
      debugPrint('❌ fetchCart timeout: $e\n$st');
      throw AppException.from(e, st);
    } catch (e, st) {
      debugPrint('❌ fetchCart unknown error: $e\n$st');
      throw AppException.from(e, st);
    }

    debugPrint('🟢 GET /cart/ → ${res.statusCode} BODY: ${res.body}');

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      return CartModel.fromJson(decoded);
    }

    // 404 or others → treat as error (or you could return empty CartModel)
    throw _mapStatusToAppException(res, context: 'Failed to load cart');
  }

  // POST /cart/items/
  Future<CartItemModel> addItem({
    required int packageId,
    required int quantity,
    required int masters,
    required int slaves,
  }) async {
    final uri = Uri.parse(Api.cartItems);
    final body = {
      'package_id': packageId,
      'quantity': quantity,
      'number_of_master_devices': masters,
      'number_of_slave_devices': slaves,
    };

    debugPrint('➡️ POST $uri (add item)');
    debugPrint('   BODY: $body');

    http.Response res;
    try {
      res = await client
          .post(
            uri,
            headers: _headers(),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));
    } on SocketException catch (e, st) {
      debugPrint('❌ addItem network error: $e\n$st');
      throw AppException.from(e, st);
    } on TimeoutException catch (e, st) {
      debugPrint('❌ addItem timeout: $e\n$st');
      throw AppException.from(e, st);
    } catch (e, st) {
      debugPrint('❌ addItem unknown error: $e\n$st');
      throw AppException.from(e, st);
    }

    debugPrint('🟢 POST /cart/items/ → ${res.statusCode} BODY: ${res.body}');

    if (res.statusCode == 200 || res.statusCode == 201) {
      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      return CartItemModel.fromJson(decoded);
    }

    throw _mapStatusToAppException(res, context: 'Failed to add item to cart');
  }

  // PATCH /cart/items/{item_id}/
  Future<CartItemModel> updateItem({
    required int itemId,
    required int quantity,
    required int masters,
    required int slaves,
  }) async {
    final uri = Uri.parse('${Api.cartItems}$itemId/');
    final body = {
      'quantity': quantity,
      'number_of_master_devices': masters,
      'number_of_slave_devices': slaves,
    };

    debugPrint('➡️ PATCH $uri (update item)');
    debugPrint('   BODY: $body');

    http.Response res;
    try {
      res = await client
          .patch(
            uri,
            headers: _headers(),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));
    } on SocketException catch (e, st) {
      debugPrint('❌ updateItem network error: $e\n$st');
      throw AppException.from(e, st);
    } on TimeoutException catch (e, st) {
      debugPrint('❌ updateItem timeout: $e\n$st');
      throw AppException.from(e, st);
    } catch (e, st) {
      debugPrint('❌ updateItem unknown error: $e\n$st');
      throw AppException.from(e, st);
    }

    debugPrint('🟢 PATCH /cart/items/$itemId/ → ${res.statusCode} BODY: ${res.body}');

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      return CartItemModel.fromJson(decoded);
    }

    throw _mapStatusToAppException(res, context: 'Failed to update cart item');
  }

  // DELETE /cart/items/{item_id}/
  Future<void> removeItem(int itemId) async {
    final uri = Uri.parse('${Api.cartItems}$itemId/');

    debugPrint('➡️ DELETE $uri (remove item)');

    http.Response res;
    try {
      res = await client
          .delete(uri, headers: _headers())
          .timeout(const Duration(seconds: 20));
    } on SocketException catch (e, st) {
      debugPrint('❌ removeItem network error: $e\n$st');
      throw AppException.from(e, st);
    } on TimeoutException catch (e, st) {
      debugPrint('❌ removeItem timeout: $e\n$st');
      throw AppException.from(e, st);
    } catch (e, st) {
      debugPrint('❌ removeItem unknown error: $e\n$st');
      throw AppException.from(e, st);
    }

    debugPrint('🟢 DELETE /cart/items/$itemId/ → ${res.statusCode}');

    if (res.statusCode == 204 || res.statusCode == 200) {
      return;
    }
    if (res.statusCode == 404) {
      // item already gone → not fatal
      return;
    }

    throw _mapStatusToAppException(res, context: 'Failed to remove cart item');
  }

  // DELETE /cart/
  Future<void> clearCart() async {
    final uri = Uri.parse(Api.cart);

    debugPrint('➡️ DELETE $uri (clear cart)');

    http.Response res;
    try {
      res = await client
          .delete(uri, headers: _headers())
          .timeout(const Duration(seconds: 20));
    } on SocketException catch (e, st) {
      debugPrint('❌ clearCart network error: $e\n$st');
      throw AppException.from(e, st);
    } on TimeoutException catch (e, st) {
      debugPrint('❌ clearCart timeout: $e\n$st');
      throw AppException.from(e, st);
    } catch (e, st) {
      debugPrint('❌ clearCart unknown error: $e\n$st');
      throw AppException.from(e, st);
    }

    debugPrint('🟢 DELETE /cart/ → ${res.statusCode}');

    if (res.statusCode == 204 || res.statusCode == 200) {
      return;
    }

    throw _mapStatusToAppException(res, context: 'Failed to clear cart');
  }

  // POST /cart/checkout/
  Future<CartCheckoutResult> checkout(Map<String, dynamic> payload) async {
    final uri = Uri.parse(Api.cartCheckout);

    debugPrint('➡️ POST $uri (checkout)');
    debugPrint('   BODY: $payload');

    http.Response res;
    try {
      res = await client
          .post(
            uri,
            headers: _headers(),
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 30));
    } on SocketException catch (e, st) {
      debugPrint('❌ checkout network error: $e\n$st');
      throw AppException.from(e, st);
    } on TimeoutException catch (e, st) {
      debugPrint('❌ checkout timeout: $e\n$st');
      throw AppException.from(e, st);
    } catch (e, st) {
      debugPrint('❌ checkout unknown error: $e\n$st');
      throw AppException.from(e, st);
    }

    debugPrint('🟢 POST /cart/checkout/ → ${res.statusCode} BODY: ${res.body}');

    if (res.statusCode == 201 || res.statusCode == 200) {
      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      final ordersJson = (decoded['orders'] as List?) ?? [];
      final orders = ordersJson
          .whereType<Map<String, dynamic>>()
          .map((e) => OrderModel.fromJson(e))
          .toList();
      final msg = (decoded['message'] ?? '').toString();

      return CartCheckoutResult(orders: orders, message: msg);
    }

    throw _mapStatusToAppException(res, context: 'Checkout failed');
  }

  AppException _mapStatusToAppException(
    http.Response res, {
    required String context,
  }) {
    final code = res.statusCode;
    final body = res.body;

    debugPrint('❌ HTTP error $code for "$context": $body');

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

    if (code == 400) {
      return AppException(
        type: AppErrorType.validation,
        message: '$context (bad request): $body',
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
