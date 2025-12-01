import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '/modules/auth/auth_handle.dart';
import '/others/theme/app_theme.dart';
import '/screens/reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final identifierController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    identifierController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    final ok = await AuthHandle().forgotPasswordInit(
      identifierController: identifierController,
      setLoading: (loading) {
        setState(() {
          _isLoading = loading;
        });
      },
    );

    if (ok && mounted) {
      Get.to(
        () => ResetPasswordScreen(
          identifier: identifierController.text.trim(),
        ),
      );
    }
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
                const SizedBox(height: 60),
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
                          Icons.lock_reset,
                          size: 62,
                          color: Colors.deepOrange,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Forgot Password",
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Enter your email or phone to receive a reset code.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.black87),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: identifierController,
                          decoration: const InputDecoration(
                            labelText: "Email or Phone",
                            prefixIcon: Icon(Icons.email),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleSendOtp,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Send OTP'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => Get.toNamed('/login'),
                          child: const Text('Back to Login'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
