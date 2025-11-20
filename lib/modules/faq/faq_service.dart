import 'package:get_storage/get_storage.dart';
import 'faq_model.dart';
import '/others/errors/app_error_handler.dart';

class FaqService {
  final GetStorage _box = GetStorage();

  Map<String, String> _headers() {
    final token = _box.read<String>('access');
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<FaqModel> fetchFaq({required String apiUrl}) async {
    final uri = Uri.parse(apiUrl);

    final res = await AppHttp.get(
      uri,
      headers: _headers(),
    );

    return AppHttp.parseJsonObject(
      res.body,
      (json) => FaqModel.fromJson(json),
    );
  }
}
