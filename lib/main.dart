import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '/modules/Alerts/alert_page.dart';
import '/modules/Devices/device_page.dart';
import '/modules/Orders/order_page.dart';
import '/modules/Packages/package_page.dart';
import '/modules/ShurjoPay/shurjopay_checkout_page.dart';
import '/screens/home_screen.dart';
import 'others/theme/app_theme.dart';
import '/index_page.dart';
import '/screens/login_screen.dart';
import '/screens/signup_screen.dart';
import '/modules/Alerts/alert_by_device_page.dart';
import '/modules/Users/user_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  runApp(FireAlarm()); 
}

class FireAlarm extends StatelessWidget {
 const FireAlarm({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      //initialRoute: hasToken ? '/index' : '/login',
      initialRoute: '/login',
      getPages: [
        GetPage(name: '/login', page: () => LoginScreen()),
        GetPage(name: '/signup', page: () => SignupScreen()),
        GetPage(name: '/index', page: () => IndexPage()),
        GetPage(name: '/user', page: () => UserPage()),
        GetPage(name: '/packages', page: () => PackagePage()),
        GetPage(name: '/devices', page: () => DevicePage()),
        GetPage(name: '/alerts', page: () => AlertPage()),
        GetPage(name: '/device_alerts', page: () => AlertByDevicePage()),
        GetPage(name: '/home', page: () => HomeScreen()),
        GetPage(name: '/orders', page: () => OrderPage()),
        GetPage(name: '/checkout', page: () => ShurjoPayCheckoutPage()),
      ],
    );
  }
}
