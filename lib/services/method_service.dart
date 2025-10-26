import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';

class MethodService {
  final GetStorage _box = GetStorage();

  Map<String, String> _headers() {
    final token = _box.read<String>('access');
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  //*-----------------------GET------------------------------

  Future<dynamic> get(String url) async {
    final uri = Uri.parse(url);
    final head = _headers();
    final res = await http
        .get(uri, headers: head)
        .timeout(const Duration(seconds: 20));

    print("Get Response: ${res.toString()}"); // for debugging

    if (res.body.isEmpty) return {};
    return jsonDecode(res.body);
  }

  //*-----------------------POST------------------------------

  Future<Map<String, dynamic>> post(
    String url,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse(url);
    final head = _headers();
    final payload = jsonEncode(body);
    final res = await http
        .post(uri, headers: head, body: payload)
        .timeout(const Duration(seconds: 20));

    print("Post Response: ${res.toString()}"); // for debugging

    final decoded = res.body.isEmpty ? {} : jsonDecode(res.body);
    return {'statusCode': res.statusCode, 'data': decoded};
  }
}
