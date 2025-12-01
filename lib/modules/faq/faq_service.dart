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

    try {
      final res = await AppHttp.get(
        uri,
        headers: _headers(),
      );

      // Optional debug log
      print('FAQ Response [${res.statusCode}]: ${res.body}');

      return AppHttp.parseJsonObject(
        res.body,
        (json) => FaqModel.fromJson(json),
      );
    } on AppException {
      // AppHttp already mapped status / timeouts / parsing etc.
      rethrow;
    } catch (e, st) {
      // Any unexpected stuff → normalize
      // print('Error in fetchFaq service: $e');
      throw AppException.from(e, st);
    }
  }
}
