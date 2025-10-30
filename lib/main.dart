import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '/modules/Firebase/firebase_messaging_background_handler.dart';
import '/modules/Alerts/alert_page.dart';
import '/modules/Alerts/alert_by_device_page.dart';
import '/modules/Devices/device_page.dart';
import '/modules/Orders/order_page.dart';
import '/modules/Packages/package_page.dart';
import '/modules/ShurjoPay/shurjopay_checkout_page.dart';
import '/modules/Users/user_page.dart';
import '/screens/home_screen.dart';
import '/screens/login_screen.dart';
import '/screens/signup_screen.dart';
import '/index_page.dart';
import '/others/theme/app_theme.dart';
import '/modules/Firebase/push_notification_service.dart';


// 🔔 Global notifications plugin
final FlutterLocalNotificationsPlugin _fln = FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Init local storage
  await GetStorage.init();

  // Init Firebase
  await Firebase.initializeApp();

  // 🔹 Local notifications setup
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidInit);
  await _fln.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (resp) {
      final alertId = resp.payload;
      if (alertId != null && alertId.isNotEmpty) {
        // Navigate when user taps notification
        Get.toNamed('/device_alerts', arguments: {'alertId': alertId});
      }
    },
  );

  // 🔹 Set background message handler (from separate file)
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // 🔹 Request permission (Android 13+ / iOS)
  await FirebaseMessaging.instance.requestPermission();

  await PushNotificationService.initialize();

  runApp(const FireAlarm());
}

class FireAlarm extends StatelessWidget {
  const FireAlarm({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      initialRoute: '/login', // or '/index' if user already logged in
      getPages: [
        GetPage(name: '/login', page: () => const LoginScreen()),
        GetPage(name: '/signup', page: () => const SignupScreen()),
        GetPage(name: '/index', page: () => const IndexPage()),
        GetPage(name: '/user', page: () => const UserPage()),
        GetPage(name: '/packages', page: () => const PackagePage()),
        GetPage(name: '/devices', page: () => const DevicePage()),
        GetPage(name: '/alerts', page: () => const AlertPage()),
        GetPage(name: '/device_alerts', page: () => const AlertByDevicePage()),
        GetPage(name: '/home', page: () => const HomeScreen()),
        GetPage(name: '/orders', page: () => const OrderPage()),
        GetPage(name: '/checkout', page: () => const ShurjoPayCheckoutPage()),
      ],
    );
  }
}
