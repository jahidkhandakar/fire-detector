import 'package:fire_alarm/mvc/model/user_model.dart';
import 'package:fire_alarm/mvc/services/user_service.dart';
import 'package:get/get.dart';

class UserController extends GetxController {
  final UserService _userService = UserService();

  final Rxn<UserModel> me = Rxn<UserModel>();

  Future<UserModel> fetchUserDetails({required String api}) async {
    final user = await _userService.userDetails(api: api);
    me.value = user; // update reactive state
    return user;
  }
}
