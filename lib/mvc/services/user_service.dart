import 'package:fire_alarm/mvc/model/user_model.dart';
import 'package:fire_alarm/mvc/services/method_service.dart';

class UserService {
  final _methods = MethodService();

  Future<UserModel> userDetails({required String api}) async {
    final map = await _methods.get(api);
    return UserModel.fromJson(map);
  }
}

