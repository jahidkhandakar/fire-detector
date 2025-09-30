import 'package:fire_alarm/mvc/controller/auth_controller.dart';
import 'package:fire_alarm/others/utils/api.dart';
import 'package:fire_alarm/others/widgets/auth_button.dart';
import 'package:flutter/material.dart';
import 'package:fire_alarm/others/theme/app_theme.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.isEmpty ||
        phoneController.text.trim().isEmpty) {
      Get.snackbar(
        'Sign up',
        'Please fill all required fields',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() => _isLoading = true);

    final res = await AuthController().userRegistration(
      api: Api.register,
      name: nameController.text.trim(),
      mail: emailController.text.trim(),
      pass: passwordController.text,
      phone: phoneController.text.trim(),
    );

    final code = res['statusCode'] as int? ?? 0;
    final data = res['data'];

    if (code >= 200 && code < 300) {
      // Save name for profile display
      final box = GetStorage();
      await box.write('signup_name', nameController.text.trim());
      await box.write('profile_name', nameController.text.trim());

      Get.snackbar(
        'Success',
        'Account created. Please login.',
        snackPosition: SnackPosition.BOTTOM,
      );
      Get.offAllNamed('/login');
    } else {
      String msg = 'Registration failed';
      if (data is Map<String, dynamic>) {
        msg =
            (data['detail'] ??
                    data['message'] ??
                    data['error'] ??
                    (data.values.isNotEmpty ? data.values.first : msg))
                .toString();
      } else if (data != null) {
        msg = data.toString();
      }
      Get.snackbar('Sign up', msg, snackPosition: SnackPosition.BOTTOM);
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.fireGradient),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 40),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 6,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.local_fire_department,
                          size: 62,
                          color: Colors.deepOrange,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Create Account",
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 24),

                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: "Full Name",
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextField(
                          controller: emailController,
                          decoration: const InputDecoration(
                            labelText: "Email",
                            prefixIcon: Icon(Icons.email),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: "Phone Number",
                            prefixIcon: Icon(Icons.phone),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextField(
                          controller: passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: "Password",
                            prefixIcon: const Icon(Icons.lock),
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleSignup,
                            child:
                                _isLoading
                                    ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                    : const Text('Sign Up'),
                          ),
                        ),
                        const SizedBox(height: 12),

                        AuthButton(
                          routeName: "/login",
                          buttonText: "Login",
                          promptText: "Already have an account? ",
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Column(
                  children: [
                    const Text("Powered by"),
                    Image.asset(
                      "assets/icons/pranisheba-tech-logo.png",
                      height: 100,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
