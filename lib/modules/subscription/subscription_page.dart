import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '/others/theme/app_theme.dart';
import '/modules/subscription/subscription_controller.dart';
import '/modules/subscription/subscription_model.dart';
import '/modules/shurjopay/shurjopay_controller.dart';
import '/modules/shurjopay/shurjopay_checkout_page.dart';
import '/others/widgets/time_field.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  late final SubscriptionController _subCtrl;
  late final ShurjoPayController _spCtrl;

  @override
  void initState() {
    super.initState();

    _subCtrl = Get.isRegistered<SubscriptionController>()
        ? Get.find<SubscriptionController>()
        : Get.put(SubscriptionController());

    _spCtrl = Get.isRegistered<ShurjoPayController>()
        ? Get.find<ShurjoPayController>()
        : Get.put(ShurjoPayController());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _subCtrl.loadSubscriptions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Subscriptions'),
        backgroundColor: theme.secondaryColor,
      ),
      body: Obx(() {
        if (_subCtrl.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_subCtrl.error.isNotEmpty) {
          return Center(child: Text(_subCtrl.error.value));
        }

        if (_subCtrl.subscriptions.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () => _subCtrl.loadSubscriptions(),
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: _subCtrl.subscriptions.length,
            itemBuilder: (context, index) {
              final sub = _subCtrl.subscriptions[index];
              return _buildSubscriptionCard(sub);
            },
          ),
        );
      }),
    );
  }

  //*_____________________WIDGETS_______________________//

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.sensors_off_outlined,
              color: Colors.deepOrange,
              size: 56,
            ),
            SizedBox(height: 12),
            Text(
              'No subscriptions found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.amber,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Your devices do not have any active subscriptions yet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard(SubscriptionModel sub) {
    final bool canPay = sub.status == 'active' && sub.isAccessible;
    final int days = sub.daysRemaining;

    String expiresText;
    Color expiresColor;

    if (days > 0) {
      expiresText = 'Expires in $days day${days == 1 ? '' : 's'}';
      expiresColor = Colors.green.shade700;
    } else if (days == 0) {
      expiresText = 'Expires today';
      expiresColor = Colors.orange.shade700;
    } else {
      expiresText = 'Expired';
      expiresColor = Colors.red.shade700;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top line: device name + status
            Row(
              children: [
                const Icon(Icons.sensors, size: 26, color: Colors.deepOrange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    sub.device.deviceName.isEmpty
                        ? 'Device #${sub.device.id}'
                        : sub.device.deviceName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.deepOrange,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: sub.status == 'active'
                        ? Colors.green.withOpacity(0.15)
                        : Colors.red.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    sub.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: sub.status == 'active'
                          ? Colors.green.shade800
                          : Colors.red.shade800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'ID: ${sub.device.hardwareIdentifier} • Role: ${sub.device.deviceRole}',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 8),

            Text(
              '৳${sub.monthlyAmount} / month',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.deepOrange,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              expiresText,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: expiresColor,
              ),
            ),

            // 👇 Next Due using TimeField
            if (sub.nextDueAt != null) ...[
              const SizedBox(height: 4),
              TimeField(
                label: 'Next due',
                raw: sub.nextDueAt!.toIso8601String(),
                icon: Icons.schedule,
                localeTag: 'en_US',
                fallback: '—',
              ),
            ],

            const SizedBox(height: 12),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => _showChargesDialog(sub),
                  icon: const Icon(Icons.receipt_long),
                  label: const Text('View charges'),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: canPay ? () => _payForSubscription(sub) : null,
                  icon: const Icon(Icons.payment),
                  label: const Text('Pay now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showChargesDialog(SubscriptionModel sub) async {
    final charges = await _subCtrl.loadCharges(sub.id);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.receipt_long,
                      size: 40, color: Colors.deepOrange),
                  const SizedBox(height: 8),
                  Text(
                    'Charges for ${sub.device.deviceName.isEmpty ? 'Device #${sub.device.id}' : sub.device.deviceName}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.deepOrange,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (charges.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'No charges found for this subscription.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: charges.length,
                        itemBuilder: (_, i) {
                          final c = charges[i];
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              '৳${c.amount} • ${c.statusDisplay}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            // 👇 Period using TimeField widgets
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TimeField(
                                  label: 'Period start',
                                  raw: c.periodStart?.toIso8601String(),
                                  icon: Icons.play_arrow,
                                  localeTag: 'en_US',
                                  fallback: '—',
                                ),
                                TimeField(
                                  label: 'Period end',
                                  raw: c.periodEnd?.toIso8601String(),
                                  icon: Icons.stop,
                                  localeTag: 'en_US',
                                  fallback: '—',
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      label: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // 🧾 Payment flow for subscription:
  // 1) POST /subscriptions/me/<id>/topup/ (months=1)
  // 2) open ShurjoPay WebView with checkout_url + provider_reference
  // 3) on return => verify via ShurjoPayController
  // 4) reload subscriptions
  Future<void> _payForSubscription(SubscriptionModel sub) async {
    const int months = 1; // default topup period (1 month)

    if (!sub.isAccessible) {
      Get.snackbar(
        'Subscription',
        'This subscription is not accessible for payment right now.',
      );
      return;
    }

    // 1) Topup -> get checkout_url + transaction_id + charge.provider_reference
    final topup = await _subCtrl.topupSubscription(
      subscriptionId: sub.id,
      months: months,
    );

    if (topup == null) {
      Get.snackbar(
        'Payment failed',
        _subCtrl.error.value.isNotEmpty
            ? _subCtrl.error.value
            : 'Could not start subscription payment.',
      );
      return;
    }

    if (topup.checkoutUrl.isEmpty) {
      Get.snackbar('Payment failed', 'Checkout URL is missing.');
      return;
    }

    final providerRef = topup.charge.providerReference;
    final txId = topup.transactionId;

    // 2) Open ShurjoPay checkout
    final result = await Get.to(
      () => const ShurjoPayCheckoutPage(),
      arguments: {
        'checkoutUrl': topup.checkoutUrl,
        'orderId': providerRef, // e.g. NOK6926a5f579198
        'transactionId': txId,
      },
    );

    print('🔁 Returned from Checkout (SubscriptionPage) with: $result');

    bool paid = false;
    String verifyId = providerRef;

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
        print('🚪 User cancelled the subscription checkout.');
      } else if (kind == 'error') {
        paid = false;
        print(
          '⚠️ Subscription checkout error: ${result['reason']} ${result['detail'] ?? ''}',
        );
      }
    } else {
      paid = (result == true);
    }

    // ✅ Success / fail UX using ScaffoldMessenger
    if (paid) {
      await _subCtrl.loadSubscriptions();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription payment successful ✅'),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment failed!❌'),
            duration: Duration(seconds: 5),
          ),
        );
      }
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
