import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '/modules/auth/auth_controller.dart';
import '/others/utils/api.dart';
import '/others/widgets/custom_snackbar.dart';
import '/modules/Firebase/push_notification_service.dart';

class AuthHandle {
  final AuthController _authController = AuthController();
  final GetStorage _box = GetStorage();

  //* -------------------- LOGIN --------------------
  Future<void> login({
    required BuildContext context,
    required TextEditingController emailController,
    required TextEditingController passwordController,
    required ValueChanged<bool> setLoading,
  }) async {
    setLoading(true);

    final res = await _authController.userLogin(
      api: Api.login,
      mail: emailController.text.trim(),
      pass: passwordController.text,
    );

    setLoading(false);

    final code = res['statusCode'] as int? ?? 0;
    final data = res['data'] as Map<String, dynamic>?;

    if (code == 200 && data != null && data['access'] != null) {
      final access = data['access'];
      final refresh = data['refresh'];

      _box.write('access', access);
      _box.write('refresh', refresh);

      debugPrint(
        "Login success: access=${access.toString().substring(0, 15)}...",
      );

      // 👉 Register / re-bind this device's FCM token to the logged-in user
      try {
        await PushNotificationService.registerAfterAuth();
      } catch (e) {
        debugPrint('⚠️ registerAfterAuth failed: $e');
      }

      if (context.mounted) {
        Get.offAllNamed('/index');
        CustomSnackbar().success("Login Successful");
      }
    } else {
      final msg =
          data?['detail'] ??
          data?['message'] ??
          data?['error'] ??
          "Login failed";
      debugPrint("Login failed: $msg");

      if (context.mounted) {
        CustomSnackbar().error(msg);
      }
    }
  }

  //* -------------------- SIGNUP --------------------
  Future<void> signup({
    required BuildContext context,
    required TextEditingController nameController,
    required TextEditingController emailController,
    required TextEditingController passwordController,
    required TextEditingController phoneController,
    required ValueChanged<bool> setLoading,
  }) async {
    if (nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.isEmpty ||
        phoneController.text.trim().isEmpty) {
      CustomSnackbar().warning('Please fill all required fields');
      return;
    }

    setLoading(true);

    final res = await _authController.userRegistration(
      api: Api.register,
      name: nameController.text.trim(),
      mail: emailController.text.trim(),
      pass: passwordController.text,
      phone: phoneController.text.trim(),
    );

    setLoading(false);

    final code = res['statusCode'] as int? ?? 0;
    final data = res['data'];

    print("Status Code: $code");
    print("Response Data: $data");

    if (code == 201 && data is Map<String, dynamic>) {
      await _box.write('name', nameController.text.trim());

      if (context.mounted) {
        CustomSnackbar().success('Account created. Please login.');
        Get.offAllNamed('/login');
      }
    } else {
      final dynamic d = res['data'];
      final String errMsg =
          (d is Map<String, dynamic>)
              ? (d['detail']?.toString() ??
                  d['message']?.toString() ??
                  d['error']?.toString() ??
                  'Something went wrong')
              : (res['detail']?.toString() ?? 'Something went wrong');

      debugPrint("Registration failed ($code): $errMsg");

      if (context.mounted) {
        // Show exactly what backend returned
        //CustomSnackbar().error(errMsg);
        // Or if your CustomSnackbar uses `.show(title, message)`:
        CustomSnackbar().show('Registration failed', errMsg);
      }
    }
  }
}
