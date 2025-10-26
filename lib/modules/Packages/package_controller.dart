import 'package:get/get.dart';
import 'package:fire_alarm/modules/Packages/package_model.dart';
import 'package:fire_alarm/modules/Packages/package_service.dart';

class PackageController extends GetxController {
  final PackageService _service = PackageService();

  var packages = <PackageModel>[].obs;
  var isLoading = false.obs;
  var error = ''.obs;

  Future<void> loadPackages({required String apiUrl}) async {
    try {
      isLoading(true);
      error('');
      final data = await _service.fetchPackages(apiUrl: apiUrl);
      packages.assignAll(data);
    } catch (e) {
      error('Failed to load packages: $e');
    } finally {
      isLoading(false);
    }
  }
}
