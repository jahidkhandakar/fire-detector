import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import '/modules/users/user_model.dart';
import '/others/errors/app_error_handler.dart'; 

class UserService {
  final GetStorage _box = GetStorage();

  /// Build headers with optional Bearer token
  Map<String, String> _headers() {
    final token = _box.read<String>('access');
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  //*------------------ GET: Fetch User Details ------------------///
  Future<UserModel> userDetails({required String api}) async {
    final uri = Uri.parse(api);

    try {
      final res = await AppHttp.get(
        uri,
        headers: _headers(),
      );

      final data = jsonDecode(res.body);
      return UserModel.fromJson(data);
    } on AppException {
      // already classified by AppHttp
      rethrow;
    } catch (e, st) {
      throw AppException.from(e, st);
    }
  }

  //*------------------ PATCH: Update User Profile ------------------///
  Future<UserModel> updateUserProfile({
    required String api,
    required String fullName,
    required String address,
    required String phoneNumber,
  }) async {
    final uri = Uri.parse(api);
    final payload = jsonEncode({
      "full_name": fullName,
      "address": address,
      "phone_number": phoneNumber,
    });

    http.Response res;
    try {
      res = await http
          .patch(
            uri,
            headers: _headers(),
            body: payload,
          )
          .timeout(const Duration(seconds: 20));
    } on SocketException catch (e, st) {
      throw AppException.from(e, st);
    } on TimeoutException catch (e, st) {
      throw AppException.from(e, st);
    } catch (e, st) {
      throw AppException.from(e, st);
    }

    if (res.statusCode == 200 || res.statusCode == 201) {
      final data = jsonDecode(res.body);
      return UserModel.fromJson(data);
    }

    // Non-2xx → map to typed AppException
    throw _mapStatusToAppException(
      res,
      context: 'Failed to update user profile',
    );
  }

  // 🔧 Map HTTP status → AppException with proper type
  AppException _mapStatusToAppException(
    http.Response res, {
    required String context,
  }) {
    final code = res.statusCode;
    final body = res.body;

    if (code == 401) {
      return AppException(
        type: AppErrorType.unauthorized,
        message: '$context (unauthorized): $body',
        raw: res,
      );
    }

    if (code == 404) {
      return AppException(
        type: AppErrorType.notFound,
        message: '$context (not found): $body',
        raw: res,
      );
    }

    if (code >= 500) {
      return AppException(
        type: AppErrorType.server,
        message: '$context (server error $code): $body',
        raw: res,
      );
    }

    return AppException(
      type: AppErrorType.unknown,
      message: '$context (HTTP $code): $body',
      raw: res,
    );
  }
}
