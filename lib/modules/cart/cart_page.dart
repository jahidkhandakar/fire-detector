import 'package:fire_alarm/others/widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '/modules/cart/cart_controller.dart';
import '/modules/cart/cart_model.dart';
import '/modules/users/user_controller.dart';
import '/modules/users/user_model.dart';
import '/modules/orders/order_controller.dart';
import '/modules/orders/order_model.dart';
import '/modules/shurjopay/shurjopay_controller.dart';
import '/modules/shurjopay/shurjopay_checkout_page.dart';
import '/others/theme/app_theme.dart';
import '/others/widgets/custom_message.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  late final CartController _cartCtrl;
  late final UserController _userCtrl;
  late final OrderController _orderCtrl;
  late final ShurjoPayController _spCtrl;

  int? _userId;

  final _currency = NumberFormat.currency(locale: 'en_BD', symbol: '৳');

  // checkout form controllers
  final _shippingAddressCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _cityCtrl = TextEditingController(text: 'Dhaka');
  final _postCodeCtrl = TextEditingController(text: '1212');
  final _billingAddressCtrl = TextEditingController();

  String _paymentMethod = 'online'; // 'online' | 'cod'

  //*________________Helpers________________*//
  void _showSnack(String title, String message) {
    if (!mounted) return;
    debugPrint('🔔 SNACK [$title]: $message');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title: $message'),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    _cartCtrl =
        Get.isRegistered<CartController>()
            ? Get.find<CartController>()
            : Get.put(CartController(), permanent: true);

    _userCtrl =
        Get.isRegistered<UserController>()
            ? Get.find<UserController>()
            : Get.put(UserController(), permanent: true);

    _orderCtrl =
        Get.isRegistered<OrderController>()
            ? Get.find<OrderController>()
            : Get.put(OrderController(), permanent: true);

    _spCtrl =
        Get.isRegistered<ShurjoPayController>()
            ? Get.find<ShurjoPayController>()
            : Get.put(ShurjoPayController(), permanent: true);

    _userId = _userCtrl.getStoredUserId();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _cartCtrl.loadCart();
      _prefillFromUser(_userCtrl.me.value);
    });
  }

  @override
  void dispose() {
    _shippingAddressCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _cityCtrl.dispose();
    _postCodeCtrl.dispose();
    _billingAddressCtrl.dispose();
    super.dispose();
  }

  void _prefillFromUser(UserModel? u) {
    if (u == null) return;

    final fullName = u.fullName;
    final address = u.address;
    final phone = u.phoneNumber;
    final email = u.email;

    if (fullName != null && fullName.trim().isNotEmpty) {
      _nameCtrl.text = fullName.trim();
    }
    if (address != null && address.trim().isNotEmpty) {
      _shippingAddressCtrl.text = address.trim();
      _billingAddressCtrl.text = address.trim();
    }
    if (phone.trim().isNotEmpty) {
      _phoneCtrl.text = phone.trim();
    }
    if (email.trim().isNotEmpty) {
      _emailCtrl.text = email.trim();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        backgroundColor: AppTheme().secondaryColor,
      ),
      body: Obx(() {
        if (_cartCtrl.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final cart = _cartCtrl.cart.value;

        if (cart == null || cart.items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.shopping_cart_outlined,
                    size: 60,
                    color: Colors.deepOrange,
                  ),
                  const SizedBox(height: 16),
                  CustomMessage(message: 'Your cart is empty.', icon: '🛒'),
                  const SizedBox(height: 8),
                  const Text(
                    'Browse packages and add them to your cart to get started.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Get.offAllNamed('/index', arguments: {'tab': 2});
                    },
                    icon: const Icon(Icons.shopping_bag),
                    label: const Text('Browse Packages'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme().secondaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => _cartCtrl.loadCart(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildCartItems(
                  cart,
                  isUpdating: _cartCtrl.isUpdatingItem.value,
                ),
                const SizedBox(height: 16),
                _buildCartSummary(cart),
                const SizedBox(height: 16),
                _buildCheckoutForm(),
                const SizedBox(height: 16),
                _buildPlaceOrderButton(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      }),
    );
  }

  //*________________WIDGETS________________*//
  Widget _buildCartItems(CartModel cart, {required bool isUpdating}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(message: 'Items (${cart.itemCount})'),
        const SizedBox(height: 8),

        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cart.items.length,
          itemBuilder: (context, index) {
            final item = cart.items[index];
            final syncing = _cartCtrl.hasPendingForItem(item.id);

            final price = item.pkg.pricePerDevice; // double
            final mrf = item.pkg.mrf; // double

            final masters = item.numberOfMasterDevices;
            final slaves = item.numberOfSlaveDevices;
            final qty = item.quantity;

            final deviceTotal = price * qty;
            final mrfTotal = mrf * masters;
            final grandTotal =
                deviceTotal + mrfTotal; // should match line_total

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // header
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.pkg.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.deepOrange
                            ),
                          ),
                        ),
                        if (syncing)
                          const Text(
                            'syncing…',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed:
                              isUpdating
                                  ? null
                                  : () => _cartCtrl.removeItem(item.id),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // POS style breakdown
                    _billRow(
                      'Master',
                      '${_currency.format(price)} × $masters',
                      _currency.format(price * masters),
                    ),
                    _billRow(
                      'Slave',
                      '${_currency.format(price)} × $slaves',
                      _currency.format(price * slaves),
                    ),
                    const Divider(height: 14),
                    _billRow(
                      'MRF',
                      '${_currency.format(mrf)} × $masters',
                      _currency.format(mrfTotal),
                    ),
                    const Divider(height: 14),
                    _billRow(
                      'Total',
                      '',
                      _currency.format(grandTotal),
                      isBold: true,
                    ),

                    const SizedBox(height: 10),

                    // steppers: choose master vs slave
                    Row(
                      children: [
                        Expanded(
                          child: _stepper(
                            label: 'Master',
                            value: masters,
                            onMinus:
                                isUpdating
                                    ? null
                                    : () =>
                                        _cartCtrl.changeMastersLocal(item, -1),
                            onPlus:
                                isUpdating
                                    ? null
                                    : () =>
                                        _cartCtrl.changeMastersLocal(item, 1),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _stepper(
                            label: 'Slave',
                            value: slaves,
                            onMinus:
                                isUpdating
                                    ? null
                                    : () =>
                                        _cartCtrl.changeSlavesLocal(item, -1),
                            onPlus:
                                isUpdating
                                    ? null
                                    : () =>
                                        _cartCtrl.changeSlavesLocal(item, 1),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // small hint row
                    Text(
                      'Qty: $qty  •  Device: ${_currency.format(price)} each  •  MRF: ${_currency.format(mrf)} per Master',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _billRow(
    String left,
    String mid,
    String right, {
    bool isBold = false,
  }) {
    final style = TextStyle(
      fontSize: 13,
      fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
      color: Colors.deepOrange
    );

    return Row(
      children: [
        Expanded(child: Text(left, style: style)),
        if (mid.isNotEmpty)
          Expanded(
            child: Text(
              mid,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          )
        else
          const Spacer(),
        Text(right, style: style),
      ],
    );
  }

  Widget _stepper({
    required String label,
    required int value,
    required VoidCallback? onMinus,
    required VoidCallback? onPlus,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.deepOrange,
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: onMinus,
          ),
          Text(
            value.toString(),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: Colors.deepOrange
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.add_circle_outline),
            onPressed: onPlus,
          ),
        ],
      ),
    );
  }

  Widget _buildCartSummary(CartModel cart) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomText(message: ' Subtotal:', icon: '🛒'),
            Text(
              _currency.format(cart.totalAsDouble),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(message: 'Checkout Information', icon: '📝'),
        const SizedBox(height: 8),
        TextField(
          controller: _shippingAddressCtrl,
          decoration: const InputDecoration(
            labelText: 'Shipping Address *',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _cityCtrl,
                decoration: const InputDecoration(
                  labelText: 'City',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _postCodeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Post Code',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _billingAddressCtrl,
                decoration: const InputDecoration(
                  labelText: 'Billing Address (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        CustomText(message: 'Select Payment Method', icon: '💳'),
        Card(
          child: Column(
            children: [
              RadioListTile<String>(
                value: 'online',
                groupValue: _paymentMethod,
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _paymentMethod = v);
                },
                title: const Text('Pay Now (Online)'),
                secondary: const Icon(Icons.payment),
              ),
              const Divider(height: 0),
              RadioListTile<String>(
                value: 'cod',
                groupValue: _paymentMethod,
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _paymentMethod = v);
                },
                title: const Text('Cash on Delivery'),
                secondary: const Icon(Icons.money),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceOrderButton() {
    return Obx(
      () => SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _cartCtrl.isCheckingOut.value ? null : () => _placeOrder(),
          icon:
              _cartCtrl.isCheckingOut.value
                  ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Icon(Icons.check_circle_outline),
          label: Text(
            _paymentMethod == 'cod' ? 'Place COD Order' : 'Place Online Order',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme().secondaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Future<void> _placeOrder() async {
    final cart = _cartCtrl.cart.value;
    debugPrint(
      '🧾 _placeOrder() called | cartId=${cart?.id} items=${cart?.items.length ?? 0} total=${cart?.total}',
    );
    if (cart == null || cart.items.isEmpty) {
      _showSnack('Cart', 'Your cart is empty.');
      return;
    }

    if (_shippingAddressCtrl.text.trim().isEmpty) {
      _showSnack('Checkout', 'Shipping address is required.');
      return;
    }

    if (_userId == null) {
      _showSnack('Checkout', 'Please login first.');
      return;
    }

    final payload = {
      'shipping_address': _shippingAddressCtrl.text.trim(),
      'customer_name': _nameCtrl.text.trim(),
      'customer_phone': _phoneCtrl.text.trim(),
      'customer_email': _emailCtrl.text.trim(),
      'customer_city': _cityCtrl.text.trim(),
      'customer_post_code': _postCodeCtrl.text.trim(),
      'customer_address':
          _billingAddressCtrl.text.trim().isEmpty
              ? _shippingAddressCtrl.text.trim()
              : _billingAddressCtrl.text.trim(),
      'currency': 'BDT',
      'payment_method': _paymentMethod, // 'online' or 'cod'
    };

    final res = await _cartCtrl.checkout(payload);
    if (res == null || res.orders.isEmpty) {
      final err =
          _cartCtrl.error.value.isNotEmpty
              ? _cartCtrl.error.value
              : 'Failed to create order(s) from cart.';
      _showSnack('Checkout', err);
      return;
    }

    if (res.orders.length != 1) {
      // Your frontend is enforcing single package, so this should never happen.
      debugPrint('🚨 Backend returned multiple orders: ${res.orders.length}');
      _showSnack(
        'Checkout',
        'Something went wrong (multiple orders created). Please clear the cart and try again.',
      );
      return;
    }

    final firstOrder = res.orders.first;

    if (_paymentMethod == 'cod') {
      // COD: no online payment; just show confirmation
      await _orderCtrl.loadOrders(userId: _userId!);
      if (!mounted) return;

      await showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text('Order Placed!'),
              content: Text(
                'Order #${firstOrder.reference}\n\n'
                'Payment: Cash on Delivery\n'
                'Status: Pending / Awaiting Delivery\n\n'
                'Please keep ৳${firstOrder.amount} ready.',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.deepOrange,
                    ),
                  ),
                ),
              ],
            ),
      );

      Get.offAllNamed('/orders');
    } else {
      // Online payment: go through ShurjoPay flow
      await _handleOnlinePayment(firstOrder);
    }
  }

  Future<void> _handleOnlinePayment(OrderModel order) async {
    if (_userId == null) {
      _showSnack('Payment', 'User not found. Please login again.');
      return;
    }

    final double amount = double.tryParse(order.amount) ?? 0;
    if (amount <= 0) {
      _showSnack('Payment', 'Invalid amount for this order.');
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

    final init = await _spCtrl.startPayment(payload);
    if (init == null || init.checkoutUrl.isEmpty) {
      _showSnack(
        'Payment failed',
        _spCtrl.error.value.isNotEmpty
            ? _spCtrl.error.value
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

    print('🔁 Returned from Checkout (CartPage) with: $result');

    bool paid = false;
    String verifyId = init.spOrderId;

    if (result is Map) {
      final kind = result['kind'];

      if (result['orderId'] is String &&
          (result['orderId'] as String).isNotEmpty) {
        verifyId = result['orderId'] as String;
      }

      if (kind == 'return') {
        final ret = await _spCtrl.returnPayment(verifyId);
        paid = ret != null && _isSuccess(ret);
        print('🧪 Return verify: paid=$paid, sp_code=${ret?.spCode}');

        if (!paid) {
          final ver = await _spCtrl.verifyPayment(verifyId);
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
      await _orderCtrl.markOrderPaid(
        userId: _userId!,
        orderId: order.id,
        transactionId: init.transactionId.toString(),
      );

      _showSnack('Payment successful', 'Order marked as PAID ✅');
      Get.offAllNamed('/orders');
    } else {
      _showSnack('Payment cancelled', 'Payment not completed.');
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
