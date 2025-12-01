import '/others/errors/app_error_handler.dart';
import 'package:get/get.dart';
import 'device_model.dart';
import 'device_node.dart';
import 'device_service.dart';

class DeviceController extends GetxController {
  final DeviceService _service = DeviceService();

  //* Flat list from /devices/
  final devices = <DeviceModel>[].obs;

  //* Tree from /devices/tree/  (masters + slaves)
  final tree = <DeviceNode>[].obs;

  final isLoading = false.obs;
  final error = ''.obs;

  Future<void> loadAll() async {
    try {
      isLoading(true);
      error('');

      final data = await _service.fetchAllDevices();
      devices.assignAll(data);
    } on AppException catch (ex, st) {
      // user-friendly text
      error(ex.toUserMessage());
      print('Error loading devices (AppException): $ex');
      AppErrorHandler.handle(ex, stackTrace: st);
    } catch (e, st) {
      error('Failed to load devices.');
      print('Error loading devices (unknown): $e');
      AppErrorHandler.handle(e, stackTrace: st);
    } finally {
      isLoading(false);
    }
  }

  Future<void> loadTree() async {
    try {
      isLoading(true);
      error('');

      final data = await _service.fetchDeviceTree();
      tree.assignAll(data);
    } on AppException catch (ex, st) {
      error(ex.toUserMessage());
      print('Error loading device tree (AppException): $ex');
      AppErrorHandler.handle(ex, stackTrace: st);
    } catch (e, st) {
      error('Failed to load device tree.');
      print('Error loading device tree (unknown): $e');
      AppErrorHandler.handle(e, stackTrace: st);
    } finally {
      isLoading(false);
    }
  }
}
