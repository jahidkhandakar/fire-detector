import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import '/modules/auth/auth_controller.dart';
import '/others/utils/api.dart';
import '/others/widgets/custom_snackbar.dart';
import '/modules/firebase/push_notification_service.dart';
import '/others/errors/app_error_handler.dart';
import '/others/errors/app_error_messages.dart';

class AuthHandle {
  final AuthController _authController = AuthController();
  final GetStorage _box = GetStorage();

  //* -------------------- SIGNUP (REGISTER INIT) --------------------
  /// Returns true if OTP was sent successfully
  Future<bool> signup({
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
      return false;
    }

    setLoading(true);

    final res = await AppErrorHandler.run(
      () => _authController.userRegistration(
        api: Api.register,
        name: nameController.text.trim(),
        mail: emailController.text.trim(),
        pass: passwordController.text,
        phone: phoneController.text.trim(),
      ),
      showUi: true,
      context: context,
    );

    setLoading(false);

    if (res == null) return false;

    final code = res['statusCode'] as int? ?? 0;
    final data = res['data'];

    if (code == 201 && data is Map<String, dynamic>) {
      final sessionId = data['session_id']?.toString();

      if (sessionId != null && sessionId.isNotEmpty) {
        await _box.write('reg_session_id', sessionId);
      }

      await _box.write('pending_reg_name', nameController.text.trim());
      await _box.write('pending_reg_email', emailController.text.trim());
      await _box.write('pending_reg_phone', phoneController.text.trim());
      await _box.write('pending_reg_pass', passwordController.text);

      CustomSnackbar().success('OTP sent. Please check your email/phone.');
      return true;
    } else {
      final dynamic d = res['data'];
      final String backendMsg =
          (d is Map<String, dynamic>)
              ? (d['detail']?.toString() ??
                  d['message']?.toString() ??
                  d['error']?.toString() ??
                  '')
              : '';

      final errMsg =
          backendMsg.isNotEmpty
              ? backendMsg
              : AppErrorMessages.authRegistrationFailed;

      CustomSnackbar().show('Registration failed', errMsg);
      return false;
    }
  }

  //* -------------------- REGISTER OTP VERIFY --------------------
  /// Used by OtpPage (signup flow)
  Future<bool> verifyOtp({required String email, required String code}) async {
    if (code.trim().isEmpty) return false;

    final sessionId = _box.read<String>('reg_session_id');

    if (sessionId == null || sessionId.isEmpty) {
      CustomSnackbar().error(AppErrorMessages.authOtpSessionExpired);
      return false;
    }

    final res = await AppErrorHandler.run(
      () => _authController.verifyRegistration(
        sessionId: sessionId,
        code: code.trim(),
      ),
      showUi: true,
    );

    if (res == null) return false;

    final status = res['statusCode'] as int? ?? 0;
    final data = res['data'] as Map<String, dynamic>?;

    if (status == 201 && data != null) {
      final tokens = data['tokens'] as Map<String, dynamic>?;

      dynamic access = tokens?['access'];
      dynamic refresh = tokens?['refresh'];

      access ??= data['access'];
      refresh ??= data['refresh'];

      if (access != null && refresh != null) {
        await _box.write('access', access.toString());
        await _box.write('refresh', refresh.toString());

        final user = data['user'] as Map<String, dynamic>?;
        if (user != null) {
          await _box.write('user_id', user['id']);
          await _box.write('user_email', user['email']);
          await _box.write('user_phone', user['phone_number']);
          await _box.write('user_full_name', user['full_name']);
          await _box.write('user_address', user['address']);
        }

        await _box.remove('reg_session_id');
        await _box.remove('pending_reg_name');
        await _box.remove('pending_reg_email');
        await _box.remove('pending_reg_phone');
        await _box.remove('pending_reg_pass');

        try {
          await PushNotificationService.registerAfterAuth();
        } catch (e) {
          debugPrint('⚠️ registerAfterAuth failed: $e');
        }

        return true;
      } else {
        CustomSnackbar().error(AppErrorMessages.authVerificationFailed);
        return false;
      }
    } else {
      final backendMsg =
          data?['detail']?.toString() ??
          data?['message']?.toString() ??
          data?['error']?.toString();

      final errMsg = backendMsg ?? AppErrorMessages.authVerificationFailed;

      CustomSnackbar().error(errMsg);
      return false;
    }
  }

