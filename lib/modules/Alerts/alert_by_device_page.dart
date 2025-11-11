import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'alert_controller.dart';
import 'alert_model.dart';
import '../Devices/device_controller.dart';
import '/others/widgets/custom_dialog.dart';

class AlertByDevicePage extends StatelessWidget {
  const AlertByDevicePage({super.key});

  @override
  Widget build(BuildContext context) {
    final alertCtrl = Get.put(AlertController());
    final deviceCtrl = Get.put(DeviceController());
    final selectedDeviceId = 0.obs;

    // Load devices once on first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (deviceCtrl.devices.isEmpty && !deviceCtrl.isLoading.value) {
        deviceCtrl.loadAll();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Alerts'),
        backgroundColor: Colors.deepOrange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Device dropdown
            Obx(() {
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
                      onPressed: deviceCtrl.loadAll,
                      child: const Text('Retry'),
                    ),
                  ],
                );
              }
              if (deviceCtrl.devices.isEmpty) {
                return const Text('No devices found.');
              }

              return DropdownButtonFormField<int>(
                value: selectedDeviceId.value == 0 ? null : selectedDeviceId.value,
                hint: const Text('Select a Device'),
                items: deviceCtrl.devices.map((d) {
                  final int id = d.id;
                  final String label = (d.deviceName?.isNotEmpty == true)
                      ? d.deviceName!
                      : (d.hardwareIdentifier?.isNotEmpty == true)
                          ? d.hardwareIdentifier!
                          : 'Device #$id';
                  return DropdownMenuItem<int>(
                    value: id,
                    child: Text(label),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  selectedDeviceId.value = value;
                  alertCtrl.loadAlertsByDevice(value);
                },
              );
            }),
            const SizedBox(height: 20),

            // Alerts for selected device
            Expanded(
              child: Obx(() {
                if (alertCtrl.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (alertCtrl.error.isNotEmpty) {
                  return Center(child: Text(alertCtrl.error.value));
                }
                if (alertCtrl.alerts.isEmpty) {
                  return const Center(child: Text('No alerts for this device.'));
                }

                return ListView.builder(
                  itemCount: alertCtrl.alerts.length,
                  itemBuilder: (_, i) {
                    final AlertModel alert = alertCtrl.alerts[i];

                    // 🔕 If unresolved → show your *silent* Resolve dialog (no alarm/vibration)
                    if (alert.status.toLowerCase() != 'resolved') {
                      Future.microtask(() {
                        showResolveDialog(
                          alertId: alert.id,
                          title: 'Resolve Alert?',
                          body:
                              'ALERT TYPE : ${alert.alertType}\n'
                              'DEVICE     : ${alert.deviceHardwareIdentifier}\n'
                              'STATUS     : ${alert.status}\n\n'
                              'Mark this alert as resolved for everyone?',
                        );
                      });
                    }

                    // Card UI
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
                        subtitle: Text(
                          'Device: ${alert.deviceHardwareIdentifier}\n'
                          'Triggered: ${alert.triggeredAt}\n'
                          'Resolved: ${alert.resolvedAt ?? 'Pending'}',
                        ),
                        onTap: () => _showDetailsDialog(context, alert),
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

  // Details dialog (unchanged)
  void _showDetailsDialog(BuildContext context, AlertModel alert) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Icon(Icons.info_outline, color: Colors.deepOrangeAccent, size: 44),
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
              _row('Triggered At', alert.triggeredAt.toString()),
              _row('Resolved At', alert.resolvedAt?.toString() ?? 'Pending'),
              _row('Owner ID', alert.ownerId.toString()),
              _row('Owner Email', alert.ownerEmail),
              _row('Owner Phone', alert.ownerPhone.isEmpty ? 'N/A' : alert.ownerPhone),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.center,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text('Close', style: TextStyle(color: Colors.white)),
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
                style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black54),
              ),
            ),
            Expanded(
              flex: 5,
              child: Text(
                valueText,
                style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
}
