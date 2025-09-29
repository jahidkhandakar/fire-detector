import 'package:fire_alarm/others/theme/app_theme.dart';
import 'package:flutter/material.dart';

class CustomDrawer extends StatelessWidget {
  final String name = "John Doe";
  final String phone = "+1 234 567 890";
  final String email = "john.doe@email.com";
  final String address = "123 Main Street, City, Country";
  final List<String> emergencyNumbers = ["+1 111 222 3333", "+1 444 555 6666"];

  CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          //----------------------- Header-------------------------
          InkWell(
            onTap: () {
              Navigator.pushNamed(context, '/profile');
            },
            child: Container(
              decoration: BoxDecoration(gradient: AppTheme.fireGradient),
              padding: const EdgeInsets.symmetric(vertical: 32),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.deepOrange,
                    child: Icon(Icons.person, size: 48, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    phone,
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),

          // Drawer items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.email, color: Colors.deepOrange),
                  title: Text(email),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.location_on,
                    color: Colors.deepOrange,
                  ),
                  title: Text(address),
                ),
                ExpansionTile(
                  leading: const Icon(
                    Icons.phone_in_talk,
                    color: Colors.deepOrange,
                  ),
                  title: const Text("Emergency Numbers"),
                  children:
                      emergencyNumbers
                          .map(
                            (num) => ListTile(
                              title: Text(num),
                              leading: const Icon(
                                Icons.call,
                                color: Colors.deepOrange,
                              ),
                            ),
                          )
                          .toList(),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.person, color: Colors.deepOrange),
                  title: Text("About"),
                  onTap: () => {Navigator.pushNamed(context, '/about')},
                ),
              ],
            ),
          ),

          const Divider(),

          // Logout pinned at bottom
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text("Logout"),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder:
                    (ctx) => AlertDialog(
                      title: const Text(
                        "Logout",
                        style: TextStyle(color: Colors.redAccent),
                        textAlign: TextAlign.center,
                        ),
                      content: const Text("Are you sure you want to logout?"),
                      actionsAlignment: MainAxisAlignment.center,
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text("Cancel"),
                        ),
                        SizedBox(width: 16),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text("Logout"),
                        ),
                      ],
                    ),
              );

              if (confirm == true && context.mounted) {
                // later you can add FirebaseAuth.instance.signOut() or prefs.clear() here
                Navigator.pushReplacementNamed(context, "/login");
              }
            },
          ),
        ],
      ),
    );
  }
}