  //* -------------------- REGISTER OTP RESEND --------------------
  Future<bool> resendOtp({required String email}) async {
    final name = _box.read<String>('pending_reg_name');
    final phone = _box.read<String>('pending_reg_phone');
    final pass = _box.read<String>('pending_reg_pass');

    if (name == null ||
        phone == null ||
        pass == null ||
        name.isEmpty ||
        phone.isEmpty ||
        pass.isEmpty) {
      CustomSnackbar().error(AppErrorMessages.authOtpSessionExpired);
      return false;
    }

    final res = await AppErrorHandler.run(
      () => _authController.userRegistration(
        api: Api.register,
        name: name,
        mail: email,
        pass: pass,
        phone: phone,
      ),
      showUi: true,
    );

    if (res == null) return false;

    final code = res['statusCode'] as int? ?? 0;
    final data = res['data'] as Map<String, dynamic>?;

    if (code == 201 && data != null) {
      final sessionId = data['session_id']?.toString();
      if (sessionId != null && sessionId.isNotEmpty) {
        await _box.write('reg_session_id', sessionId);
      }

      CustomSnackbar().success('OTP resent. Please check your inbox.');
      return true;
    } else {
      final backendMsg =
          data?['detail']?.toString() ??
          data?['message']?.toString() ??
          data?['error']?.toString();

      final errMsg = backendMsg ?? AppErrorMessages.authResendFailed;

      CustomSnackbar().error(errMsg);
      return false;
    }
  }

  //* -------------------- LOGIN (INIT) --------------------
  /// Returns true if OTP was sent successfully
  Future<bool> login({
    required BuildContext context,
    required TextEditingController emailController,
    required TextEditingController passwordController,
    required ValueChanged<bool> setLoading,
  }) async {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.isEmpty) {
      CustomSnackbar().warning('Please fill all required fields');
      return false;
    }

    setLoading(true);

    final res = await AppErrorHandler.run(
      () => _authController.userLogin(
        api: Api.login,
        mail: emailController.text.trim(),
        pass: passwordController.text,
      ),
      showUi: true,
      context: context,
    );

    setLoading(false);

    // If null => network/timeout/parsing etc already handled via AppErrorHandler
    if (res == null) {
      debugPrint('AuthHandle.login -> res is null');
      return false;
    }

    // Be flexible about how status code is stored
    final dynamic rawCode = res['statusCode'] ?? res['status'] ?? res['code'];
    final int code =
        rawCode is int ? rawCode : int.tryParse(rawCode?.toString() ?? '') ?? 0;

    // Some services nest body in `data`, some just return body directly
    dynamic data = res['data'];
    if (data == null && res['session_id'] != null) {
      // looks like direct backend body
      data = res;
    }

    debugPrint('AuthHandle.login -> code=$code data=$data');

    if (data is! Map<String, dynamic>) {
      CustomSnackbar().error(AppErrorMessages.authLoginFailed);
      return false;
    }

