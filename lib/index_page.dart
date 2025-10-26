import 'package:fire_alarm/modules/Devices/device_page.dart';
import 'package:fire_alarm/modules/Packages/package_page.dart';
import 'package:fire_alarm/modules/Users/user_page.dart';
import '/screens/history_screen.dart';
import '/screens/home_screen.dart';
import '/others/widgets/bottom_nav_bar.dart';
import '/others/widgets/custom_drawer.dart';
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
    DevicePage(), // now only renders TabBarView
    PackagePage(),
    HistoryScreen(),
    UserPage(),
  ];

  final List<String> _titles = const [
    'Home',
    'Devices',
    'Packages',
    'History',
    'User Profile',
  ];

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      // provide controller for TabBar + TabBarView
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_titles[_currentIndex]),
          centerTitle: true,
          bottom:
              _currentIndex == 1
                  ? const TabBar(
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.blueGrey,
                    indicatorColor: Colors.white,
                    tabs: [
                      Tab(
                        icon: Icon(Icons.list, color: Colors.white),
                        text: 'All Devices',
                      ),
                      Tab(
                        icon: Icon(Icons.account_tree, color: Colors.white),
                        text: 'Device Tree',
                      ),
                    ],
                  )
                  : null,
        ),
        drawer: CustomDrawer(
          onTabSelected: (index) {
            Navigator.pop(context);
            _onTabSelected(index);
          },
        ),
        body: IndexedStack(index: _currentIndex, children: _pages),
        bottomNavigationBar: BottomNavBar(
          currentIndex: _currentIndex,
          onTap: _onTabSelected,
        ),
      ),
    );
  }
}
