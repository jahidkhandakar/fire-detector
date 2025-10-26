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
    } catch (e) {
      error('Failed to load devices: $e');
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
    } catch (e) {
      error('Failed to load device tree: $e');
    } finally {
      isLoading(false);
    }
  }
}
