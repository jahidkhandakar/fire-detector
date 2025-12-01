import '/modules/users/user_model.dart';
import '/modules/users/user_service.dart';
import '/others/utils/api.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '/others/errors/app_error_handler.dart';

class UserController extends GetxController {
  final UserService _userService = UserService();
  final GetStorage _box = GetStorage();
  final Rxn<UserModel> me = Rxn<UserModel>();

  // optional: expose error state for the UI
  final error = ''.obs;

  //* ---------------- Fetch user details ----------------
  Future<UserModel> fetchUserDetails({required String api}) async {
    try {
      error.value = '';
      final user = await _userService.userDetails(api: api);
      me.value = user;

      // Save user ID locally for other modules (e.g. Orders)
      _box.write('user_id', user.id);

      return user;
    } catch (e, st) {
      debugPrint('fetchUserDetails error: $e\n$st');
      final appEx = AppException.from(e, st);
      error.value = appEx.toUserMessage();
      AppErrorHandler.handle(appEx, stackTrace: st);
      rethrow; // keep same behavior: caller can still catch
    }
  }

  //* ---------------- Update user profile ----------------
  Future<UserModel?> patchUserProfile({
    required String fullName,
    required String address,
    required String phoneNumber,
  }) async {
    try {
      error.value = '';
      final updated = await _userService.updateUserProfile(
        api: Api.userDetails,
        fullName: fullName,
        address: address,
        phoneNumber: phoneNumber,
      );

      // Update local memory
      me.value = updated;

      // Update stored user ID (in case it changes in response)
      _box.write('user_id', updated.id);

      return updated;
    } catch (e, st) {
      debugPrint('patchUserProfile error: $e\n$st');
      final appEx = AppException.from(e, st);
      error.value = appEx.toUserMessage();
      AppErrorHandler.handle(appEx, stackTrace: st);
      return null;
    }
  }

  //* ---------------- Get stored user ID ----------------
  int? getStoredUserId() => _box.read<int>('user_id');

  //* ---------------- Check if user ID exists ----------------
  bool get hasStoredUserId => _box.hasData('user_id');

  //* ---------------- Logout and clear cache ----------------
  void clearCachedUser() {
    me.value = null;
    _box.remove('user_id');
  }

  Future<void> logout(BuildContext context) async {
    final box = GetStorage();
    await box.erase();
    await box.save();

    debugPrint("🧹 Storage cleared, navigating to login");
    Get.offAllNamed('/login');
  }
}
