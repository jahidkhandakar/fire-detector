import 'package:fire_alarm/mvc/services/auth_service.dart';

class AuthController {
  final AuthService _authService = AuthService();
  
  //*__________________USER REGISTRATION__________________*//
  Future<void> userRegistration({
    required String api,
    required String mail,
    required String pass,
    required String phone,
  }) async {
    final response = await _authService.register(
      api: api,
      mail: mail,
      pass: pass,
      phone: phone,
    );
    print("Response: $response");
  }

  //*__________________USER LOGIN__________________*//
  Future<void> userLogin({
    required String api,
    required String mail,
    required String pass,
  }) async {
    final response = await _authService.login(
      api: api,
      mail: mail,
      pass: pass,
    );
    print("Response: $response");
  }

  //*__________________FETCH USER DETAILS__________________*//  
  Future<void> fetchUserDetails({
    required String api,
  }) async {
    final response = await _authService.userDetails(
      api: api,
    );
    print("User Details Response: $response");
  }
}