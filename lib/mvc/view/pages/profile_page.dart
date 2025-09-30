import 'package:fire_alarm/others/utils/api.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fire_alarm/mvc/model/user_model.dart';
import 'package:fire_alarm/mvc/controller/user_controller.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final UserController _controller = Get.put(UserController());
  late Future<UserModel> _future;
  
  final String api = Api.userDetails;

  @override
  void initState() {
    super.initState();
    _future = _controller.fetchUserDetails(api: api);
  }

  Future<void> _refresh() async {
    await _controller.fetchUserDetails(api: api);
    setState(() {}); // rebind FutureBuilder if needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<UserModel>(
          future: _future,
          builder: (context, snapshot) {
            // Use controller.me reactively once loaded
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _CenteredLoader();
            }
            if (snapshot.hasError) {
              return _CenteredError(message: snapshot.error.toString());
            }

            return Obx(() {
              final user = _controller.me.value ?? snapshot.data!;
              return _ProfileContent(user: user);
            });
          },
        ),
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  final UserModel user;
  const _ProfileContent({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final phone = (user.phoneNumber.isEmpty) ? '—' : user.phoneNumber;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  child: Text(_initialsFromEmail(user.email)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.email, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(
                            label: Text(user.role.isEmpty ? 'unknown' : user.role),
                            visualDensity: VisualDensity.compact,
                          ),
                          Chip(
                            label: Text('ID: ${user.id}'),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              _Tile(
                icon: Icons.email_outlined,
                title: 'Email',
                value: user.email,
              ),
              const Divider(height: 1),
              _Tile(
                icon: Icons.phone_outlined,
                title: 'Phone',
                value: phone,
              ),
              const Divider(height: 1),
              _Tile(
                icon: Icons.verified_user_outlined,
                title: 'Role',
                value: user.role.isEmpty ? '—' : user.role,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _initialsFromEmail(String email) {
    if (email.isEmpty) return '?';
    final namePart = email.split('@').first;
    if (namePart.isEmpty) return email.characters.first.toUpperCase();
    final parts = namePart.split(RegExp(r'[._\-+]')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return namePart.characters.first.toUpperCase();
    final first = parts.first.characters.first.toUpperCase();
    final second = parts.length > 1 ? parts[1].characters.first.toUpperCase() : '';
    return '$first$second';
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  const _Tile({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon),
      title: Text(title, style: theme.textTheme.bodyMedium),
      subtitle: Text(value, style: theme.textTheme.titleSmall),
      dense: true,
    );
  }
}

class _CenteredLoader extends StatelessWidget {
  const _CenteredLoader();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Padding(
      padding: EdgeInsets.all(24.0),
      child: CircularProgressIndicator(),
    ));
  }
}

class _CenteredError extends StatelessWidget {
  final String message;
  const _CenteredError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red),
        ),
      ),
    );
  }
}
