import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '/modules/alerts/alert_controller.dart';
import 'alarm_service.dart';

class AppDialogText {
  static const silenceTitle = 'High Smoke Detected';
  static const silenceBody =
      'Turn off sound and vibration? You can resolve the alert from the Alerts screen.';
  static const keepRinging = 'Keep Ringing';
  static const acknowledge = 'Acknowledge';
  static const resolveTitle = 'Resolve Alert?';
  static const resolveBody = 'Mark this alert as resolved for everyone?';
  static const cancel = 'Cancel';
  static const resolve = 'Resolve';
}

AlertController? _getAlertControllerOrNull() {
  if (Get.isRegistered<AlertController>()) {
    debugPrint('[Dialog] AlertController already registered.');
    return Get.find<AlertController>();
  }
  try {
    debugPrint('[Dialog] AlertController not registered → putting new one.');
    return Get.put<AlertController>(AlertController(), permanent: true);
  } catch (e) {
    debugPrint('[Dialog] Failed to put AlertController: $e');
    return null;
  }
}

/// Close only the top dialog, without going through Get.back()
void _closeTopDialogOnly() {
  final ctx = Get.overlayContext ?? Get.context;
  if (ctx != null) {
    debugPrint('[Dialog] _closeTopDialogOnly → closing top dialog.');
    Navigator.of(ctx, rootNavigator: true).pop();
  } else {
    debugPrint('[Dialog] _closeTopDialogOnly → no context found.');
  }
}

Future<void> showSilenceAlarmDialog({
  required String title,
  required String body,
  int? alertId, // optional: acknowledge on backend if present
}) async {
  debugPrint(
      '[Dialog] showSilenceAlarmDialog called. alertId=$alertId, title="$title"');

  final alarm = ensureAlarm();
  final alertController = _getAlertControllerOrNull();

  // Ensure alarm is running (caller may have started it already)
  if (!alarm.isActive) {
    debugPrint('[Dialog] Alarm not active → calling alarm.start()');
    await alarm.start();
  } else {
    debugPrint('[Dialog] Alarm already active, not calling start()');
  }

  // Avoid stacking
  if (Get.isDialogOpen == true) {
    debugPrint(
        '[Dialog] Another dialog is already open → closing top and delaying.');
    _closeTopDialogOnly();
    await Future.delayed(const Duration(milliseconds: 30));
  }

  await Get.dialog(
    AlertDialog(
      backgroundColor: Colors.white,
      title: Text(
        title.isNotEmpty ? title : AppDialogText.silenceTitle,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFFE40404),
        ),
      ),
      content: Text(
        body.isNotEmpty ? body : AppDialogText.silenceBody,
        style: const TextStyle(fontSize: 16, color: Colors.deepOrange),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      actionsAlignment: MainAxisAlignment.end,
      actions: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Keep Ringing → just close dialog, leave alarm running
            TextButton(
              onPressed: () {
                debugPrint(
                    '[Dialog] KeepRinging pressed. alertId=$alertId → closing dialog only (alarm continues).');
                _closeTopDialogOnly();
              },
              child: const Text(
                AppDialogText.keepRinging,
                style: TextStyle(color: Color.fromARGB(255, 13, 13, 13)),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              icon: const Icon(Icons.volume_off),
              style: FilledButton.styleFrom(backgroundColor: Colors.white),
              onPressed: () {
                debugPrint(
                    '[Dialog] Acknowledge pressed. alertId=$alertId → closing dialog, stopping alarm, calling acknowledgeAlert if possible.');

                // 1) Close the dialog immediately so UI doesn't feel frozen
                _closeTopDialogOnly();

                // 2) Stop alarm ASAP (fire-and-forget)
                try {
                  alarm.stop();
                } catch (e) {
                  debugPrint('[Dialog] alarm.stop() error: $e');
                }

                // 3) Fire the acknowledge call WITHOUT blocking the UI
                if (alertId != null &&
                    alertId > 0 &&
                    alertController != null) {
                  try {
                    alertController.acknowledgeAlert(alertId);
                  } catch (e) {
                    debugPrint('⚠️ acknowledgeAlert error: $e');
                  }
                } else {
                  debugPrint(
                      '[Dialog] Skipping acknowledgeAlert (alertId or controller null).');
                }
              },
              label: const Text(
                AppDialogText.acknowledge,
                style: TextStyle(color: Color.fromARGB(255, 255, 156, 7)),
              ),
            ),
          ],
        ),
      ],
    ),
    barrierDismissible: false,
  );
}

/// Silent resolve dialog (no sound/vibration).
/// Also stops any ongoing alarm after a successful resolve.
Future<void> showResolveDialog({
  required int alertId,
  String? title,
  String? body,
}) async {
  debugPrint(
      '[Dialog] showResolveDialog called. alertId=$alertId, title="$title"');

  final alertController = _getAlertControllerOrNull();

  // No stacking
  if (Get.isDialogOpen == true) {
    debugPrint(
        '[Dialog] Another dialog is already open → closing top and delaying.');
    _closeTopDialogOnly();
    await Future.delayed(const Duration(milliseconds: 30));
  }

  await Get.defaultDialog(
    title:
        (title == null || title.isEmpty) ? AppDialogText.resolveTitle : title,
    middleText:
        (body == null || body.isEmpty) ? AppDialogText.resolveBody : body,
    middleTextStyle: const TextStyle(
      fontSize: 14,
      color: Color.fromARGB(255, 97, 4, 4),
    ),
    barrierDismissible: false,
    radius: 12,
    actions: [
      TextButton(
        onPressed: () {
          debugPrint(
              '[Dialog] Resolve dialog Cancel pressed. alertId=$alertId → closing dialog.');
          _closeTopDialogOnly();
        },
        child: const Text(AppDialogText.cancel),
      ),
      const SizedBox(width: 12),
      FilledButton(
        onPressed: () {
          debugPrint(
              '[Dialog] Resolve pressed. alertId=$alertId → calling resolveAlert, stopping alarm, closing dialog.');

          // Resolve in background, don't block UI
          if (alertController != null) {
            try {
              alertController.resolveAlert(alertId);
            } catch (e) {
              debugPrint('[Dialog] resolveAlert error: $e');
            }
          } else {
            debugPrint(
                '[Dialog] AlertController is null in showResolveDialog, cannot resolve.');
          }
          try {
            ensureAlarm().stop();
          } catch (e) {
            debugPrint('[Dialog] ensureAlarm().stop() error: $e');
          }
          _closeTopDialogOnly();
        },
        child: const Text(AppDialogText.resolve),
      ),
    ],
  );
}
