import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '/modules/auth/auth_handle.dart';
import '/others/theme/app_theme.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String identifier;
  const ResetPasswordScreen({super.key, required this.identifier});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final otpController = TextEditingController();
  final newPassController = TextEditingController();
  final confirmPassController = TextEditingController();

  bool _isLoading = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    otpController.dispose();
    newPassController.dispose();
    confirmPassController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    final ok = await AuthHandle().forgotPasswordComplete(
      code: otpController.text.trim(),
      newPassword: newPassController.text,
      confirmPassword: confirmPassController.text,
      setLoading: (loading) {
        setState(() {
          _isLoading = loading;
        });
      },
    );

    if (ok && mounted) {
      Get.offAllNamed('/login');
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
                          Icons.lock_open,
                          size: 62,
                          color: Colors.deepOrange,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Reset Password",
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Enter the OTP sent to\n${widget.identifier}',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.black87),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: otpController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "OTP Code",
                            prefixIcon: Icon(Icons.lock_clock),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: newPassController,
                          obscureText: _obscureNew,
                          decoration: InputDecoration(
                            labelText: "New Password",
                            prefixIcon: const Icon(Icons.lock),
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureNew
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureNew = !_obscureNew;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: confirmPassController,
                          obscureText: _obscureConfirm,
                          decoration: InputDecoration(
                            labelText: "Confirm New Password",
                            prefixIcon: const Icon(Icons.lock),
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirm = !_obscureConfirm;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleReset,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Reset Password'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => Get.offAllNamed('/login'),
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
