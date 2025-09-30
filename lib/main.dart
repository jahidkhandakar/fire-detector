import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'others/theme/app_theme.dart';
import 'mvc/view/pages/index_page.dart';
import 'mvc/view/pages/profile_page.dart';
import 'mvc/view/screens/login_screen.dart';
import 'mvc/view/screens/signup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  runApp(FireAlarm()); 
}

class FireAlarm extends StatelessWidget {
 FireAlarm({super.key});

  @override
  Widget build(BuildContext context) {
    final hasToken = GetStorage().read<String>('access')?.isNotEmpty == true;
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      initialRoute: hasToken ? '/index' : '/login',
      getPages: [
        GetPage(name: '/login', page: () => LoginScreen()),
        GetPage(name: '/signup', page: () => SignupScreen()),
        GetPage(name: '/index', page: () => IndexPage()),
        GetPage(name: '/profile', page: () => ProfilePage()),
      ],
    );
  }
}
