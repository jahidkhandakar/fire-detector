import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import '/modules/packages/package_model.dart';
import '/others/errors/app_error_handler.dart';

class PackageService {
  final GetStorage _box = GetStorage();

  Map<String, String> _headers() {
    final token = _box.read<String>('access');
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  //*_________________FETCH PACKAGES_________________*/
  Future<List<PackageModel>> fetchPackages({required String apiUrl}) async {
    final uri = Uri.parse(apiUrl);

    try {
      final res = await AppHttp.get(
        uri,
        headers: _headers(),
      );

      if (res.body.isEmpty) {
        // AppHttp would already throw AppErrorType.empty normally,
        // but in case you ever bypass that behavior:
        throw AppException(
          type: AppErrorType.empty,
          message: 'Empty packages response',
          raw: res,
        );
      }

      final decoded = jsonDecode(res.body);

      //* Endpoint is a top-level list: [ {...}, {...} ]
      if (decoded is List) {
        return decoded
            .where((e) => e is Map)
            .map((e) => PackageModel.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ))
            .toList();
      }

      //* Future-proofing (e.g., { results: [ {...} ] })
      if (decoded is Map && decoded['results'] is List) {
        final results = decoded['results'] as List;
        return results
            .where((e) => e is Map)
            .map((e) => PackageModel.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ))
            .toList();
      }

      // Unexpected shape → treat as parsing error
      throw const FormatException('Unexpected packages response shape');
    } on AppException {
      // already a typed app error
      rethrow;
    } catch (e, st) {
      throw AppException.from(e, st);
    }
  }
}
