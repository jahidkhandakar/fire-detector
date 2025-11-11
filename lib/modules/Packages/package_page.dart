import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '/modules/ShurjoPay/shurjopay_controller.dart';
import '/others/widgets/package_selector.dart';
import '/others/utils/api.dart';
import '/modules/Packages/package_controller.dart';
import '/modules/Packages/package_model.dart';
import '/modules/users/user_controller.dart';
import '/modules/users/user_model.dart';
import '/modules/orders/order_controller.dart';
import '/modules/orders/order_model.dart';
import 'package:get_storage/get_storage.dart';

class PackagePage extends StatefulWidget {
  const PackagePage({super.key});

  @override
  State<PackagePage> createState() => _PackagePageState();
}

class _PackagePageState extends State<PackagePage> {
  final PackageController _pkgCtrl = Get.put(PackageController());
  final OrderController _orderCtrl = Get.put(OrderController(), permanent: true);
  final UserController _userCtrl = Get.put(UserController(), permanent: true);

  final String apiUrl = Api.packages;
  final _currency = NumberFormat.currency(locale: 'en_BD', symbol: '৳');

  final Map<int, int> masterQtyByPackage = {};
  final Map<int, int> slaveQtyByPackage = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pkgCtrl.packages.isEmpty && !_pkgCtrl.isLoading.value) {
        _pkgCtrl.loadPackages(apiUrl: apiUrl);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (_pkgCtrl.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_pkgCtrl.error.isNotEmpty) {
          return Center(child: Text(_pkgCtrl.error.value));
        }
        if (_pkgCtrl.packages.isEmpty) {
          return const Center(child: Text('No packages available.'));
        }

        return RefreshIndicator(
          onRefresh: () => _pkgCtrl.loadPackages(apiUrl: apiUrl),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _pkgCtrl.packages.length,
            itemBuilder: (context, index) {
              final pkg = _pkgCtrl.packages[index];
              return _buildPackageCard(pkg);
            },
          ),
        );
      }),
    );
  }

  Widget _buildPackageCard(PackageModel pkg) {
    final masters = masterQtyByPackage[pkg.id] ?? pkg.minQuantity;
    final slaves = slaveQtyByPackage[pkg.id] ?? pkg.minQuantity;

    final devices = masters + slaves;
    final upfrontDevicesCost = pkg.pricePerDevice * devices;
    final firstMonthMrf = pkg.mrf * masters; // MRF only on masters
    final totalNow = upfrontDevicesCost + firstMonthMrf;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _titleCase(pkg.name.isEmpty ? 'Unnamed Package' : pkg.name),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                ),
                _rangeChip(pkg.minQuantity, pkg.maxQuantity),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 20),

            _rowIconTextValue(
              icon: Icons.sell,
              label: 'Price / Device',
              value: _currency.format(pkg.pricePerDevice),
            ),
            const SizedBox(height: 10),
            _rowIconTextValue(
              icon: Icons.autorenew,
              label: 'MRF (per master)',
              value: pkg.mrf == 0 ? '—' : _currency.format(pkg.mrf),
            ),

            const SizedBox(height: 14),
            const Divider(height: 20),

            Center(
              child: Text(
                "How many devices do you need?",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Master selector
                Column(
                  children: [
                    Text(
                      "Master",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[800],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    PackageSelector(
                      min: pkg.minQuantity,
                      max: pkg.maxQuantity,
                      initial: masters,
                      onChanged: (v) =>
                          setState(() => masterQtyByPackage[pkg.id] = v),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                // Slave selector
                Column(
                  children: [
                    Text(
                      "Slave",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[800],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    PackageSelector(
                      min: pkg.minQuantity,
                      max: pkg.maxQuantity,
                      initial: slaves,
                      onChanged: (v) =>
                          setState(() => slaveQtyByPackage[pkg.id] = v),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),
            Center(
              child: Text(
                'Selected: $masters Master • $slaves Slave',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'First month MRF (masters only): ${firstMonthMrf == 0 ? "—" : _currency.format(firstMonthMrf)}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[800],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                'Total Price: ${_currency.format(totalNow)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
            ),

            const SizedBox(height: 14),
            const Divider(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showPackageDetails(pkg),
                  icon: const Icon(Icons.info_outline),
                  label: const Text('Details'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () => _handleSelect(pkg, masters, slaves, totalNow),
                  icon: const Icon(Icons.shopping_cart_checkout),
                  label: const Text('Select'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSelect(
    PackageModel pkg,
    int masters,
    int slaves,
    double totalNow,
  ) async {
    if (totalNow <= 0) {
      Get.snackbar('Payment', 'Amount must be greater than 0');
      return;
    }

    final userId = _userCtrl.getStoredUserId();
    if (userId == null) {
      Get.snackbar('Order', 'Please login first');
      return;
    }

    // pull user info (safe fallbacks)
    final UserModel? u = _userCtrl.me.value;
    final String customerName = (u?.fullName?.trim().isNotEmpty ?? false)
        ? u!.fullName!.trim()
        : (u?.email.split('@').first ?? 'Customer');
    final String customerAddress =
        (u?.address?.trim().isNotEmpty ?? false) ? u!.address!.trim() : 'Dhaka, Bangladesh';
    final String customerPhone =
        (u?.phoneNumber.trim().isNotEmpty ?? false) ? u!.phoneNumber.trim() : '01700000000';
    final String customerEmail =
        (u?.email.trim().isNotEmpty ?? false) ? u!.email.trim() : 'customer@example.com';
    const String customerCity = 'Dhaka';
    const String customerPostCode = '1212';

    // 1) Create Order FIRST (server source of truth) — note `package_id`
    final int devices = masters + slaves;

    final orderBody = {
      "package_id": pkg.id, // ✅ server expects `package_id`
      "quantity": devices,
      "amount": totalNow.toStringAsFixed(2), // if server expects number, send `totalNow`
      "currency": "BDT",
      "number_of_master_devices": masters,
      "number_of_slave_devices": slaves,
      "customer_name": customerName,
      "customer_address": customerAddress,
      "customer_phone": customerPhone,
      "customer_city": customerCity,
      "customer_post_code": customerPostCode,
      "customer_email": customerEmail,
      // "shipping_address": customerAddress, // (optional)
    };

    // 🔍 Visibility for debugging
    debugPrint('🧾 About to create order with body => $orderBody');
    debugPrint('🔐 Access token exists? ${GetStorage().hasData("access")}');

    OrderModel? created;
    try {
      created = await _orderCtrl.createOrder(userId: userId, body: orderBody);
    } catch (e) {
      Get.snackbar('Order', 'Failed to create order');
      return;
    }

    if (created == null) {
      final errText =
          _orderCtrl.error.value.isNotEmpty ? _orderCtrl.error.value : 'Failed to create order';
      Get.snackbar('Order', errText, duration: const Duration(seconds: 4));
      return;
    }

    // 2) Initiate ShurjoPay using server order data (reference/amount)
    final payCtrl = Get.put(ShurjoPayController());
    final double amountFromServer = double.tryParse(created.amount) ?? totalNow;

    final init = await payCtrl.startPayment({
      "reference": created.reference, // tie payment to server order
      "amount": amountFromServer,
      "currency": created.currency.isNotEmpty ? created.currency : "BDT",
      "customer_name": customerName,
      "customer_address": customerAddress,
      "customer_phone": customerPhone,
      "customer_city": customerCity,
      "customer_post_code": customerPostCode,
      "customer_email": customerEmail,
    });

    if (init == null || init.checkoutUrl.isEmpty) {
      Get.snackbar(
        'Error',
        payCtrl.error.value.isNotEmpty ? payCtrl.error.value : 'Failed to start payment',
      );
      _markLocalOrderStatus(_orderCtrl, created, 'not_paid');
      await _orderCtrl.loadOrders(userId: userId);
      return;
    }

    final orderIdForVerify =
        init.spOrderId.isNotEmpty ? init.spOrderId : init.transactionId.toString();

    // 3) Open checkout — expects a Map result {kind: return|cancel|error, orderId?}
    final result = await Get.toNamed(
      '/checkout',
      arguments: {
        'checkoutUrl': init.checkoutUrl,
        'orderId': orderIdForVerify,
        'transactionId': init.transactionId,
      },
    );

    print('🔁 Returned from Checkout with: $result');

    // 4) Verify and show only one snackbar
    bool paid = false;
    String verifyId = orderIdForVerify;

    if (result is Map) {
      final kind = result['kind'];
      if (result['orderId'] is String && (result['orderId'] as String).isNotEmpty) {
        verifyId = result['orderId'] as String;
      }

      if (kind == 'return') {
        final ret = await payCtrl.returnPayment(verifyId);
        paid = ret != null && _isSuccess(ret);
        print('🧪 Return verify: paid=$paid, sp_code=${ret?.spCode}');

        if (!paid) {
          final ver = await payCtrl.verifyPayment(verifyId);
          paid = ver != null && _isSuccess(ver);
          print('🧪 POST verify: paid=$paid, sp_code=${ver?.spCode}');
        }
      } else if (kind == 'cancel') {
        paid = false;
        print('🚪 User cancelled the checkout.');
      } else if (kind == 'error') {
        paid = false;
        print('⚠️ Checkout error: ${result['reason']} ${result['detail'] ?? ''}');
      }
    } else {
      // Fallback if older route returns bool
      paid = (result == true);
    }

    if (paid) {
      print('🔔 SNACK [Payment]: Payment successful ✅');
      Get.snackbar('Payment', 'Payment successful ✅');
      _markLocalOrderStatus(_orderCtrl, created, 'paid');
      await _orderCtrl.loadOrders(userId: userId);
      Get.toNamed('/index', arguments: {'tab': 3}); // → History tab
    } else {
      print('🔔 SNACK [Payment]: Payment cancelled/failed');
      Get.snackbar('Payment', 'Payment cancelled');
      _markLocalOrderStatus(_orderCtrl, created, 'not_paid');
      await _orderCtrl.loadOrders(userId: userId);
    }
  }

  // success iff spCode == '1000'
  bool _isSuccess(dynamic verifyOrReturnModel) {
    try {
      final spCode = verifyOrReturnModel.spCode?.toString();
      return spCode == '1000';
    } catch (_) {
      return false;
    }
  }

  void _markLocalOrderStatus(OrderController ctrl, OrderModel created, String status) {
    final idx = ctrl.orders.indexWhere((o) => o.id == created.id);
    if (idx == -1) return;
    final curr = ctrl.orders[idx];
    ctrl.orders[idx] = OrderModel(
      id: curr.id,
      user: curr.user,
      packageId: curr.packageId,
      quantity: curr.quantity,
      amount: curr.amount,
      currency: curr.currency,
      reference: curr.reference,
      customerName: curr.customerName,
      customerAddress: curr.customerAddress,
      customerPhone: curr.customerPhone,
      customerCity: curr.customerCity,
      customerPostCode: curr.customerPostCode,
      customerEmail: curr.customerEmail,
      orderStatus: status,
      gatewayTransactionId: curr.gatewayTransactionId,
      gatewayResponse: curr.gatewayResponse,
      shippingAddress: curr.shippingAddress,
      numberOfMasterDevices: curr.numberOfMasterDevices,
      numberOfSlaveDevices: curr.numberOfSlaveDevices,
      orderedAt: curr.orderedAt,
    );
  }

  Widget _rowIconTextValue({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.black54),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey[800],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _rangeChip(int minQ, int maxQ) {
    return Chip(
      label: Text('Qty: $minQ–$maxQ'),
      avatar: const Icon(
        Icons.format_list_numbered,
        size: 16,
        color: Colors.white,
      ),
      labelStyle: const TextStyle(color: Colors.white),
      backgroundColor: Colors.blueAccent,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  void _showPackageDetails(PackageModel pkg) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _titleCase(pkg.name),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _kvRow('ID', pkg.id.toString()),
                _kvRow('Quantity Range', '${pkg.minQuantity} – ${pkg.maxQuantity}'),
                _kvRow('Price per Device', _currency.format(pkg.pricePerDevice)),
                _kvRow('MRF (per master)', pkg.mrf == 0 ? '—' : _currency.format(pkg.mrf)),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _kvRow(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              '$k:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              v,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 15, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  String _titleCase(String s) {
    if (s.isEmpty) return s;
    return s
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}
