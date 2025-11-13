import 'package:fire_alarm/others/theme/app_theme.dart';
import 'package:fire_alarm/others/widgets/time_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '/modules/users/user_controller.dart';
import '/modules/orders/order_controller.dart';
import '/modules/orders/order_model.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  late final OrderController _controller;
  late final UserController _userController;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<OrderController>()
        ? Get.find<OrderController>()
        : Get.put(OrderController());

    _userController = Get.isRegistered<UserController>()
        ? Get.find<UserController>()
        : Get.put(UserController());

    _userId = _userController.getStoredUserId();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_userId != null) {
        await _controller.loadOrders(userId: _userId!);
      } else {
        _controller.error.value = 'User ID not found.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: AppTheme().secondaryColor,
      ),
      body: Obx(() {
        if (_controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_controller.error.isNotEmpty) {
          return Center(child: Text(_controller.error.value));
        }

        if (_controller.orders.isEmpty) {
          return _buildEmptyState(context);
        }

        return RefreshIndicator(
          onRefresh: () async {
            if (_userId != null) {
              debugPrint('↻ Refreshing orders for user=$_userId');
              await _controller.loadOrders(userId: _userId!);
            }
          },
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: _controller.orders.length,
            itemBuilder: (context, index) {
              final order = _controller.orders[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                elevation: 3,
                child: ListTile(
                  leading: Icon(
                    Icons.shopping_bag_outlined,
                    color: order.orderStatus == 'paid'
                        ? Colors.green
                        : Colors.deepOrangeAccent,
                    size: 28,
                  ),
                  title: Text(
                    'Order #${order.reference}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Price: ৳${order.amount} • ${order.orderStatus.toUpperCase()}\n'),
                      const SizedBox(height: 1),
                      TimeField(
                        label: 'Ordered At',            
                        raw: order.orderedAt.toIso8601String(),
                        icon: Icons.schedule,
                        localeTag: 'en_US', // or 'bn_BD'
                        fallback: '—',
                      ),
                    ],
                  ),

                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showOrderDetailsDialog(context, order),
                ),
              );
            },
          ),
        );
      }),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('Order a new package'),
        onPressed: () => Get.toNamed('/index', arguments: {'tab': 2}),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildEmptyState(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.inventory_outlined,
                  color: Colors.deepOrange, size: 60),
              const SizedBox(height: 16),
              const Text(
                'No orders found',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              const Text(
                'You haven’t ordered any packages yet.\nTap below to get started!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 25),
              ElevatedButton.icon(
                icon: const Icon(Icons.shopping_cart_checkout),
                label: const Text('Order a new package'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Get.toNamed('/index', arguments: {'tab': 2}),
              ),
            ],
          ),
        ),
      );

  void _showOrderDetailsDialog(BuildContext context, OrderModel order) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Icon(Icons.receipt_long,
                    color: Colors.deepOrange, size: 50),
              ),
              const SizedBox(height: 2),
              Center(
                child: Text(
                  'ORDER #${order.reference}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                  ),
                ),
              ),
              const Divider(height: 25, thickness: 1.2),
              _row('Order ID', order.id.toString()),
              _row('Package ID', order.packageId.toString()),
              _row('Quantity', order.quantity.toString()),
              _row('Master Devices', order.numberOfMasterDevices.toString()),
              _row('Slave Devices', order.numberOfSlaveDevices.toString()),
              _row('Amount', '${order.amount} ${order.currency}'),
              _row('Status', order.orderStatus),
              //___________________Ordered At using TimeField___________________
              TimeField(
                    label: 'Ordered At',
                    raw: order.orderedAt.toIso8601String(),
                    icon: Icons.schedule,
                    localeTag: 'en_US',
                    fallback: '—',
                ),
              //________________________________________________________________
              const Divider(height: 25, thickness: 1.2),
              _row('Customer', order.customerName),
              _row('Phone', order.customerPhone),
              _row('Email', order.customerEmail),
              _row('City', order.customerCity),
              _row('Address', order.customerAddress),
              _row('Shipping', order.shippingAddress),
              const SizedBox(height: 15),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text('Close'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                '$label:',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.deepOrangeAccent,
                ),
              ),
            ),
            Expanded(
              flex: 5,
              child: Text(
                value.isEmpty ? '—' : value,
                style: const TextStyle(color: Colors.black),
              ),
            ),
          ],
        ),
      );
}
