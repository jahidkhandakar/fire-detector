import '/modules/users/user_controller.dart';
import '/modules/users/user_model.dart';
import '/others/theme/app_theme.dart';
import '/others/utils/api.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomDrawer extends StatefulWidget {
  final ValueChanged<int>? onTabSelected;

  const CustomDrawer({super.key, this.onTabSelected});

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  // ✅ CHANGED: use GetX-managed controller instead of creating plain instance
  late final UserController _userController;
  late Future<UserModel> _future;

  @override
  void initState() {
    super.initState();

    // ✅ CHANGED: register or retrieve controller from GetX (global instance)
    // If you already use an InitialBinding for UserController, use Get.find()
    _userController = Get.put(UserController(), permanent: true);

    // Fetch current user details from backend
    _future = _userController.fetchUserDetails(api: Api.userDetails);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: FutureBuilder<UserModel>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

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
              // ─────────── Drawer Header ─────────── //
              Container(
                decoration: BoxDecoration(gradient: AppTheme.fireGradient),
                padding: const EdgeInsets.symmetric(vertical: 32),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white24,
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

              // ─────────── Drawer Items ─────────── //
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    if (email.isNotEmpty)
                      ListTile(
                        leading: const Icon(Icons.email, color: Colors.deepOrange),
                        title: Text(email),
                      ),
                    if (role.isNotEmpty)
                      ListTile(
                        leading: const Icon(Icons.verified_user, color: Colors.deepOrange),
                        title: Text('Role: $role'),
                      ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.book, color: Colors.deepOrange),
                      title: const Text("About"),
                      onTap: () => Navigator.pushNamed(context, '/about'),
                    ),
                  ],
                ),
              ),

              const Divider(),

              //* ─────────── Logout Button ─────────── //
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text("Logout"),
                onTap: () async {
                  // ✅ Confirmation dialog before logout
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
                    await _userController.logout(context);
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
