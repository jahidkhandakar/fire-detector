import '/others/errors/app_error_messages.dart';
import 'package:get/get.dart';
import '/modules/packages/package_model.dart';
import '/modules/packages/package_service.dart';
import '/others/errors/app_error_handler.dart';

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

      // show a message when there are no packages
      if (data.isEmpty) {
        error(AppErrorMessages.empty); // "No data found."
      }
    } catch (e, st) {
      final appEx = AppException.from(e, st);
      error(appEx.toUserMessage());
      AppErrorHandler.handle(appEx, stackTrace: st);
    } finally {
      isLoading(false);
    }
  }
}
