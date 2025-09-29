import 'package:fire_alarm/mvc/view/pages/index_page.dart';
import 'package:fire_alarm/mvc/view/pages/profile_page.dart';
import 'package:fire_alarm/mvc/view/screens/login_screen.dart';
import 'package:fire_alarm/others/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'mvc/view/screens/home_screen.dart';
import 'mvc/view/screens/alert_screen.dart';
import 'mvc/view/screens/history_screen.dart';
import 'mvc/view/screens/signup_screen.dart';

void main() {
  runApp(const FireAlarm());
}

class FireAlarm extends StatelessWidget {
  const FireAlarm({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      initialRoute: '/login',
      routes: {
        '/index': (context) => IndexPage(),
        '/home': (context) => HomeScreen(),
        '/alerts': (context) => AlertScreen(),
        '/history': (context) => HistoryScreen(),
        '/login': (context) =>  LoginScreen(),
        '/signup': (context) => SignupScreen(),
        '/profile': (context) => ProfilePage(),
      },
    );
  }
}
