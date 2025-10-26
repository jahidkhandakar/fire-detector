import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'shurjopay_controller.dart';

class ShurjoPayCheckoutPage extends StatefulWidget {
  const ShurjoPayCheckoutPage({super.key});

  @override
  State<ShurjoPayCheckoutPage> createState() => _ShurjoPayCheckoutPageState();
}

class _ShurjoPayCheckoutPageState extends State<ShurjoPayCheckoutPage> {
  final ShurjoPayController controller = Get.put(ShurjoPayController());
  late final WebViewController webViewController;

  late final String checkoutUrl; // from initiate
  late final String orderId;     // sp_order_id (for verify/return/cancel)
  int? transactionId;            // optional: for /status (not used here)

  final ValueNotifier<double> _progress = ValueNotifier<double>(0);
  bool _handled = false; // prevent double-handling on rapid redirects

  @override
  void initState() {
    super.initState();

    final args = (Get.arguments ?? {}) as Map;
    checkoutUrl  = (args['checkoutUrl'] ?? '') as String;
    orderId      = (args['orderId'] ?? '') as String;
    transactionId = args['transactionId'] as int?;

    if (checkoutUrl.isEmpty || orderId.isEmpty) {
      Future.microtask(() {
        Get.snackbar('Error', 'Missing payment info.');
        Get.back(result: false);
      });
      return;
    }

    if (Platform.isAndroid) {
      WebViewPlatform.instance; // ensure webview initialized
    }

    webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) => _progress.value = p / 100.0,
          onNavigationRequest: (navReq) {
            if (_handled) return NavigationDecision.prevent;

            final url = navReq.url;
            final lower = url.toLowerCase();

            // Adjust these if your backend uses different paths/params
            final isReturn = lower.contains('/shurjopay/return') || lower.contains('status=success');
            final isCancel = lower.contains('/shurjopay/cancel') || lower.contains('status=failed') || lower.contains('cancel');

            // Try to pick up order_id from the URL; fall back to passed arg
            final uri = Uri.tryParse(url);
            final orderInUrl = uri?.queryParameters['order_id'];
            final idToUse = (orderInUrl?.isNotEmpty ?? false) ? orderInUrl! : orderId;

            if (isReturn) {
              _handled = true;
              _handleReturn(idToUse);
              return NavigationDecision.prevent;
            }
            if (isCancel) {
              _handled = true;
              _handleCancel(idToUse);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onWebResourceError: (err) {
            Get.snackbar('WebView', 'Error: ${err.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(checkoutUrl));
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Colors.deepOrangeAccent,
        actions: [
          IconButton(onPressed: () => webViewController.reload(), icon: const Icon(Icons.refresh)),
          IconButton(onPressed: () => Get.back(result: false), icon: const Icon(Icons.close)),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: ValueListenableBuilder<double>(
            valueListenable: _progress,
            builder: (_, v, __) => v < 1.0 ? LinearProgressIndicator(value: v) : const SizedBox(height: 3),
          ),
        ),
      ),
      body: WebViewWidget(controller: webViewController),
    );
  }

  Future<void> _handleReturn(String idToVerify) async {
    try {
      // (A) Your backend return endpoint (already verifies)
      final ret = await controller.returnPayment(idToVerify);

      // (B) Optional belt-and-suspenders verify
      final ver = await controller.verifyPayment(idToVerify);

      final ok = (ret?.isSuccess ?? false) && (ver?.isSuccess ?? false);

      if (ok) {
        Get.snackbar('Payment', 'Payment is successful ✅');
        await Future.delayed(const Duration(milliseconds: 700));
        Get.offAllNamed('/index'); // <-- redirect to indexpage
      } else {
        Get.snackbar('Payment', ver?.message ?? 'Payment could not be verified');
        await Future.delayed(const Duration(milliseconds: 700));
        Get.back(result: false); // close WebView
      }
    } catch (e) {
      Get.snackbar('Payment', 'Return handling failed');
      await Future.delayed(const Duration(milliseconds: 700));
      Get.back(result: false);
    }
  }

  Future<void> _handleCancel(String idToVerify) async {
    try {
      await controller.cancelPayment(idToVerify);
      Get.snackbar('Payment', 'Payment cancelled');
      await Future.delayed(const Duration(milliseconds: 700));
      Get.back(result: false); // close WebView
    } catch (e) {
      Get.snackbar('Payment', 'Cancel handling failed');
      await Future.delayed(const Duration(milliseconds: 700));
      Get.back(result: false);
    }
  }
}
