import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '/modules/users/user_controller.dart';
import '/modules/orders/order_controller.dart';
import '/modules/orders/order_model.dart';

class OrderPage extends StatelessWidget {
  const OrderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OrderController());
    final userController = Get.put(UserController());

    final userId = userController.getStoredUserId();

    if (userId != null) {
      controller.loadOrders(user_id: userId);
    } else {
      controller.error.value = 'User ID not found.';
      debugPrint("User ID not found in storage.");
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: Colors.deepOrangeAccent,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.error.isNotEmpty) {
          return Center(child: Text(controller.error.value));
        }

        if (controller.orders.isEmpty) {
          return const Center(child: Text('No orders found.'));
        }

        return RefreshIndicator(
          onRefresh: () => controller.loadOrders(user_id: userId!),
          child: ListView.builder(
            itemCount: controller.orders.length,
            itemBuilder: (context, index) {
              final OrderModel order = controller.orders[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                elevation: 2,
                child: ListTile(
                  leading: const Icon(
                    Icons.receipt_long,
                    color: Colors.deepOrangeAccent,
                  ),
                  title: Text(
                    'Order #${order.reference}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Amount: ${order.amount} ${order.currency}\n'
                    'Status: ${order.orderStatus.toUpperCase()}\n'
                    'Date: ${order.orderedAt.toLocal()}',
                  ),
                  trailing: const Icon(Icons.info_outline, size: 20),
                  onTap: () => _showOrderDetailsDialog(context, order),
                ),
              );
            },
          ),
        );
      }),
    );
  }

  /// 🔹 Show full order details in a styled dialog box
  void _showOrderDetailsDialog(BuildContext context, OrderModel order) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Icon(
                    Icons.receipt_long,
                    color: Colors.deepOrangeAccent,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    'ORDER #${order.reference}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrangeAccent,
                    ),
                  ),
                ),
                const Divider(height: 25, thickness: 1.2),

                // Order information
                _buildDetailRow('Order ID', order.id.toString()),
                _buildDetailRow('Package ID', order.packageId.toString()),
                _buildDetailRow('Quantity', order.quantity.toString()),
                _buildDetailRow('Amount', '${order.amount} ${order.currency}'),
                _buildDetailRow('Status', order.orderStatus.toUpperCase()),
                _buildDetailRow(
                    'Ordered At', order.orderedAt.toLocal().toString()),

                const Divider(height: 25, thickness: 1.2),

                // information
                _buildDetailRow('Name', order.customerName),
                _buildDetailRow('Phone', order.customerPhone),
                _buildDetailRow('Email', order.customerEmail),
                _buildDetailRow('City', order.customerCity),
                _buildDetailRow('Post Code', order.customerPostCode),
                _buildDetailRow('Customer Address', order.customerAddress),

                const Divider(height: 25, thickness: 1.2),

                _buildDetailRow('Shipping Address', order.shippingAddress),

                const SizedBox(height: 25),

                Align(
                  alignment: Alignment.center,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    label: const Text('Close'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrangeAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 🔹 Reusable helper row
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value.isEmpty ? 'N/A' : value,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}
