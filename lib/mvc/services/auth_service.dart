import 'package:fire_alarm/mvc/services/method_service.dart';

class AuthService {
  final MethodService _methods = MethodService();
  //*____________________REGISTER____________________*//
  Future<Map<String, dynamic>> register({
    required String api,
    required String mail,
    required String pass,
    required String phone,
  }) async {
    return await _methods.post(
      api,
      {
        "email": mail,
        "password": pass,
        "phone_number": phone,
      },
    );
  }
  //*____________________LOGIN____________________*//
  Future<Map<String, dynamic>> login({
    required String api,
    required String mail,
    required String pass,
  }) async {
    return await _methods.post(
      api,
      {
        "email": mail,
        "password": pass,
      },
    );
  }

  //*____________________USER DETAILS____________________*//
  Future<Map<String, dynamic>> userDetails({
    required String api,
  }) async {
    return await _methods.get(api);
  }
}