import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'order_model.dart';
import 'order_service.dart';
import '/others/errors/app_error_handler.dart';

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
      final appEx = AppException.from(e, st);
      error.value = appEx.toUserMessage();
      AppErrorHandler.handle(appEx, stackTrace: st);
    } finally {
      isLoading.value = false;
    }
  }

  //__________________Get Order by ID___________________//
  Future<OrderModel?> getOrderById({
    required int userId,
    required int orderId,
  }) async {
    try {
      debugPrint('🔄 Fetch order by id=$orderId for userId=$userId');
      final o = await _service.fetchOrderById(userId, orderId);
      return o;
    } catch (e, st) {
      debugPrint('❌ getOrderById error: $e\n$st');
      final appEx = AppException.from(e, st);
      error.value = appEx.toUserMessage();
      AppErrorHandler.handle(appEx, stackTrace: st);
      return null;
    }
  }

  //__________________Create Order__________________//
  Future<OrderModel?> createOrder({
    required int userId,
    required Map<String, dynamic> body,
  }) async {
    try {
      error.value = '';
      debugPrint('🧾 createOrder called for userId=$userId');
      final o = await _service.createOrder(userId, body);
      orders.insert(0, o);
      debugPrint(
        '✅ Order created: id=${o.id}, reference=${o.reference}, status=${o.orderStatus}',
      );
      return o;
    } catch (e, st) {
      debugPrint('❌ createOrder error: $e\n$st');
      final appEx = AppException.from(e, st);
      error.value = appEx.toUserMessage();
      AppErrorHandler.handle(appEx, stackTrace: st);
      return null;
    }
  }


  //_______________Mark Order Paid via notify API_______________//
  Future<void> markOrderPaid({
    required int userId,
    required int orderId,
    required String transactionId,
  }) async {
    try {
      error.value = '';
      debugPrint(
        '🔄 notifyPayment for userId=$userId, orderId=$orderId, tx=$transactionId',
      );

      // Call backend to notify payment (marks order as paid)
      await _service.notifyPayment(
        orderId: orderId,
        transactionId: transactionId,
      );

      // Reload list so UI sees updated status
      await loadOrders(userId: userId);
    } catch (e, st) {
      debugPrint('❌ markOrderPaid error: $e\n$st');
      final appEx = AppException.from(e, st);
      error.value = appEx.toUserMessage();
      AppErrorHandler.handle(appEx, stackTrace: st);
    }
  }
}
