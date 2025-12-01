import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '/modules/auth/auth_handle.dart';
import '/others/theme/app_theme.dart';
import 'package:sms_autofill/sms_autofill.dart';

class SignupOtpScreen extends StatefulWidget {
  final String email; // email used during signup

  const SignupOtpScreen({super.key, required this.email});

  @override
  State<SignupOtpScreen> createState() => _SignupOtpScreenState();
}

// 🔹 Use CodeAutoFill mixin for SMS OTP autofill (same as LoginOtpScreen)
class _SignupOtpScreenState extends State<SignupOtpScreen> with CodeAutoFill {
  final TextEditingController _otpController = TextEditingController();

  bool _isVerifying = false;
  bool _isResending = false;
  int _secondsLeft = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();

    // 🔹 Start listening for OTP SMS (uses same app hash as login screen)
    SmsAutoFill().listenForCode();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    SmsAutoFill().unregisterListener();
    super.dispose();
  }

  void _startCountdown() {
    _secondsLeft = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft == 0) {
        t.cancel();
        setState(() {});
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  // 🔹 Common snackbar helper (same pattern as we used on LoginOtpScreen)
  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
  }

  //*______________Verify OTP (Signup)_______________//
  Future<void> _verifyOtp() async {
    FocusScope.of(context).unfocus();

    final code = _otpController.text.trim();

    // Guard: must be 6 digits
    if (code.length != 6) {
      _showSnack('Please enter the 6-digit code');
      return;
    }

    if (!mounted) return;
    setState(() => _isVerifying = true);

    try {
      debugPrint(
        '🔐 [SignupVerifyOtp] Calling verifyOtp with email=${widget.email}, code=$code',
      );

      final result = await AuthHandle().verifyOtp(
        email: widget.email,
        code: code,
      );

      debugPrint('🔐 [SignupVerifyOtp] verifyOtp returned: $result');

      if (!mounted) return;

      // Normalize result to bool
      final bool ok =
          result == true ||
          result == 1 ||
          result == '1' ||
          result == 'true' ||
          result == 'success' ||
          result == 'ok';

      if (ok) {
        debugPrint('✅ [SignupVerifyOtp] OTP verified successfully');

        _showSnack('Registration successful ✅');

        // Small delay so user can see it
        await Future.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;
        Get.offAllNamed('/index');
      } else {
        debugPrint(
          '⚠️ [SignupVerifyOtp] OTP invalid/expired. Raw result: $result',
        );

        _showSnack('Invalid or expired code ❌');
      }
    } catch (e, st) {
      debugPrint('❌ [SignupVerifyOtp] verifyOtp threw error: $e\n$st');
      _showSnack('Verification failed ❌. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  //*_____________Resend OTP (Signup)_______________//
  Future<void> _resendOtp() async {
    if (_secondsLeft > 0) return;

    setState(() => _isResending = true);
    try {
      debugPrint(
        '🔁 [SignupResendOtp] Resending OTP to ${widget.email}',
      );

      final ok = await AuthHandle().resendOtp(email: widget.email);

      if (ok) {
        _showSnack('Code resent ✅');
        _startCountdown();
      } else {
        _showSnack('Failed to resend ❌');
      }
    } catch (e, st) {
      debugPrint('❌ [SignupResendOtp] resendOtp error: $e\n$st');
      _showSnack('Failed to resend ❌. Please try again.');
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  // 🔹 Called automatically when SMS code is detected (via sms_autofill)
  @override
  void codeUpdated() {
    if (code == null) return;

    debugPrint('📩 [SignupOtp] codeUpdated: $code');

    setState(() {
      _otpController.text = code!;
    });

    if (code!.length == 6) {
      _verifyOtp();
    }
  }

  @override
  Widget build(BuildContext context) {
    final canVerify = _otpController.text.trim().length == 6 && !_isVerifying;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.fireGradient),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 80),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 6,
                  child: Padding(
                    padding: const EdgeInsets.all(22),
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
                          "Verify Your Account",
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Enter the 6-digit code sent to\n${widget.email}',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.black87),
                        ),
                        const SizedBox(height: 24),

                        //*_________OTP Input (PinFieldAutoFill like login)________//
                        PinFieldAutoFill(
                          controller: _otpController,
                          codeLength: 6,
                          currentCode: _otpController.text,
                          keyboardType: TextInputType.number,
                          decoration: UnderlineDecoration(
                            textStyle: const TextStyle(
                              fontSize: 20,
                              color: Colors.black,
                            ),
                            colorBuilder: FixedColorBuilder(
                              Colors.black54,
                            ),
                          ),
                          onCodeChanged: (code) {
                            debugPrint('👉 [SignupOtp] onCodeChanged: $code');
                            if (code == null) return;
                            setState(() {});
                            if (code.length == 6) {
                              FocusScope.of(context).unfocus();
                              _verifyOtp();
                            }
                          },
                          onCodeSubmitted: (code) {
                            // optional hook
                          },
                        ),

                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: canVerify ? _verifyOtp : null,
                            child: _isVerifying
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Verify'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed:
                                (_secondsLeft == 0 && !_isResending)
                                    ? _resendOtp
                                    : null,
                            icon: _isResending
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.refresh),
                            label: Text(
                              _secondsLeft == 0
                                  ? 'Resend Code'
                                  : 'Resend in ${_secondsLeft}s',
                            ),
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
                const SizedBox(height: 30),
                Column(
                  children: [
                    const Text(
                      "Powered by",
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    Image.asset(
                      "assets/icons/pranisheba-tech-logo.png",
                      height: 90,
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
