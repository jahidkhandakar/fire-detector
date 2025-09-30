import 'package:fire_alarm/mvc/controller/auth_controller.dart';
import 'package:fire_alarm/others/utils/api.dart';
import 'package:fire_alarm/others/widgets/auth_button.dart';
import 'package:flutter/material.dart';
import 'package:fire_alarm/others/theme/app_theme.dart';
import 'package:get/get.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool _obscureText = true;
  bool _isLoading = false;

  final AuthController authController = AuthController();

  Future<void> _handleLogin() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final res = await authController.userLogin(
      api:
          Api.login, // ensure this is the correct endpoint (often with a trailing slash)
      mail: emailController.text,
      pass: passwordController.text,
    );

    final code = res['statusCode'] as int? ?? 0;
    final data = res['data'];
    String message = 'Login failed';
    if (data is Map) {
      message = (data['detail'] ?? data['message'] ?? message).toString();
    } else if (data is String && data.isNotEmpty) {
      message = data;
    }

    if (code >= 200 && code < 300) {
      Get.offAllNamed('/index');
    } else {
      // Show backend message like “Invalid login credentials”
      Get.snackbar('Login', message, snackPosition: SnackPosition.BOTTOM);
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.fireGradient),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 100),

                // Login Card
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 6,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
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
                          "Fire Alarm",
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 24),

                        // Email
                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: "Email",
                            prefixIcon: Icon(Icons.email),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Password
                        TextField(
                          controller: passwordController,
                          obscureText: _obscureText,
                          decoration: InputDecoration(
                            labelText: "Password",
                            prefixIcon: const Icon(Icons.lock),
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureText
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() => _obscureText = !_obscureText);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            child:
                                _isLoading
                                    ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : const Text("Login"),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Signup Link
                        const AuthButton(
                          routeName: "/signup",
                          buttonText: "Sign Up",
                          promptText: "Don’t have an account? ",
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Powered by
                Column(
                  children: [
                    const Text(
                      "Powered by",
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
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
