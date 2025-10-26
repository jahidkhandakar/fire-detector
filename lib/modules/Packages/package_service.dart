import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:fire_alarm/modules/Packages/package_model.dart';

class PackageService {
  final GetStorage _box = GetStorage();

  Map<String, String> _headers() {
    final token = _box.read<String>('access');
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<PackageModel>> fetchPackages({required String apiUrl}) async {
    final uri = Uri.parse(apiUrl);
    final res = await http
        .get(uri, headers: _headers())
        .timeout(const Duration(seconds: 20));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Failed to load packages (HTTP ${res.statusCode})');
    }
    if (res.body.isEmpty) return [];

    final decoded = jsonDecode(res.body);

    //* Endpoint is a top-level list: [ {...}, {...} ]
    if (decoded is List) {
      return decoded
          .where((e) => e is Map)
          .map((e) => PackageModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }

    //* Future-proofing (e.g., { results: [ {...} ] })
    if (decoded is Map && decoded['results'] is List) {
      final results = decoded['results'] as List;
      return results
          .where((e) => e is Map)
          .map((e) => PackageModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }

    return [];
  }
}
