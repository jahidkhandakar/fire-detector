import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '/modules/auth/auth_handle.dart';
import '/others/theme/app_theme.dart';
import 'package:sms_autofill/sms_autofill.dart';

class LoginOtpScreen extends StatefulWidget {
  const LoginOtpScreen({super.key});

  @override
  State<LoginOtpScreen> createState() => _LoginOtpScreenState();
}

// 🔹 CHANGED: Added `with CodeAutoFill` mixin for SMS listener
class _LoginOtpScreenState extends State<LoginOtpScreen> with CodeAutoFill {
  final TextEditingController _otpController = TextEditingController();

  bool _isVerifying = false;
  bool _isResending = false;
  int _secondsLeft = 60;
  Timer? _timer;

  final GetStorage _box = GetStorage();

  @override
  void initState() {
    super.initState();
    _startCountdown();

    // 🔹 NEW: Start listening for incoming OTP SMS
    SmsAutoFill().listenForCode();
    _printAppSignature();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();

    // 🔹 NEW: Stop listening to avoid leaks
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

  Future<void> _printAppSignature() async {
    try {
      final signature = await SmsAutoFill().getAppSignature;
      debugPrint('📨 App Signature: $signature');
    } catch (e) {
      debugPrint('❌ Failed to get app signature: $e');
    }
  }

  //*______________Verify OTP_______________//
  Future<void> _verifyOtp() async {
    FocusScope.of(context).unfocus();

    final code = _otpController.text.trim();

    // 1️⃣ Quick guard for incomplete code
    if (code.length != 6) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the 6-digit code'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isVerifying = true);

    try {
      debugPrint('🔐 [verifyOtp] Calling verifyLoginOtp with code: $code');

      final result = await AuthHandle().verifyLoginOtp(code: code);

      debugPrint('🔐 [verifyOtp] verifyLoginOtp returned: $result');

      if (!mounted) return;

      // Normalize result
      final bool ok =
          result == true ||
          result == 1 ||
          result == '1' ||
          result == 'true' ||
          result == 'success' ||
          result == 'ok';

      if (ok) {
        debugPrint('✅ [verifyOtp] OTP verified successfully');

        // ✅ Success Snackbar
        ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Verification Successful ✅'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
        Get.offAllNamed('/index');
      } else {
        debugPrint('⚠️ [verifyOtp] OTP invalid/expired. Raw result: $result');

        // ❌ Error – use ScaffoldMessenger (more reliable)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid or expired code ❌'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e, st) {
      debugPrint('❌ [verifyOtp] verifyLoginOtp threw error: $e\n$st');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification failed❌. Please try again.'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  //*_____________Resend OTP_______________//
  Future<void> _resendOtp() async {
    if (_secondsLeft > 0) return;

    setState(() => _isResending = true);
    try {
      final ok = await AuthHandle().resendLoginOtp();

      if (ok) {
        Get.snackbar('OTP', 'Code resent', snackPosition: SnackPosition.TOP);
        _startCountdown();
      } else {
        Get.snackbar(
          'OTP',
          'Failed to resend',
          snackPosition: SnackPosition.TOP,
        );
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  // 🔹 NEW: This is called automatically when SMS code is detected
  @override
  void codeUpdated() {
    if (code == null) return;

    setState(() {
      _otpController.text = code!;
    });

    // Optional: auto-verify when full 6-digit code comes in
    if (code!.length == 6) {
      _verifyOtp();
    }
  }

  @override
  Widget build(BuildContext context) {
    final canVerify = _otpController.text.trim().length == 6 && !_isVerifying;

    // 🔥 Now we read from storage only
    final sentTo = _box.read<String>('login_otp_sent_to');
    final loginIdentifier = _box.read<String>('login_email');
    final displayTarget = sentTo ?? loginIdentifier ?? 'your phone/email';

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
                          "Login Verification",
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Enter the 6-digit code sent to\n$displayTarget',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.black87),
                        ),
                        const SizedBox(height: 24),

                        //*_________OTP Input (CHANGED to PinFieldAutoFill)________//
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
                            colorBuilder: FixedColorBuilder(Colors.black54),
                          ),
                          onCodeChanged: (code) {
                            if (code == null) return;
                            setState(() {});
                            if (code.length == 6) {
                              FocusScope.of(context).unfocus();
                              _verifyOtp();
                            }
                          },
                          onCodeSubmitted: (code) {
                            // optional: extra handling if needed
                          },
                        ),

                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: canVerify ? _verifyOtp : null,
                            child:
                                _isVerifying
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
                            icon:
                                _isResending
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
