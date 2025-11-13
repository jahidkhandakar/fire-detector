//import 'package:fire_alarm/modules/Firebase/push_notification_service.dart';
import 'package:fire_alarm/others/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerFloat, // center FAB
      //*---------FAB to verify FCM registration status-----------
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: () async {
      //     final ok = await PushNotificationService.ensureRegisteredNow();
      //     if (ok) {
      //       Get.snackbar(
      //         'FCM',
      //         'Device is registered ✅',
      //         snackPosition: SnackPosition.BOTTOM,
      //       );
      //     } else {
      //       Get.snackbar(
      //         'FCM',
      //         'FCM not registered ❌',
      //         snackPosition: SnackPosition.BOTTOM,
      //       );
      //     }
      //   },
      //   icon: const Icon(Icons.verified_user),
      //   label: const Text('Verify FCM Registration'),
      //   backgroundColor: Colors.deepOrange,
      //   foregroundColor: Colors.white,
      // ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset("assets/icons/pranisheba-tech-logo.png", height: 150),
              const SizedBox(height: 10),
              //Image.asset("assets/images/gas_meter.png", height: 100),
              //const SizedBox(height: 10),
              Text(
                'Welcome to Fire Alarm System',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontSize: 24),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              //------------Alerts Buttons-----------------//
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Get.toNamed('/alerts'),
                      icon: const Icon(Icons.notifications_active),
                      label: const Text('All Alerts'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme().secondaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Get.toNamed('/device_alerts'),
                      icon: const Icon(Icons.notifications_active),
                      label: const Text('Device Alerts'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme().secondaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
              //-------------------------------------------//
              const SizedBox(height: 10),
              //*-----My Orders Button-------*//
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Get.toNamed('/orders'),
                  icon: const Icon(Icons.shopping_basket),
                  label: const Text('My Orders'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme().secondaryColor,
                    foregroundColor: const Color.fromARGB(255, 4, 2, 2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
