import 'package:fire_alarm/others/utils/api.dart';
import '/modules/orders/order_model.dart';
import '/services/method_service.dart';

class OrderService {
  final MethodService _method = MethodService();

  Future<List<OrderModel>> fetchOrders({required int user_id}) async {
    final url = "${Api.orders}$user_id/"; // e.g., base-url/orders/1/
    final response = await _method.get(url);

    if (response is List) {
      return response.map((e) => OrderModel.fromJson(e)).toList();
    } else if (response['results'] != null) {
      // if backend paginates
      return (response['results'] as List)
          .map((e) => OrderModel.fromJson(e))
          .toList();
    } else {
      return [];
    }
  }
}
