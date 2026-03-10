import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '/others/theme/app_theme.dart';
import '/others/widgets/custom_message.dart';
import '/others/widgets/time_field.dart';
import 'alert_controller.dart';
import 'alert_model.dart';
import '../devices/device_controller.dart';
import '/others/widgets/custom_dialog.dart'; // showResolveDialog

class AlertByDevicePage extends StatelessWidget {
  const AlertByDevicePage({super.key});

  @override
  Widget build(BuildContext context) {
    final alertCtrl = Get.put(AlertController());
    final deviceCtrl = Get.put(DeviceController());
    final selectedDeviceId = 0.obs;

    // Load devices once on first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('[AlertByDevicePage] Post-frame callback triggered.');
      if (deviceCtrl.devices.isEmpty && !deviceCtrl.isLoading.value) {
        debugPrint(
            '[AlertByDevicePage] Device list empty → calling deviceCtrl.loadAll()');
        deviceCtrl.loadAll();
      } else {
        debugPrint(
            '[AlertByDevicePage] Devices already loaded or loading in progress.');
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Alerts'),
        backgroundColor: AppTheme().secondaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // ───────────────── Device dropdown ─────────────────
            Obx(() {
              debugPrint(
                  '[AlertByDevicePage] Device Obx rebuilt. isLoading=${deviceCtrl.isLoading.value}, devices=${deviceCtrl.devices.length}, error="${deviceCtrl.error.value}"');

              if (deviceCtrl.isLoading.value && deviceCtrl.devices.isEmpty) {
                return const LinearProgressIndicator();
              }
              if (deviceCtrl.error.isNotEmpty) {
                return Row(
                  children: [
                    Expanded(
                      child: Text(
                        deviceCtrl.error.value,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        debugPrint(
                            '[AlertByDevicePage] Retry devices tapped → deviceCtrl.loadAll()');
                        deviceCtrl.loadAll();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                );
              }
              if (deviceCtrl.devices.isEmpty) {
                return const CustomMessage(
                  message: 'No devices found.',
                  icon: '⚠️',
                );
              }

              return DropdownButtonFormField<int>(
                value: selectedDeviceId.value == 0
                    ? null
                    : selectedDeviceId.value,
                hint: const Text('Select a Device'),
                items: deviceCtrl.devices.map((d) {
                  final int id = d.id;
                  final String label = (d.deviceName.isNotEmpty == true)
                      ? d.deviceName
                      : (d.hardwareIdentifier.isNotEmpty == true)
                          ? d.hardwareIdentifier
                          : 'Device #$id';
                  return DropdownMenuItem<int>(
                    value: id,
                    child: Text(label),
                  );
                }).toList(),
                onChanged: (value) async {
                  if (value == null) return;
                  debugPrint(
                      '[AlertByDevicePage] Device dropdown changed → id=$value');

                  selectedDeviceId.value = value;

                  // Load alerts for this device
                  await alertCtrl.loadAlertsByDevice(value);
                  debugPrint(
                      '[AlertByDevicePage] Alerts loaded for device $value → count=${alertCtrl.alerts.length}');

                  // Find the latest unresolved alert (status != resolved, max triggeredAt)
                  AlertModel? latestUnresolved;
                  for (final alert in alertCtrl.alerts) {
                    final status = alert.status.toLowerCase();
                    debugPrint(
                        '[AlertByDevicePage] Inspecting alert id=${alert.id}, status=$status, triggeredAt=${alert.triggeredAt.toIso8601String()}');

                    if (status != 'resolved') {
                      if (latestUnresolved == null ||
                          alert.triggeredAt
                              .isAfter(latestUnresolved.triggeredAt)) {
                        latestUnresolved = alert;
                      }
                    }
                  }

                  if (latestUnresolved != null) {
                    debugPrint(
                        '[AlertByDevicePage] Latest unresolved alert found → id=${latestUnresolved.id}, status=${latestUnresolved.status}, triggeredAt=${latestUnresolved.triggeredAt.toIso8601String()}');

                    await showResolveDialog(
                      alertId: latestUnresolved.id,
                      title: 'Resolve Alert?',
                      body: 'ALERT TYPE : ${latestUnresolved.alertType}\n'
                          'DEVICE     : ${latestUnresolved.deviceHardwareIdentifier}\n'
                          'STATUS     : ${latestUnresolved.status}\n\n'
                          'Mark this alert as resolved for everyone?',
                    );
                  } else {
                    debugPrint(
                        '[AlertByDevicePage] No unresolved alerts for device $value');
                  }
                },
              );
            }),
            const SizedBox(height: 20),

            // ───────────────── Alerts for selected device ─────────────────
            Expanded(
              child: Obx(() {
                debugPrint(
                    '[AlertByDevicePage] Alerts Obx rebuilt. isLoading=${alertCtrl.isLoading.value}, alerts=${alertCtrl.alerts.length}, error="${alertCtrl.error.value}", selectedDeviceId=${selectedDeviceId.value}');

                if (alertCtrl.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (alertCtrl.error.isNotEmpty) {
                  return Center(child: Text(alertCtrl.error.value));
                }
                if (alertCtrl.alerts.isEmpty) {
                  return const CustomMessage(
                    message: 'No alerts found for this device.',
                    icon: '⚠️',
                  );
                }

                debugPrint(
                    '[AlertByDevicePage] Building alert list with ${alertCtrl.alerts.length} items.');

                return ListView.builder(
                  itemCount: alertCtrl.alerts.length,
                  itemBuilder: (_, i) {
                    final AlertModel alert = alertCtrl.alerts[i];

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: Icon(
                          alert.status.toLowerCase() == 'resolved'
                              ? Icons.check_circle
                              : Icons.warning_amber_rounded,
                          color: alert.status.toLowerCase() == 'resolved'
                              ? Colors.green
                              : Colors.red,
                        ),
                        title: Text(
                          '${alert.alertType.toUpperCase()} - ${alert.status.toUpperCase()}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                'Device: ${alert.deviceHardwareIdentifier}'),
                            const SizedBox(height: 4),
                            TimeField(
                              label: 'Triggered',
                              raw: alert.triggeredAt.toIso8601String(),
                              icon: Icons.schedule,
                              localeTag: 'en_US', // or 'bn_BD'
                              fallback: '—',
                            ),
                            TimeField(
                              label: 'Resolved',
                              raw: alert.resolvedAt != null
                                  ? alert.resolvedAt!.toIso8601String()
                                  : '',
                              icon: Icons.schedule,
                              localeTag: 'en_US',
                              fallback: 'Pending',
                            ),
                          ],
                        ),
                        onTap: () {
                          debugPrint(
                              '[AlertByDevicePage] ListTile tapped → alertId=${alert.id}');
                          _showDetailsDialog(context, alert);
                        },
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // Details dialog
  void _showDetailsDialog(BuildContext context, AlertModel alert) {
    debugPrint(
        '[AlertByDevicePage] _showDetailsDialog called → alertId=${alert.id}');
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Icon(
                  Icons.info_outline,
                  color: Colors.deepOrangeAccent,
                  size: 44,
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Alert #${alert.id}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.deepOrangeAccent,
                  ),
                ),
              ),
              const Divider(height: 24),
              _row('Device ID', alert.device.toString()),
              _row('Hardware', alert.deviceHardwareIdentifier),
              _row('Type', alert.alertType),
              _row('Status', alert.status),

              // Triggered / Resolved with null-safe handling
              TimeField(
                label: 'Triggered At',
                raw: alert.triggeredAt.toIso8601String(),
                icon: Icons.schedule,
                localeTag: 'en_US',
                fallback: '—',
              ),
              TimeField(
                label: 'Resolved At',
                raw: alert.resolvedAt != null
                    ? alert.resolvedAt!.toIso8601String()
                    : '',
                icon: Icons.check_circle_outline,
                localeTag: 'en_US',
                fallback: 'Pending',
              ),

              _row('Owner ID', alert.ownerId.toString()),
              _row('Owner Email', alert.ownerEmail),
              _row(
                'Owner Phone',
                alert.ownerPhone.isEmpty ? 'N/A' : alert.ownerPhone,
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.center,
                child: ElevatedButton.icon(
                  onPressed: () {
                    debugPrint(
                        '[AlertByDevicePage] Details dialog Close pressed → alertId=${alert.id}');
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.close),
                  label: const Text(
                    'Close',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String keyText, String valueText) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Text(
                '$keyText:',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
            ),
            Expanded(
              flex: 5,
              child: Text(
                valueText,
                style: const TextStyle(
                  color: Colors.deepOrange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
}
