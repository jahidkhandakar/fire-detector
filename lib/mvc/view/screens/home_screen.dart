import 'package:fire_alarm/widgets/bottom_nav_bar.dart';
import 'package:fire_alarm/widgets/custom_drawer.dart';
import 'package:flutter/material.dart';
import 'package:fire_alarm/theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Fire Detector',
          style: TextStyle(
            color: AppTheme.theme.appBarTheme.foregroundColor,
            fontWeight: FontWeight.bold,
            fontSize: 28,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppTheme.theme.appBarTheme.backgroundColor,
      ),
      drawer: CustomDrawer(),
      body: Container(
        decoration: BoxDecoration(color: Colors.white),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.fire_extinguisher,
                  color: Theme.of(context).colorScheme.secondary,
                  size: 100,
                ),
                const SizedBox(height: 24),
                Text(
                  'Welcome to Fire Alarm System',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontSize: 24),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Monitor and manage fire safety alerts in real time. Stay safe and informed with instant notifications and emergency contacts.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Navigate to alarm monitoring page
                  },
                  icon: const Icon(Icons.notifications_active),
                  label: const Text('View Alerts'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      //*_____________________ bottomNavigationBar _____________________
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0,
        onTap: (index) {
          // Handle navigation based on the tapped index
          switch (index) {
            case 0:
              // Already on HomeScreen
              break;
            case 1:
              Navigator.pushNamed(context, '/alerts');
              break;
            case 2:
              Navigator.pushNamed(context, '/history');
              break;
            case 3:
              Navigator.pushNamed(context, '/profile');
              break;
          }
        },
      ),
    );
  }
}
