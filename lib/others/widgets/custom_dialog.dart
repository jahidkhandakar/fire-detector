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

Future<void> showSilenceAlarmDialog({
  required String title,
  required String body,
  int? alertId, // optional: if present, we’ll call acknowledge on tap
}) async {
  final alarm = ensureAlarm();
  final alertController = Get.find<AlertController>();

  // Make sure alarm is running (caller may have started it already)
  if (!alarm.isActive) {
    await alarm.start();
  }

  // Avoid stacking
  if (Get.isDialogOpen == true) Get.back();

  await Get.dialog(
    AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.orangeAccent,
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
                style: TextStyle(color: Color(0xFF018505)),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              icon: const Icon(Icons.volume_off),
              style: FilledButton.styleFrom(backgroundColor: Colors.white),
              onPressed: () async {
                // optional: acknowledge on backend
                if (alertId != null && alertId > 0) {
                  await alertController.acknowledgeAlert(alertId);
                }
                await alarm.stop();
                Get.back(); // close dialog
              },
              label: const Text(
                AppDialogText.acknowledge,
                style: TextStyle(color: Colors.deepOrange),
              ),
            ),
          ],
        ),
      ],
    ),
    barrierDismissible: false,
  );
}

Future<void> showResolveDialog({
  required int alertId,
  String? title,
  String? body,
}) {
  final alertController = Get.find<AlertController>();

  // No stacking
  if (Get.isDialogOpen == true) Get.back();

  return Get.defaultDialog(
    title: (title == null || title.isEmpty) ? AppDialogText.resolveTitle : title,
    middleText: (body == null || body.isEmpty) ? AppDialogText.resolveBody : body,
    barrierDismissible: false,
    radius: 12,
    actions: [
      TextButton(
        onPressed: () => Get.back(),
        child: const Text(AppDialogText.cancel),
      ),
      FilledButton(
        onPressed: () async {
          await alertController.resolveAlert(alertId);
          Get.back();
        },
        child: const Text(AppDialogText.resolve),
      ),
    ],
  );
}
