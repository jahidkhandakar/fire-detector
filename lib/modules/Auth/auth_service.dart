import '/services/method_service.dart';

class AuthService {
  final MethodService _methods = MethodService();

  //*____________________REGISTER____________________*//
  Future<Map<String, dynamic>> register({
    required String api,
    required String mail,
    required String pass,
    required String phone,
    required String name,
  }) async {
    return _methods.post(
       api, 
       {
         'email': mail,
         'password': pass,
         'phone_number': phone,
         'name': name, 
         'full_name': name,
       }
    );
  }

  //*____________________LOGIN____________________*//
  Future<Map<String, dynamic>> login({
    required String api,
    required String mail,
    required String pass,
  }) async {
    return _methods.post(
      api, 
      {
        'email': mail,
        'password': pass
      }
    );
  }
}
