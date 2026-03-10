import '/modules/devices/device_page.dart';
import '/modules/packages/package_page.dart';
import '/modules/users/user_page.dart';
import '/modules/cart/cart_page.dart';
import '/modules/cart/cart_controller.dart';
import '/screens/history_screen.dart';
import '/screens/home_screen.dart';
import '/others/widgets/bottom_nav_bar.dart';
import '/others/widgets/custom_drawer.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class IndexPage extends StatefulWidget {
  const IndexPage({super.key});

  @override
  State<IndexPage> createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> {
  int _currentIndex = 0;

  late final CartController _cartCtrl;

  final List<Widget> _pages = const [
    HomeScreen(),
    DevicePage(), // Only renders TabBarView
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

  @override
  void initState() {
    super.initState();

    _cartCtrl = Get.isRegistered<CartController>()
        ? Get.find<CartController>()
        : Get.put(CartController(), permanent: true);

    // initial tab via arguments
    final args = Get.arguments;
    if (args is Map && args['tab'] is int) {
      final newIndex = args['tab'] as int;
      if (newIndex >= 0 && newIndex < _pages.length) {
        _currentIndex = newIndex;
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cartCtrl.loadCart();
    });
  }

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
  }

  Widget _buildCartIcon() {
    return Obx(() {
      final count = _cartCtrl.itemCount;
      return Stack(
        children: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => Get.to(() => const CartPage()),
          ),
          if (count > 0)
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count > 99 ? '99+' : count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_titles[_currentIndex]),
          centerTitle: true,
          actions: [
            _buildCartIcon(),
          ],
          bottom: _currentIndex == 1
              ? const TabBar(
                  labelColor: Color.fromARGB(255, 22, 243, 29),
                  unselectedLabelColor: Colors.white,
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
