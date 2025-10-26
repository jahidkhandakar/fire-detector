import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '/modules/ShurjoPay/shurjopay_controller.dart';
import '/others/widgets/package_selector.dart';
import '/others/utils/api.dart';
import '/modules/Packages/package_controller.dart';
import '/modules/Packages/package_model.dart';

class PackagePage extends StatefulWidget {
  const PackagePage({super.key});

  @override
  State<PackagePage> createState() => _PackagePageState();
}

class _PackagePageState extends State<PackagePage> {
  final PackageController _controller = Get.put(PackageController());
  final String apiUrl = Api.packages;
  final _currency = NumberFormat.currency(locale: 'en_BD', symbol: '৳');

  final Map<int, int> masterQtyByPackage = {};
  final Map<int, int> slaveQtyByPackage  = {};

  @override
  void initState() {
    super.initState();
    _controller.loadPackages(apiUrl: apiUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (_controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_controller.error.isNotEmpty) {
          return Center(child: Text(_controller.error.value));
        }
        if (_controller.packages.isEmpty) {
          return const Center(child: Text('No packages available.'));
        }

        return RefreshIndicator(
          onRefresh: () => _controller.loadPackages(apiUrl: apiUrl),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _controller.packages.length,
            itemBuilder: (context, index) {
              final pkg = _controller.packages[index];
              return _buildPackageCard(pkg);
            },
          ),
        );
      }),
    );
  }

  Widget _buildPackageCard(PackageModel pkg) {
    final masters = masterQtyByPackage[pkg.id] ?? pkg.minQuantity;
    final slaves  = slaveQtyByPackage[pkg.id]  ?? 0;

    final devices            = masters + slaves;
    final upfrontDevicesCost = pkg.pricePerDevice * devices;
    final firstMonthMrf      = pkg.mrf * masters; // MRF only on masters
    final totalNow           = upfrontDevicesCost + firstMonthMrf;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(
                  _titleCase(pkg.name.isEmpty ? 'Unnamed Package' : pkg.name),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue[800]),
                ),
              ),
              _rangeChip(pkg.minQuantity, pkg.maxQuantity),
            ]),
            const SizedBox(height: 8),
            const Divider(height: 20),

            _rowIconTextValue(icon: Icons.sell, label: 'Price / Device', value: _currency.format(pkg.pricePerDevice)),
            const SizedBox(height: 10),
            _rowIconTextValue(icon: Icons.autorenew, label: 'MRF (per master)', value: pkg.mrf == 0 ? '—' : _currency.format(pkg.mrf)),

            const SizedBox(height: 14),
            const Divider(height: 20),

            Center(
              child: Text("How many devices do you need?", style: TextStyle(fontSize: 16, color: Colors.grey[800], fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Master selector
                Column(
                  children: [
                    Text("Master", style: TextStyle(fontSize: 16, color: Colors.grey[800], fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    PackageSelector(
                      min: pkg.minQuantity,
                      max: pkg.maxQuantity,
                      initial: masters,
                      onChanged: (v) => setState(() => masterQtyByPackage[pkg.id] = v),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                // Slave selector
                Column(
                  children: [
                    Text("Slave", style: TextStyle(fontSize: 16, color: Colors.grey[800], fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    PackageSelector(
                      min: 0,
                      max: pkg.maxQuantity,
                      initial: slaves,
                      onChanged: (v) => setState(() => slaveQtyByPackage[pkg.id] = v),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),
            Center(child: Text('Selected: $masters Master • $slaves Slave', style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w600))),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'First month MRF (masters only): ${firstMonthMrf == 0 ? '—' : _currency.format(firstMonthMrf)}',
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
                  onPressed: () async {
                    if (totalNow <= 0) {
                      Get.snackbar('Payment', 'Amount must be greater than 0');
                      return;
                    }
                    final payCtrl = Get.put(ShurjoPayController());

                    // 🔐 Use your provided fixed values for body:
                    final init = await payCtrl.startPayment({
                      "reference": "${pkg.id}",
                      "amount": totalNow,                 // MUST be > 0
                      "currency": "BDT",
                      "customer_name": "Jahid",
                      "customer_address": "Badda",
                      "customer_phone": "01700000000",
                      "customer_city": "Dhaka",
                      "customer_post_code": "1212",
                      "customer_email": "admin@admin.com",
                    });

                    if (init != null && init.checkoutUrl.isNotEmpty) {
                      final orderIdForVerify = init.spOrderId.isNotEmpty
                          ? init.spOrderId
                          : init.transactionId.toString();

                      // Await result from checkout (true=paid, false/cancel)
                      final ok = await Get.toNamed('/checkout', arguments: {
                        'checkoutUrl': init.checkoutUrl,
                        'orderId': orderIdForVerify,
                        'transactionId': init.transactionId, // you can use this with /status
                      });

                      if (ok == true) {
                        Get.snackbar('Order', 'Your order has been confirmed ✅');
                      } else {
                        Get.snackbar('Order', 'Payment did not complete');
                      }
                    } else {
                      Get.snackbar('Error', payCtrl.error.value.isNotEmpty ? payCtrl.error.value : 'Failed to start payment');
                    }
                  },
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

  Widget _rowIconTextValue({required IconData icon, required String label, required String value}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.black54),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w600))),
        Text(value, style: const TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _rangeChip(int minQ, int maxQ) {
    return Chip(
      label: Text('Qty: $minQ–$maxQ'),
      avatar: const Icon(Icons.format_list_numbered, size: 16, color: Colors.white),
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(children: [
              Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 12),
              Text(_titleCase(pkg.name), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _kvRow('ID', pkg.id.toString()),
              _kvRow('Quantity Range', '${pkg.minQuantity} – ${pkg.maxQuantity}'),
              _kvRow('Price per Device', _currency.format(pkg.pricePerDevice)),
              _kvRow('MRF (per master)', pkg.mrf == 0 ? '—' : _currency.format(pkg.mrf)),
              const SizedBox(height: 16),
            ]),
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
          Expanded(flex: 3, child: Text('$k:', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black87))),
          Expanded(flex: 5, child: Text(v, textAlign: TextAlign.end, style: const TextStyle(fontSize: 15, color: Colors.black54))),
        ],
      ),
    );
  }

  String _titleCase(String s) {
    if (s.isEmpty) return s;
    return s.split(' ').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
  }
}
