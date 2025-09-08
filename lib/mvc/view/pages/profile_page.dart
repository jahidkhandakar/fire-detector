import 'package:flutter/material.dart';
import 'package:fire_alarm/theme/app_theme.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Example user data
    final String name = "John Doe";
    final String phone = "+1 234 567 890";
    final String email = "john.doe@email.com";

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.fireGradient),
        child: Center(
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.deepOrange,
                    child: Icon(Icons.person, size: 48, color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.phone, color: Colors.deepOrange),
                    title: Text(
                      phone,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.email, color: Colors.deepOrange),
                    title: Text(
                      email,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
