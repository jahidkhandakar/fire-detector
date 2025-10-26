import '/modules/users/user_controller.dart';
import '/modules/users/user_model.dart';
import '/others/utils/api.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  final UserController _controller = Get.put(UserController(), permanent: true);
  late Future<UserModel> _future;
  final String api = Api.userDetails;

  @override
  void initState() {
    super.initState();
    _future = _controller.fetchUserDetails(api: api);
  }

  Future<void> _refresh() async {
    await _controller.fetchUserDetails(api: api);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<UserModel>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _CenteredLoader();
            }
            if (snapshot.hasError) {
              return _CenteredError(message: snapshot.error.toString());
            }

            return Obx(() {
              final user = _controller.me.value ?? snapshot.data!;
              return _UserProfileView(user: user);
            });
          },
        ),
      ),
    );
  }
}

class _UserProfileView extends StatelessWidget {
  final UserModel user;
  const _UserProfileView({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final phone = user.phoneNumber.isEmpty ? '—' : user.phoneNumber;
    final address = (user.address?.isNotEmpty ?? false)
        ? user.address!
        : 'No address provided';

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          //* ---------- HEADER ----------
          Container(
            margin: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepOrange, Colors.orangeAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(48), top: Radius.circular(48)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 45,
                  backgroundColor: Colors.white,
                  child: Text(
                    _initialsFromName(user.fullName ?? user.email),
                    style: const TextStyle(
                      color: Colors.deepOrange,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  user.fullName?.isNotEmpty == true
                      ? user.fullName!
                      : user.email.split('@').first,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(user.email,
                    style: const TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 4),
                Text(phone,
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    user.role.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          //* ---------- USER DETAILS ----------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 3,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  children: [
                    _ProfileTile(icon: Icons.email_outlined, title: "Email", value: user.email),
                    const Divider(height: 1),
                    _ProfileTile(icon: Icons.phone_outlined, title: "Phone", value: phone),
                    const Divider(height: 1),
                    _ProfileTile(icon: Icons.home_outlined, title: "Address", value: address),
                    const Divider(height: 1),
                    _ProfileTile(icon: Icons.verified_user_outlined, title: "Role", value: user.role.isEmpty ? "—" : user.role),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          //* ---------- DEVICES ----------
          if (user.devices.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 3,
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("My Devices (${user.devices.length})",
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange,
                          )),
                      const SizedBox(height: 10),
                      for (final d in user.devices)
                        Card(
                          color: Colors.grey.shade50,
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            leading: Icon(
                              d.deviceRole == 'master' ? Icons.sensors : Icons.sensors_outlined,
                              color: Colors.deepOrange,
                            ),
                            title: Text(d.deviceName.isNotEmpty ? d.deviceName : 'Unnamed Device',
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text("ID: ${d.id}  •  Role: ${d.deviceRole}",
                                style: const TextStyle(color: Colors.grey)),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: d.status == 'alive'
                                    ? Colors.green.shade100
                                    : Colors.red.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                d.status == 'alive' ? 'Online' : 'Offline',
                                style: TextStyle(
                                  color: d.status == 'alive'
                                      ? Colors.green.shade800
                                      : Colors.red.shade800,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

          const SizedBox(height: 25),

          //* ---------- EDIT BUTTON ----------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showEditProfileSheet(context, user),
                icon: const Icon(Icons.edit),
                label: const Text("Edit Profile"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  //* ---------- EDIT PROFILE SHEET ----------
  void _showEditProfileSheet(BuildContext context, UserModel user) {
    final controller = Get.find<UserController>();
    final nameCtrl = TextEditingController(text: user.fullName ?? '');
    final addressCtrl = TextEditingController(text: user.address ?? '');
    final phoneCtrl = TextEditingController(text: user.phoneNumber ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        bool isLoading = false;
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            Future<void> saveProfile() async {
              setModalState(() => isLoading = true);
              final updated = await controller.patchUserProfile(
                fullName: nameCtrl.text.trim(),
                address: addressCtrl.text.trim(),
                phoneNumber: phoneCtrl.text.trim(),
              );
              setModalState(() => isLoading = false);

              if (updated != null && ctx.mounted) {
                Get.back();
                Get.snackbar("Success", "Profile updated successfully!",
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.green,
                    colorText: Colors.white);
              } else {
                Get.snackbar("Error", "Failed to update profile.",
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.red,
                    colorText: Colors.white);
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Edit Profile",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.deepOrange,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: "Full Name",
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: addressCtrl,
                    decoration: const InputDecoration(
                      labelText: "Address",
                      prefixIcon: Icon(Icons.home),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: "Phone Number",
                      prefixIcon: Icon(Icons.phone),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text("Save Changes"),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _initialsFromName(String text) {
    if (text.isEmpty) return '?';
    final parts = text.split(' ').where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return text.characters.first.toUpperCase();
    final first = parts.first.characters.first.toUpperCase();
    final second = parts.length > 1 ? parts[1].characters.first.toUpperCase() : '';
    return '$first$second';
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.deepOrange),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      subtitle: Text(value),
      dense: true,
    );
  }
}

class _CenteredLoader extends StatelessWidget {
  const _CenteredLoader();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: CircularProgressIndicator(),
      ),
    );
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
          style:
              Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red),
        ),
      ),
    );
  }
}
