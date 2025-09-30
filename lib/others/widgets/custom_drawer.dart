import 'package:fire_alarm/mvc/controller/user_controller.dart';
import 'package:fire_alarm/mvc/model/user_model.dart';
import 'package:fire_alarm/others/theme/app_theme.dart';
import 'package:fire_alarm/others/utils/api.dart';
import 'package:flutter/material.dart';

class CustomDrawer extends StatefulWidget {
  const CustomDrawer({super.key});

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  final _user = UserController();
  late Future<UserModel> _future;

  @override
  void initState() {
    super.initState();
    _future = _user.fetchUserDetails(api: Api.userDetails);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: FutureBuilder<UserModel>(
        future: _future,
        builder: (context, snapshot) {
          String name = 'User';
          String phone = '';
          String email = '';
          String role = '';

          final user = snapshot.data;
          if (snapshot.connectionState == ConnectionState.done && user != null) {
            email = user.email;
            phone = user.phoneNumber;
            name = email.contains('@') ? email.split('@').first : 'User';
            role = user.role;
          }

          return Column(
            children: [
              // Header
              InkWell(
                onTap: () => Navigator.pushNamed(context, '/profile'),
                child: Container(
                  decoration: BoxDecoration(gradient: AppTheme.fireGradient),
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white24,
                        child: Icon(
                          Icons.person,
                          size: 48,
                          color: Colors.white,
                        ),
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
                      if (phone.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          phone,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Drawer items
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    if (email.isNotEmpty)
                      ListTile(
                        leading: const Icon(
                          Icons.email,
                          color: Colors.deepOrange,
                        ),
                        title: Text(email),
                      ),
                    if (role.isNotEmpty)
                      ListTile(
                        leading: const Icon(
                          Icons.verified_user,
                          color: Colors.deepOrange,
                        ),
                        title: Text('Role: $role'),
                      ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(
                        Icons.book,
                        color: Colors.deepOrange,
                      ),
                      title: const Text("About"),
                      onTap: () => Navigator.pushNamed(context, '/about'),
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
                    builder: (ctx) => AlertDialog(
                      title: const Text(
                        "Logout",
                        style: TextStyle(color: Colors.redAccent),
                        textAlign: TextAlign.center,
                      ),
                      content: const Text(
                        "Are you sure you want to logout?",
                        style: TextStyle(
                          color: Colors.deepOrange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      actionsAlignment: MainAxisAlignment.center,
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text("Cancel"),
                        ),
                        const SizedBox(width: 16),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text("Logout"),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true && context.mounted) {
                    // TODO: call your AuthService.logout() here
                    Navigator.pushReplacementNamed(context, "/login");
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
