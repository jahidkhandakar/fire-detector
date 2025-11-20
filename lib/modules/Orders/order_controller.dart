import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'order_model.dart';
import 'order_service.dart';

class OrderController extends GetxController {
  final OrderService _service = OrderService();
  var orders = <OrderModel>[].obs;
  var isLoading = false.obs;
  var error = ''.obs;

  //_____________________Load Orders_____________________//
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
  //__________________Get Order by ID___________________//
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
  //__________________Create Order__________________//
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
  //_____________________Mark Order Paid_____________________//
  Future<void> markOrderPaid({
    required int userId,
    required int orderId,
  }) async {
    try {
      error.value = '';
      // Call backend to set order_status = "paid"
      await _service.updateOrderStatus(
        userId: userId,
        orderId: orderId,
        status: 'paid',
      );

      // simplest + clean: reload list so UI updates
      await loadOrders(userId: userId);
    } catch (e, st) {
      debugPrint('❌ markOrderPaid error: $e\n$st');
      error.value = e.toString();
    }
  }
}
