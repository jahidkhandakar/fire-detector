import 'package:get/get.dart';
import 'alert_model.dart';
import 'alert_service.dart';
import 'package:fire_alarm/others/utils/api.dart';

class AlertController extends GetxController {
  final AlertService _service = AlertService();

  var alerts = <AlertModel>[].obs;
  var isLoading = false.obs;
  var error = ''.obs;

  //*------------------- 🔹 Fetch all alerts -------------------
  Future<void> loadAlerts({required String apiUrl}) async {
    try {
      isLoading(true);
      error('');
      final data = await _service.fetchAlerts(apiUrl: apiUrl);
      alerts.assignAll(data);
    } catch (e) {
      error('Failed to load alerts: $e');
      print('Error fetching alerts: $e');
    } finally {
      isLoading(false);
    }
  }

  //*---------------🔹 Fetch alerts for a specific device------------
  Future<void> loadAlertsByDevice(int deviceId) async {
    try {
      isLoading(true);
      error('');
      final data = await _service.fetchAlertsByDevice(
        baseUrl: Api.baseUrl,
        deviceId: deviceId,
      );
      alerts.assignAll(data);
    } catch (e) {
      error('Failed to load device alerts: $e');
      print('Error fetching device alerts: $e');
    } finally {
      isLoading(false);
    }
  }

  //*---------- 🔹 Resolve alert and update status locally------------
  Future<void> resolveAlert(int alertId) async {
    try {
      final success = await _service.resolveAlert(
        baseUrl: Api.baseUrl,
        alertId: alertId,
      );
      if (success) {
        final index = alerts.indexWhere((a) => a.id == alertId);
        if (index != -1) {
          alerts[index] = AlertModel(
            id: alerts[index].id,
            device: alerts[index].device,
            deviceHardwareIdentifier: alerts[index].deviceHardwareIdentifier,
            alertType: alerts[index].alertType,
            status: 'resolved', // updated
            triggeredAt: alerts[index].triggeredAt,
            resolvedAt: DateTime.now(),
            ownerId: alerts[index].ownerId,
            ownerEmail: alerts[index].ownerEmail,
            ownerPhone: alerts[index].ownerPhone,
          );
          alerts.refresh();
        }
      }
    } catch (e) {
      error('Failed to resolve alert: $e');
      print('Error resolving alert: $e');
    }
  }

  //*-------- 🔹 Acknowledge alert and update status locally----------
  Future<void> acknowledgeAlert(int alertId) async {
    try {
      final success = await _service.acknowledgeAlert(
        baseUrl: Api.baseUrl,
        alertId: alertId,
      );
      if (success) {
        final index = alerts.indexWhere((a) => a.id == alertId);
        if (index != -1) {
          alerts[index] = AlertModel(
            id: alerts[index].id,
            device: alerts[index].device,
            deviceHardwareIdentifier: alerts[index].deviceHardwareIdentifier,
            alertType: alerts[index].alertType,
            status: 'Open', // No change in status on acknowledge
            triggeredAt: alerts[index].triggeredAt,
            resolvedAt: alerts[index].resolvedAt,
            ownerId: alerts[index].ownerId,
            ownerEmail: alerts[index].ownerEmail,
            ownerPhone: alerts[index].ownerPhone,
          );
          alerts.refresh();
        }
      }
    } catch (e) {
      error('Failed to acknowledge alert: $e');
      print('Error acknowledging alert: $e');
    }
  }
}
