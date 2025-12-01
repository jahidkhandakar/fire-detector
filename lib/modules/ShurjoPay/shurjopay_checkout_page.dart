import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ShurjoPayCheckoutPage extends StatefulWidget {
  const ShurjoPayCheckoutPage({super.key});

  @override
  State<ShurjoPayCheckoutPage> createState() => _ShurjoPayCheckoutPageState();
}

class _ShurjoPayCheckoutPageState extends State<ShurjoPayCheckoutPage> {
  late final WebViewController _web;
  late final String checkoutUrl; // from initiate
  late final String orderId;     // sp_order_id from initiate
  int? transactionId;            // optional

  final ValueNotifier<double> _progress = ValueNotifier(0);
  bool _done = false; // guard against double pop

  // 👉 Your backend host (no scheme)
  static const String backendHost = 'firealarm.pranisheba.com.bd';

  @override
  void initState() {
    super.initState();

    final args = (Get.arguments ?? {}) as Map;
    checkoutUrl = (args['checkoutUrl'] ?? '') as String;
    orderId     = (args['orderId'] ?? '') as String;
    transactionId = args['transactionId'] as int?;

    if (checkoutUrl.isEmpty || orderId.isEmpty) {
      Future.microtask(
        () => _finish({'kind': 'error', 'reason': 'missing_args'}),
      );
      return;
    }

    if (Platform.isAndroid) {
      WebViewPlatform.instance; // ensure init
    }

    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) => _progress.value = p / 100.0,

          onPageStarted: (u) {
            print('🌐 onPageStarted: $u');
          },

          onUrlChange: (c) {
            print('🌐 onUrlChange: ${c.url}');
          },

          onPageFinished: (u) async {
            print('🌐 onPageFinished: $u');

            // 1) Strict URL-based detection against your backend
            final decision = _detectReturnOrCancel(u);
            if (decision != null) {
              _finish(decision);
              return;
            }

            // 2) JS probe (some gateways render result without navigation)
            try {
              final jsText = await _web.runJavaScriptReturningResult(
                "(() => { const t = document.title || ''; const b = (document.body && document.body.innerText) || ''; return (t + ' ' + b).toLowerCase(); })();",
              );

              final text = _jsResultToString(jsText);
              if (text.isNotEmpty) {
                final looksSuccess =
                    text.contains('payment') && text.contains('success');
                final looksFailed = text.contains('payment') &&
                    (text.contains('fail') || text.contains('cancel'));

                if (looksSuccess) {
                  final orderInUrl = _readQuery(u, 'order_id');
                  _finish({
                    'kind': 'return',
                    'orderId': orderInUrl ?? orderId,
                  });
                  return;
                }
                if (looksFailed) {
                  _finish({'kind': 'cancel'});
                  return;
                }
              }
            } catch (e) {
              print('🧪 JS probe error: $e');
            }
          },

          onNavigationRequest: (req) {
            final url = req.url;
            print('🌐 onNavigationRequest: $url');

            final decision = _detectReturnOrCancel(url);
            if (decision != null) {
              _finish(decision);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },

          onWebResourceError: (err) {
            print('🌐 WebView error: ${err.description}');
            _finish({
              'kind': 'error',
              'reason': 'webview_error',
              'detail': err.description,
            });
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

  Map<String, dynamic>? _detectReturnOrCancel(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    if (uri.host != backendHost) return null;

    final lowerPath = uri.path.toLowerCase();

    if (lowerPath.startsWith('/shurjopay/return')) {
      final oid = uri.queryParameters['order_id'] ?? orderId;
      return {'kind': 'return', 'orderId': oid};
    }
    if (lowerPath.startsWith('/shurjopay/cancel')) {
      return {'kind': 'cancel'};
    }
    return null;
  }

  String? _readQuery(String url, String key) {
    try {
      final uri = Uri.parse(url);
      return uri.queryParameters[key];
    } catch (_) {
      return null;
    }
  }

  String _jsResultToString(Object? js) {
    if (js == null) return '';
    final s = js.toString();
    if (s.startsWith('"') && s.endsWith('"')) {
      return s.substring(1, s.length - 1);
    }
    return s;
  }

  // 🔴 FIX: don't use Get.back here – use Navigator.pop to avoid Snackbar crash
  void _finish(Map<String, dynamic> result) {
    if (_done) return;
    _done = true;
    print('✅ Checkout pop result: $result');

    if (!mounted) return;
    Navigator.of(context).pop(result); // ← instead of Get.back(result: result)
  }

  void _goBackToPackages() {
    if (_done) return;
    _done = true;
    Get.offAllNamed('/index', arguments: {'tab': 2});
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        // System back → go to Packages tab
        _goBackToPackages();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Checkout'),
          backgroundColor: Colors.deepOrange,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _goBackToPackages,
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(3),
            child: ValueListenableBuilder<double>(
              valueListenable: _progress,
              builder: (_, v, __) =>
                  v < 1.0
                      ? LinearProgressIndicator(value: v)
                      : const SizedBox(height: 3),
            ),
          ),
        ),
        body: WebViewWidget(controller: _web),
      ),
    );
  }
}
