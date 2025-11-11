import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '/modules/Firebase/push_notification_service.dart';
// ----------------------- pages ------------------------------
import '/screens/login_screen.dart';
import '/screens/signup_screen.dart';
import '/index_page.dart';
import '/screens/home_screen.dart';
import '/modules/Users/user_page.dart';
import '/modules/Packages/package_page.dart';
import '/modules/Devices/device_page.dart';
import '/modules/Alerts/alert_page.dart';
import '/modules/Alerts/alert_by_device_page.dart';
import '/modules/Orders/order_page.dart';
import '/modules/ShurjoPay/shurjopay_checkout_page.dart';
import '/others/theme/app_theme.dart';

Future<void> _bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) Storage (auth decision depends on this)
  await GetStorage.init();

  // 2) Firebase core
  await Firebase.initializeApp();

  // 3) MUST register background handler BEFORE any FCM usage
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
}

void main() async {
  await _bootstrap();

  // Run UI immediately; don't block on notification init
  runApp(const FireAlarm());

  // Kick off FCM + LocalNotifications setup after first frame to avoid splash hang
  scheduleMicrotask(() {
    PushNotificationService.initialize();
  });
}

class FireAlarm extends StatelessWidget {
  const FireAlarm({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      // A tiny decider widget that routes to /login or /index quickly
      home: const AuthGate(),

      // Keep your named routes for navigation elsewhere
      getPages: [
        GetPage(name: '/login', page: () => const LoginScreen()),
        GetPage(name: '/signup', page: () => const SignupScreen()),
        GetPage(name: '/index', page: () => const IndexPage()),
        GetPage(name: '/home', page: () => const HomeScreen()),
        GetPage(name: '/user', page: () => const UserPage()),
        GetPage(name: '/packages', page: () => const PackagePage()),
        GetPage(name: '/devices', page: () => const DevicePage()),
        GetPage(name: '/alerts', page: () => const AlertPage()),
        GetPage(name: '/device_alerts', page: () => const AlertByDevicePage()),
        GetPage(name: '/orders', page: () => const OrderPage()),
        GetPage(name: '/checkout', page: () => const ShurjoPayCheckoutPage()),
      ],
    );
  }
}

/// Decides where to go as soon as the first frame is rendered.
/// No heavy work here!
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    // Defer navigation to AFTER first frame so we don't fight build/layout.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final box = GetStorage();
      final token = box.read<String>('access');
      final loggedIn = token != null && token.isNotEmpty;

      if (loggedIn) {
        Get.offAllNamed('/index'); 
      } else {
        Get.offAllNamed('/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Minimal splash while AuthGate decides
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
