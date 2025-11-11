import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'order_model.dart';
import 'order_service.dart';

class OrderController extends GetxController {
  final OrderService _service = OrderService();
  var orders = <OrderModel>[].obs;
  var isLoading = false.obs;
  var error = ''.obs;

  Future<void> loadOrders({required int userId}) async {
    try {
      isLoading.value = true;
      error.value = '';
      debugPrint('🔄 Loading orders for userId=$userId');
      orders.value = await _service.fetchOrders(userId);
      debugPrint('✅ Loaded ${orders.length} orders');
    } catch (e, st) {
      debugPrint('❌ loadOrders error: $e\n$st');
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<OrderModel?> getOrderById({required int userId, required int orderId}) async {
    try {
      debugPrint('🔄 Fetch order by id=$orderId for userId=$userId');
      final o = await _service.fetchOrderById(userId, orderId);
      return o;
    } catch (e, st) {
      debugPrint('❌ getOrderById error: $e\n$st');
      error.value = e.toString();
      return null;
    }
  }

  Future<OrderModel?> createOrder({required int userId, required Map<String, dynamic> body}) async {
    try {
      error.value = '';
      debugPrint('🧾 createOrder called for userId=$userId');
      final o = await _service.createOrder(userId, body);
      orders.insert(0, o);
      debugPrint('✅ Order created: id=${o.id}, reference=${o.reference}, status=${o.orderStatus}');
      return o;
    } catch (e, st) {
      debugPrint('❌ createOrder error: $e\n$st');
      error.value = e.toString();
      return null;
    }
  }
}
