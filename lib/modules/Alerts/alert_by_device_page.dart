import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vibration/vibration.dart';
import 'alert_controller.dart';
import 'alert_model.dart';
import '../Devices/device_controller.dart';

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
        deviceCtrl.loadAll(); // uses your existing method
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
                value:
                    selectedDeviceId.value == 0 ? null : selectedDeviceId.value,
                hint: const Text('Select a Device'),
                items:
                    deviceCtrl.devices.map((d) {
                      final int id = d.id;
                      final String label =
                          (d.deviceName?.isNotEmpty == true)
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
                  return const Center(
                    child: Text('No alerts for this device.'),
                  );
                }

                return ListView.builder(
                  itemCount: alertCtrl.alerts.length,
                  itemBuilder: (_, i) {
                    final AlertModel a = alertCtrl.alerts[i];

                    //*________ Show fire dialog if unresolved_________
                    if (a.status.toLowerCase() != 'resolved') {
                      Future.microtask(
                        () => _showFireDialog(context, alertCtrl, a),
                      );
                    }
                    //*_______________________________________________
                    //*________ Return alert card __________________//
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: Icon(
                          a.status.toLowerCase() == 'resolved'
                              ? Icons.check_circle
                              : Icons.warning_amber_rounded,
                          color:
                              a.status.toLowerCase() == 'resolved'
                                  ? Colors.green
                                  : Colors.red,
                        ),
                        title: Text(
                          '${a.alertType.toUpperCase()} - ${a.status.toUpperCase()}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Device: ${a.deviceHardwareIdentifier}\n'
                          'Triggered: ${a.triggeredAt}\n'
                          'Resolved: ${a.resolvedAt ?? 'Pending'}',
                        ),
                        onTap: () => _showDetailsDialog(context, a),
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

  //* Popup when an unresolved alert is detected:
  //* ------------lets user resolve immediately----------------//
  void _showFireDialog(
    BuildContext context,
    AlertController controller,
    AlertModel a,
  ) async {
    final player = AudioPlayer();
    //*---------------- 🔊 Start siren/alarm sound---------------------
    await player.setReleaseMode(ReleaseMode.loop);
    await player.play(AssetSource('assets/sounds/alarm1.mp3'), volume: 1.0);

    //*-------------- 📳 Start vibration if available-----------------
    if (await Vibration.hasVibrator() ?? false) {
      // pattern: [delay, vibrate, pause, vibrate, pause, ...]
      Vibration.vibrate(
        pattern: [0, 800, 400, 800, 400],
        repeat: 0, // repeat from index 0 of the pattern
      );
    }
    //*______________ 🔔 Show the fire alert dialog_________________
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            title: const Text(
              '🔥 Fire Alert!',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            content: Text(
              'Alert Type: ${a.alertType}\n'
              'Device: ${a.deviceHardwareIdentifier}\n'
              'Status: ${a.status}',
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  await controller.resolveAlert(
                    a.id,
                  ); // calls /alerts/<id>/resolve/
                  await player.stop(); // stop alarm sound
                  Vibration.cancel(); // stop vibration
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text(
                  'Resolve',
                  style: TextStyle(color: Colors.deepOrange),
                ),
              ),
            ],
          ),
    );
  }

  //*______________ Full info dialog ____________________*//
  void _showDetailsDialog(BuildContext context, AlertModel a) {
    showDialog(
      context: context,
      builder:
          (_) => Dialog(
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
                      'Alert #${a.id}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.deepOrangeAccent,
                      ),
                    ),
                  ),
                  const Divider(height: 24),
                  _row('Device ID', a.device.toString()),
                  _row('Hardware', a.deviceHardwareIdentifier),
                  _row('Type', a.alertType),
                  _row('Status', a.status),
                  _row('Triggered At', a.triggeredAt.toString()),
                  _row('Resolved At', a.resolvedAt?.toString() ?? 'Pending'),
                  _row('Owner ID', a.ownerId.toString()),
                  _row('Owner Email', a.ownerEmail),
                  _row(
                    'Owner Phone',
                    a.ownerPhone.isEmpty ? 'N/A' : a.ownerPhone,
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.center,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
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

  //*______________ Detail row widget ____________________*//
  Widget _row(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Text(
            '$k:',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: Text(
            v,
            style: const TextStyle(
              color: Colors.deepOrange,
              fontWeight: FontWeight.bold, // value in deep orange
            ),
          ),
        ),
      ],
    ),
  );
}
