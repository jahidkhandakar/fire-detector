import 'package:flutter/material.dart';
import 'mvc/view/screens/home_screen.dart';
import 'mvc/view/screens/alert_screen.dart';
import 'mvc/view/screens/history_screen.dart';
// import 'mvc/view/screens/profile_screen.dart'; // if you have a profile page

void main() {
  runApp(const FireAlarm());
}

class FireAlarm extends StatelessWidget {
  const FireAlarm({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => HomeScreen(),
        '/alerts': (context) => AlertScreen(),
        '/history': (context) => HistoryScreen(),
        // '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}
