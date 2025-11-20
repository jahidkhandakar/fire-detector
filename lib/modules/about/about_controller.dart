import 'package:get/get.dart';
import 'package:fire_alarm/modules/about/about_model.dart';
import 'package:fire_alarm/modules/about/about_service.dart';
import '/others/errors/app_error_handler.dart';

class AboutController extends GetxController {
  final AboutService _service = AboutService();

  var about = Rxn<AboutModel>();
  var isLoading = false.obs;
  var error = ''.obs;

  Future<void> loadAbout({required String apiUrl}) async {
    try {
      isLoading(true);
      error('');

      final data = await _service.fetchAbout(apiUrl: apiUrl);
      about.value = data;
    } catch (e, st) {
      // Normalize everything into AppException
      final appEx = AppException.from(e, st);

      // Optional: show inline error text on the page
      error(appEx.toUserMessage());

      // Global handler: logs + snackbar
      AppErrorHandler.handle(appEx, stackTrace: st);
    } finally {
      isLoading(false);
    }
  }
}
