import 'package:get/get.dart';
import 'order_model.dart';
import 'order_service.dart';

class OrderController extends GetxController {
  final OrderService _service = OrderService();
  var orders = <OrderModel>[].obs;
  var isLoading = false.obs;
  var error = ''.obs;

  /// 🔹 Get all orders for the logged-in user
  Future<void> loadOrders({required int userId}) async {
    try {
      isLoading.value = true;
      error.value = '';
      orders.value = await _service.fetchOrders(userId);
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  /// 🔹 Get specific order details
  Future<OrderModel?> getOrderById({required int userId, required int orderId}) async {
    try {
      return await _service.fetchOrderById(userId, orderId);
    } catch (e) {
      error.value = e.toString();
      return null;
    }
  }

  /// 🔹 Create new order
  Future<OrderModel?> createOrder({required int userId, required Map<String, dynamic> body}) async {
    try {
      final order = await _service.createOrder(userId, body);
      orders.insert(0, order);
      return order;
    } catch (e) {
      error.value = e.toString();
      return null;
    }
  }
}
