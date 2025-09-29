import 'package:fire_alarm/mvc/view/screens/alert_screen.dart';
import 'package:fire_alarm/mvc/view/screens/history_screen.dart';
import 'package:fire_alarm/mvc/view/screens/home_screen.dart';
import 'package:fire_alarm/others/widgets/bottom_nav_bar.dart';
import 'package:fire_alarm/others/widgets/custom_drawer.dart';
import 'package:flutter/material.dart';

class IndexPage extends StatefulWidget {
  const IndexPage({super.key});

  @override
  State<IndexPage> createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    AlertScreen(),
    HistoryScreen(),
  ];
  final List<String> _titles = const [
    'Home',
    'Alerts',
    'History',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
      ),
      drawer: CustomDrawer(),
      body: _pages[_currentIndex],

      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
