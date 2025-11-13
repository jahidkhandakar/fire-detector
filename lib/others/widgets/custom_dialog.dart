import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fire_alarm/modules/Alerts/alert_controller.dart';
import 'alarm_service.dart';

class AppDialogText {
  static const silenceTitle = 'High Smoke Detected';
  static const silenceBody  =
      'Turn off sound and vibration? You can resolve the alert from the Alerts screen.';
  static const keepRinging  = 'Keep Ringing';
  static const acknowledge  = 'Acknowledge';
  static const resolveTitle = 'Resolve Alert?';
  static const resolveBody  = 'Mark this alert as resolved for everyone?';
  static const cancel       = 'Cancel';
  static const resolve      = 'Resolve';
}

AlertController? _getAlertControllerOrNull() {
  if (Get.isRegistered<AlertController>()) {
    return Get.find<AlertController>();
  }
  try {
    // Lazily register so dialogs work anywhere in the app.
    return Get.put<AlertController>(AlertController(), permanent: true);
  } catch (_) {
    return null;
  }
}

Future<void> showSilenceAlarmDialog({
  required String title,
  required String body,
  int? alertId, // optional: acknowledge on backend if present
}) async {
  final alarm = ensureAlarm();
  final alertController = _getAlertControllerOrNull();

  // Ensure alarm is running (caller may have started it already)
  if (!alarm.isActive) {
    await alarm.start();
  }

  // Avoid stacking
  if (Get.isDialogOpen == true) Get.back();

  await Get.dialog(
    AlertDialog(
      backgroundColor: Colors.white,
      //surfaceTintColor: Colors.orangeAccent,
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
            TextButton(
              onPressed: () => Get.back(), // keep ringing, just close dialog
              child: const Text(
                AppDialogText.keepRinging,
                style: TextStyle(color: Color.fromARGB(255, 13, 13, 13)),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              icon: const Icon(Icons.volume_off),
              style: FilledButton.styleFrom(backgroundColor: Colors.white),
              onPressed: () async {
                if (alertId != null && alertId > 0 && alertController != null) {
                  try { await alertController.acknowledgeAlert(alertId); } catch (_) {}
                }
                await alarm.stop();
                Get.back();
              },
              label: const Text(
                AppDialogText.acknowledge,
                style: TextStyle(color: Color(0xFFE40404)),
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
  final alertController = _getAlertControllerOrNull();

  // No stacking
  if (Get.isDialogOpen == true) Get.back();

  await Get.defaultDialog(
    title: (title == null || title.isEmpty) ? AppDialogText.resolveTitle : title,
    middleText: (body == null || body.isEmpty) ? AppDialogText.resolveBody : body,
    middleTextStyle: const TextStyle(fontSize: 14, color: Color.fromARGB(255, 97, 4, 4)),
    barrierDismissible: false,
    radius: 12,
    actions: [
      TextButton(
        onPressed: () => Get.back(),
        child: const Text(AppDialogText.cancel),
      ),
      SizedBox(width: 12),
      FilledButton(
        onPressed: () async {
          if (alertController != null) {
            try { await alertController.resolveAlert(alertId); } catch (_) {}
          }
          try { await ensureAlarm().stop(); } catch (_) {}
          Get.back();
        },
        child: const Text(AppDialogText.resolve),
      ),
    ],
  );
}
