import 'package:flutter/material.dart';
import '/others/errors/app_error_handler.dart';
import 'package:get/get.dart';
import 'alert_model.dart';
import 'alert_service.dart';
import '/others/utils/api.dart';


class AlertController extends GetxController {
  final AlertService _service = AlertService();

  var alerts = <AlertModel>[].obs;
  var isLoading = false.obs;
  var error = ''.obs;

  //*------------------- 🔹 Fetch all alerts -------------------
  Future<void> loadAlerts({required String apiUrl}) async {
    debugPrint('[AlertController] loadAlerts called. apiUrl=$apiUrl');
    try {
      isLoading(true);
      error('');

      final data = await _service.fetchAlerts(apiUrl: apiUrl);
      debugPrint(
          '[AlertController] loadAlerts success. received ${data.length} alerts.');
      alerts.assignAll(data);
    } on AppException catch (ex, st) {
      error(ex.toUserMessage());
      debugPrint(
          '[AlertController] Error fetching alerts (AppException): $ex');
      AppErrorHandler.handle(ex, stackTrace: st);
    } catch (e, st) {
      error('Failed to load alerts.');
      debugPrint('[AlertController] Error fetching alerts (unknown): $e');
      AppErrorHandler.handle(e, stackTrace: st);
    } finally {
      isLoading(false);
      debugPrint(
          '[AlertController] loadAlerts finished. isLoading=${isLoading.value}, error="$error"');
    }
  }

  //*---------------🔹 Fetch alerts for a specific device------------
  Future<void> loadAlertsByDevice(int deviceId) async {
    debugPrint(
        '[AlertController] loadAlertsByDevice called. deviceId=$deviceId');
    try {
      isLoading(true);
      error('');

      final data = await _service.fetchAlertsByDevice(
        baseUrl: Api.baseUrl,
        deviceId: deviceId,
      );
      debugPrint(
          '[AlertController] loadAlertsByDevice success. deviceId=$deviceId, alerts=${data.length}');
      alerts.assignAll(data);
    } on AppException catch (ex, st) {
      error(ex.toUserMessage());
      debugPrint(
          '[AlertController] Error fetching device alerts (AppException): $ex');
      AppErrorHandler.handle(ex, stackTrace: st);
    } catch (e, st) {
      error('Failed to load device alerts.');
      debugPrint(
          '[AlertController] Error fetching device alerts (unknown): $e');
      AppErrorHandler.handle(e, stackTrace: st);
    } finally {
      isLoading(false);
      debugPrint(
          '[AlertController] loadAlertsByDevice finished. deviceId=$deviceId, isLoading=${isLoading.value}, error="$error"');
    }
  }

  //*---------- 🔹 Resolve alert and update status locally------------
  Future<void> resolveAlert(int alertId) async {
    debugPrint('[AlertController] resolveAlert called. alertId=$alertId');
    try {
      final success = await _service.resolveAlert(
        baseUrl: Api.baseUrl,
        alertId: alertId,
      );
      debugPrint(
          '[AlertController] resolveAlert service call returned success=$success');

      if (success) {
        final index = alerts.indexWhere((a) => a.id == alertId);
        debugPrint(
            '[AlertController] resolveAlert local index for alertId=$alertId → $index');

        if (index != -1) {
          final old = alerts[index];
          alerts[index] = AlertModel(
            id: old.id,
            device: old.device,
            deviceHardwareIdentifier: old.deviceHardwareIdentifier,
            alertType: old.alertType,
            status: 'resolved', // updated
            triggeredAt: old.triggeredAt,
            resolvedAt: DateTime.now(),
            ownerId: old.ownerId,
            ownerEmail: old.ownerEmail,
            ownerPhone: old.ownerPhone,
          );
          alerts.refresh();
          debugPrint(
              '[AlertController] resolveAlert updated local alert to resolved. alertId=$alertId');
        }
      }
    } on AppException catch (ex, st) {
      error(ex.toUserMessage());
      debugPrint(
          '[AlertController] Error resolving alert (AppException): $ex');
      AppErrorHandler.handle(ex, stackTrace: st);
    } catch (e, st) {
      error('Failed to resolve alert.');
      debugPrint('[AlertController] Error resolving alert (unknown): $e');
      AppErrorHandler.handle(e, stackTrace: st);
    }
  }

  //*-------- 🔹 Acknowledge alert and update status locally----------
  Future<void> acknowledgeAlert(int alertId) async {
    debugPrint('[AlertController] acknowledgeAlert called. alertId=$alertId');
    try {
      final success = await _service.acknowledgeAlert(
        baseUrl: Api.baseUrl,
        alertId: alertId,
      );
      debugPrint(
          '[AlertController] acknowledgeAlert service call returned success=$success');

      if (success) {
        final index = alerts.indexWhere((a) => a.id == alertId);
        debugPrint(
            '[AlertController] acknowledgeAlert local index for alertId=$alertId → $index');

        if (index != -1) {
          final old = alerts[index];
          alerts[index] = AlertModel(
            id: old.id,
            device: old.device,
            deviceHardwareIdentifier: old.deviceHardwareIdentifier,
            alertType: old.alertType,
            status: 'Open', // No change in status on acknowledge (backend semantic)
            triggeredAt: old.triggeredAt,
            resolvedAt: old.resolvedAt,
            ownerId: old.ownerId,
            ownerEmail: old.ownerEmail,
            ownerPhone: old.ownerPhone,
          );
          alerts.refresh();
          debugPrint(
              '[AlertController] acknowledgeAlert updated local alert. alertId=$alertId');
        }
      }
    } on AppException catch (ex, st) {
      error(ex.toUserMessage());
      debugPrint(
          '[AlertController] Error acknowledging alert (AppException): $ex');
      AppErrorHandler.handle(ex, stackTrace: st);
    } catch (e, st) {
      error('Failed to acknowledge alert.');
      debugPrint('[AlertController] Error acknowledging alert (unknown): $e');
      AppErrorHandler.handle(e, stackTrace: st);
    }
  }
}
