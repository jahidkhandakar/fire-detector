import 'package:fire_alarm/others/widgets/custom_message.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '/others/theme/app_theme.dart';
import '/others/widgets/time_field.dart';
import '/modules/users/user_controller.dart';
import '/modules/orders/order_controller.dart';
import '/modules/orders/order_model.dart';
import '/modules/shurjopay/shurjopay_controller.dart';
import '/modules/shurjopay/shurjopay_checkout_page.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  late final OrderController _controller;
  late final UserController _userController;
  late final ShurjoPayController _spController;

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

    _spController = Get.isRegistered<ShurjoPayController>()
        ? Get.find<ShurjoPayController>()
        : Get.put(ShurjoPayController());

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
              await _controller.loadOrders(userId: _userId!);
            }
          },
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: _controller.orders.length,
            itemBuilder: (context, index) {
              final order = _controller.orders[index];
              final isPaid = order.orderStatus == 'paid';
              final isCod = order.paymentMethod == 'cod';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                elevation: 3,
                child: ListTile(
                  leading: Icon(
                    Icons.shopping_bag_outlined,
                    color: isPaid
                        ? Colors.green
                        : (isCod ? Colors.blueAccent : Colors.deepOrangeAccent),
                    size: 28,
                  ),
                  title: Text(
                    'Order #${order.reference}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '৳${order.amount}  •  '
                        '${isCod ? 'COD' : 'Online'}  •  ${order.orderStatus.toUpperCase()}\n',
                      ),
                      const SizedBox(height: 1),
                      TimeField(
                        label: 'Ordered At',
                        raw: order.orderedAt.toIso8601String(),
                        icon: Icons.schedule,
                        localeTag: 'en_US',
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
        backgroundColor: AppTheme().secondaryColor,
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
              const Icon(
                Icons.inventory_outlined,
                color: Colors.deepOrange,
                size: 60,
              ),
              const SizedBox(height: 16),
              CustomMessage(message: 'No orders found.', icon: '🛒'),
              const SizedBox(height: 10),
              const Text(
                'You haven’t ordered any packages yet.\nTap below to get started!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      );

  void _showOrderDetailsDialog(BuildContext context, OrderModel order) {
    final isOnline = order.paymentMethod == 'online';
    final isPaid = order.orderStatus == 'paid';

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Icon(
                  Icons.receipt_long,
                  color: Colors.deepOrange,
                  size: 50,
                ),
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
              _row('Payment', order.paymentMethod.toUpperCase()),
              _row('Status', order.orderStatus),
              TimeField(
                label: 'Ordered At',
                raw: order.orderedAt.toIso8601String(),
                icon: Icons.schedule,
                localeTag: 'en_US',
                fallback: '—',
              ),
              const Divider(height: 25, thickness: 1.2),
              _row('Customer', order.customerName),
              _row('Phone', order.customerPhone),
              _row('Email', order.customerEmail),
              _row('City', order.customerCity),
              _row('Address', order.customerAddress),
              _row('Shipping', order.shippingAddress),
              const SizedBox(height: 20),

              // Show Pay Now only if ONLINE and not paid
              if (isOnline && !isPaid) ...[
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context); // close dialog
                      _payForOrder(order);
                    },
                    icon: const Icon(Icons.payment),
                    label: const Text('Pay Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],

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

  Future<void> _payForOrder(OrderModel order) async {
    if (_userId == null) {
      Get.snackbar('Error', 'User not found. Please login again.');
      return;
    }

    final double amount = double.tryParse(order.amount) ?? 0;
    if (amount <= 0) {
      Get.snackbar('Error', 'Invalid amount for this order.');
      return;
    }

    final payload = {
      'reference': order.reference,
      'amount': amount,
      'currency': order.currency.isNotEmpty ? order.currency : 'BDT',
      'customer_name': order.customerName,
      'customer_address': order.customerAddress,
      'customer_phone': order.customerPhone,
      'customer_city': order.customerCity,
      'customer_post_code':
          order.customerPostCode.isNotEmpty ? order.customerPostCode : '1212',
      'customer_email': order.customerEmail,
    };

    final init = await _spController.startPayment(payload);
    if (init == null || init.checkoutUrl.isEmpty) {
      Get.snackbar(
        'Payment failed',
        _spController.error.value.isNotEmpty
            ? _spController.error.value
            : 'Could not start payment.',
      );
      return;
    }

    final result = await Get.to(
      () => const ShurjoPayCheckoutPage(),
      arguments: {
        'checkoutUrl': init.checkoutUrl,
        'orderId': init.spOrderId,
        'transactionId': init.transactionId,
      },
    );

    print('🔁 Returned from Checkout (OrderPage) with: $result');

    bool paid = false;
    String verifyId = init.spOrderId;

    if (result is Map) {
      final kind = result['kind'];

      if (result['orderId'] is String &&
          (result['orderId'] as String).isNotEmpty) {
        verifyId = result['orderId'] as String;
      }

      if (kind == 'return') {
        final ret = await _spController.returnPayment(verifyId);
        paid = ret != null && _isSuccess(ret);
        print('🧪 Return verify: paid=$paid, sp_code=${ret?.spCode}');

        if (!paid) {
          final ver = await _spController.verifyPayment(verifyId);
          paid = ver != null && _isSuccess(ver);
          print('🧪 POST verify: paid=$paid, sp_code=${ver?.spCode}');
        }
      } else if (kind == 'cancel') {
        paid = false;
        print('🚪 User cancelled the checkout.');
      } else if (kind == 'error') {
        paid = false;
        print(
          '⚠️ Checkout error: ${result['reason']} ${result['detail'] ?? ''}',
        );
      }
    } else {
      paid = (result == true);
    }

    if (paid) {
      await _controller.markOrderPaid(
        userId: _userId!,
        orderId: order.id,
        transactionId: init.transactionId.toString(),
      );

      Get.snackbar('Payment successful', 'Order marked as PAID ✅');
    } else {
      Get.snackbar('Payment cancelled', 'Payment not completed.');
    }
  }

  bool _isSuccess(dynamic verifyOrReturnModel) {
    try {
      final spCode = verifyOrReturnModel.spCode?.toString();
      return spCode == '1000';
    } catch (_) {
      return false;
    }
  }
}
