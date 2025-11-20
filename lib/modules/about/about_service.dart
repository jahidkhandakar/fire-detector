import 'package:get_storage/get_storage.dart';
import 'package:fire_alarm/modules/about/about_model.dart';
import '/others/errors/app_error_handler.dart';

class AboutService {
  final GetStorage _box = GetStorage();

  Map<String, String> _headers() {
    final token = _box.read<String>('access');
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<AboutModel> fetchAbout({required String apiUrl}) async {
    final uri = Uri.parse(apiUrl);

    // Centralized:
    // - timeout
    // - status code mapping (401/404/5xx/others)
    // - empty body check
    // - network / timeout mapped to AppException
    final res = await AppHttp.get(
      uri,
      headers: _headers(),
    );

    // Centralized JSON parsing → throws AppException on bad format
    return AppHttp.parseJsonObject(
      res.body,
      (json) => AboutModel.fromJson(json),
    );
  }
}