    // Accept both 200 and 201 as success (in case backend uses 201 for challenge)
    if (code >= 200 && code <= 300 ) {
      final sessionId = data['session_id']?.toString();
      final otpSentTo = data['otp_sent_to']?.toString();

      if (sessionId == null || sessionId.isEmpty) {
        debugPrint('AuthHandle.login -> session_id missing in response');
        CustomSnackbar().error(AppErrorMessages.authLoginFailed);
        return false;
      }

      await _box.write('login_session_id', sessionId);
      await _box.write('login_email', emailController.text.trim());
      await _box.write('login_pass', passwordController.text);
      if (otpSentTo != null) {
        await _box.write('login_otp_sent_to', otpSentTo);
      }

      CustomSnackbar().success('OTP sent. Please check your phone/email.');
      return true;
    } else {
      final String msg =
          (data['detail']?.toString() ??
              data['message']?.toString() ??
              data['error']?.toString() ??
              AppErrorMessages.authLoginFailed);

      debugPrint('AuthHandle.login -> failed ($code): $msg');
      CustomSnackbar().error(msg);
      return false;
    }
  }

  //* -------------------- LOGIN OTP VERIFY --------------------
  Future<bool> verifyLoginOtp({required String code}) async {
    if (code.trim().isEmpty) return false;

    final sessionId = _box.read<String>('login_session_id');

    if (sessionId == null || sessionId.isEmpty) {
      CustomSnackbar().error(AppErrorMessages.authOtpSessionExpired);
      return false;
    }

    final res = await AppErrorHandler.run(
      () =>
          _authController.verifyLogin(sessionId: sessionId, code: code.trim()),
      showUi: true,
    );

    if (res == null) return false;

    final status = res['statusCode'] as int? ?? 0;
    final data = res['data'] as Map<String, dynamic>?;

    if (status == 200 && data != null) {
      final tokens = data['tokens'] as Map<String, dynamic>?;

      dynamic access = tokens?['access'];
      dynamic refresh = tokens?['refresh'];

      access ??= data['access'];
      refresh ??= data['refresh'];

      if (access != null && refresh != null) {
        await _box.write('access', access.toString());
        await _box.write('refresh', refresh.toString());

        final user = data['user'] as Map<String, dynamic>?;
        if (user != null) {
          await _box.write('user_id', user['id']);
          await _box.write('user_email', user['email']);
          await _box.write('user_phone', user['phone_number']);
          await _box.write('user_full_name', user['full_name']);
          await _box.write('user_address', user['address']);
        }

        await _box.remove('login_session_id');
        await _box.remove('login_email');
        await _box.remove('login_pass');
        await _box.remove('login_otp_sent_to');

        try {
          await PushNotificationService.registerAfterAuth();
        } catch (e) {
          debugPrint('⚠️ registerAfterAuth failed: $e');
        }

        return true;
      } else {
        CustomSnackbar().error(AppErrorMessages.authVerificationFailed);
        return false;
      }
    } else {
      final backendMsg =
          data?['detail']?.toString() ??
          data?['message']?.toString() ??
          data?['error']?.toString();

      final errMsg = backendMsg ?? AppErrorMessages.authVerificationFailed;

      CustomSnackbar().error(errMsg);
      return false;
    }
  }

  //* -------------------- LOGIN OTP RESEND --------------------
  Future<bool> resendLoginOtp() async {
    final email = _box.read<String>('login_email');
    final pass = _box.read<String>('login_pass');

    if (email == null || pass == null || email.isEmpty || pass.isEmpty) {
      CustomSnackbar().error(AppErrorMessages.authOtpSessionExpired);
      return false;
    }

    final res = await AppErrorHandler.run(
      () => _authController.userLogin(api: Api.login, mail: email, pass: pass),
      showUi: true,
    );

    if (res == null) return false;

    final code = res['statusCode'] as int? ?? 0;
    final data = res['data'] as Map<String, dynamic>?;

    if (code == 200 && data != null) {
      final sessionId = data['session_id']?.toString();
      final otpSentTo = data['otp_sent_to']?.toString();

      if (sessionId != null && sessionId.isNotEmpty) {
        await _box.write('login_session_id', sessionId);
      }
      if (otpSentTo != null) {
        await _box.write('login_otp_sent_to', otpSentTo);
      }

      CustomSnackbar().success('OTP resent. Please check your phone/email.');
      return true;
    } else {
      final backendMsg =
          data?['detail']?.toString() ??
          data?['message']?.toString() ??
          data?['error']?.toString();

      final errMsg = backendMsg ?? AppErrorMessages.authResendFailed;

      CustomSnackbar().error(errMsg);
      return false;
    }
  }

  //* -------------------- FORGOT PASSWORD INIT --------------------
  Future<bool> forgotPasswordInit({
    required TextEditingController identifierController,
    required ValueChanged<bool> setLoading,
  }) async {
    final identifier = identifierController.text.trim();
    if (identifier.isEmpty) {
      CustomSnackbar().warning('Please enter your email or phone.');
      return false;
    }

    setLoading(true);

    final res = await AppErrorHandler.run(
      () => _authController.forgotPasswordInit(identifier: identifier),
      showUi: true,
    );

    setLoading(false);

    if (res == null) return false;

    final code = res['statusCode'] as int? ?? 0;
    final data = res['data'];

    if (code == 201) {
      String? sessionId;
      if (data is Map<String, dynamic>) {
        sessionId = data['session_id']?.toString();
      }

      if (sessionId != null && sessionId.isNotEmpty) {
        await _box.write('forgot_session_id', sessionId);
      }

      await _box.write('forgot_identifier', identifier);

      CustomSnackbar().success('OTP sent. Please check your email/phone.');
      return true;
    } else {
      final dynamic d = res['data'];
      final String backendMsg =
          (d is Map<String, dynamic>)
              ? (d['detail']?.toString() ??
                  d['message']?.toString() ??
                  d['error']?.toString() ??
                  '')
              : '';

      final errMsg =
          backendMsg.isNotEmpty
              ? backendMsg
              : AppErrorMessages.authForgotInitFailed;

      CustomSnackbar().error(errMsg);
      return false;
    }
  }

  //* -------------------- FORGOT PASSWORD COMPLETE --------------------
  Future<bool> forgotPasswordComplete({
    required String code,
    required String newPassword,
    required String confirmPassword,
    required ValueChanged<bool> setLoading,
  }) async {
    if (code.trim().isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      CustomSnackbar().warning('Please fill all required fields');
      return false;
    }

    if (newPassword != confirmPassword) {
      CustomSnackbar().warning('Passwords do not match');
      return false;
    }

    final sessionId = _box.read<String>('forgot_session_id');

    if (sessionId == null || sessionId.isEmpty) {
      CustomSnackbar().error(AppErrorMessages.authOtpSessionExpired);
      return false;
    }

    setLoading(true);

    final res = await AppErrorHandler.run(
      () => _authController.forgotPasswordComplete(
        sessionId: sessionId,
        code: code.trim(),
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      ),
      showUi: true,
    );

    setLoading(false);

    if (res == null) return false;

    final status = res['statusCode'] as int? ?? 0;
    final data = res['data'];

    if (status == 200) {
      await _box.remove('forgot_session_id');
      await _box.remove('forgot_identifier');

      CustomSnackbar().success('Password reset successful. Please login.');
      return true;
    } else {
      final dynamic d = data;
      final String backendMsg =
          (d is Map<String, dynamic>)
              ? (d['detail']?.toString() ??
                  d['message']?.toString() ??
                  d['error']?.toString() ??
                  '')
              : '';

      final errMsg =
          backendMsg.isNotEmpty
              ? backendMsg
              : AppErrorMessages.authForgotCompleteFailed;

      CustomSnackbar().error(errMsg);
      return false;
    }
  }

  //* -------------------- CHANGE PASSWORD --------------------
  Future<bool> changePassword({
    required TextEditingController currentPassController,
    required TextEditingController newPassController,
    required TextEditingController confirmPassController,
    required ValueChanged<bool> setLoading,
  }) async {
    final currentPass = currentPassController.text;
    final newPass = newPassController.text;
    final confirmPass = confirmPassController.text;

    if (currentPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
      CustomSnackbar().warning('Please fill all required fields');
      return false;
    }

    if (newPass != confirmPass) {
      CustomSnackbar().warning('New passwords do not match');
      return false;
    }

    if (newPass == currentPass) {
      CustomSnackbar().warning('New password must be different');
      return false;
    }

    setLoading(true);

    final res = await AppErrorHandler.run(
      () => _authController.changePassword(
        currentPassword: currentPass,
        newPassword: newPass,
        confirmNewPassword: confirmPass,
      ),
      showUi: true,
    );

    setLoading(false);

    if (res == null) return false;

    final status = res['statusCode'] as int? ?? 0;
    final data = res['data'];

    if (status == 204) {
      CustomSnackbar().success('Password changed successfully.');
      return true;
    } else {
      final dynamic d = data;
      final String backendMsg =
          (d is Map<String, dynamic>)
              ? (d['detail']?.toString() ??
                  d['message']?.toString() ??
                  d['error']?.toString() ??
                  '')
              : '';

      final errMsg =
          backendMsg.isNotEmpty
              ? backendMsg
              : AppErrorMessages.authChangePasswordFailed;

      CustomSnackbar().error(errMsg);
      return false;
    }
  }
}
