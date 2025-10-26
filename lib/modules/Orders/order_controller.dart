import 'package:fire_alarm/modules/Orders/order_service.dart';
import 'package:get/get.dart';
import '../../modules/orders/order_model.dart';

class OrderController extends GetxController {
  final OrderService _service = OrderService();

  var orders = <OrderModel>[].obs;
  var isLoading = false.obs;
  var error = ''.obs;

  Future<void> loadOrders({required int user_id}) async {
    try {
      isLoading.value = true;
      error.value = '';
      final fetchedOrders = await _service.fetchOrders(user_id: user_id);
      orders.assignAll(fetchedOrders);
    } catch (e) {
      error.value = 'Failed to load orders: $e';
    } finally {
      isLoading.value = false;
    }
  }
}
