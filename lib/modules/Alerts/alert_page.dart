import 'package:fire_alarm/others/theme/app_theme.dart';
import 'package:fire_alarm/others/widgets/time_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'alert_controller.dart';
import 'alert_model.dart';
import 'package:fire_alarm/others/utils/api.dart';
import '/modules/Firebase/push_notification_service.dart';

class AlertPage extends StatefulWidget {
  const AlertPage({super.key});

  @override
  State<AlertPage> createState() => _AlertPageState();
}

class _AlertPageState extends State<AlertPage> {
  final AlertController controller = Get.put(AlertController());
  final String apiUrl = Api.alerts;

  @override
  void initState() {
    super.initState();

    // ✅ Initialize Push Notification listener (if not already)
    PushNotificationService.initialize();

    // ✅ Load alerts initially
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadAlerts(apiUrl: apiUrl);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fire Alerts'),
        backgroundColor: AppTheme().secondaryColor,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.error.value.isNotEmpty) {
          return Center(child: Text(controller.error.value));
        }

        if (controller.alerts.isEmpty) {
          return const Center(child: Text('No alerts found.'));
        }

        return RefreshIndicator(
          onRefresh: () => controller.loadAlerts(apiUrl: apiUrl),
          child: ListView.builder(
            itemCount: controller.alerts.length,
            itemBuilder: (context, index) {
              final AlertModel alert = controller.alerts[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                elevation: 2,
                child: ListTile(
                  leading: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.redAccent,
                  ),
                  title: Text(
                    '${alert.alertType.toUpperCase()}  :  ${alert.status.toUpperCase()}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Device: ${alert.deviceHardwareIdentifier}'),
                      const SizedBox(height: 4),
                      TimeField(
                        label: 'Triggered',
                        // if triggeredAt is DateTime?
                        raw: alert.triggeredAt.toIso8601String(),
                        // if it's already a String from API, use: raw: alert.triggeredAt,
                        icon: Icons.schedule,
                        localeTag: 'en_US', // or 'bn_BD'
                        fallback: '—',
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.info_outline, size: 20),
                  onTap: () => _showAlertDetailsDialog(context, alert),
                ),
              );
            },
          ),
        );
      }),
    );
  }

  //*--------- Show alert details dialog ---------*
  void _showAlertDetailsDialog(BuildContext context, AlertModel alert) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.deepOrange,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    alert.alertType.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange,
                    ),
                  ),
                ),
                const Divider(height: 25, thickness: 1.2),
                _buildDetailRow('ID', alert.id.toString()),
                _buildDetailRow('Device ID', alert.device.toString()),
                _buildDetailRow(
                  'Hardware Identifier',
                  alert.deviceHardwareIdentifier,
                ),
                _buildDetailRow('Alert Type', alert.alertType),
                _buildDetailRow('Status', alert.status),
                //_____________Tiggered At and Resolved At using TimeField_____________
                TimeField(
                  label: 'Triggered At',
                  raw: alert.triggeredAt.toIso8601String(),
                  icon: Icons.schedule,
                  localeTag: 'en_US',
                  fallback: '—',
                ),
                TimeField(
                  label: 'Resolved At',
                  raw: alert.resolvedAt!.toIso8601String(),              
                  icon: Icons.check_circle_outline,
                  localeTag: 'en_US',
                  fallback: 'Pending',
                ),
                //_________________________________________________________
                _buildDetailRow('Owner ID', alert.ownerId.toString()),
                _buildDetailRow('Owner Email', alert.ownerEmail),
                _buildDetailRow(
                  'Owner Phone',
                  alert.ownerPhone.isEmpty ? 'N/A' : alert.ownerPhone,
                ),
                const SizedBox(height: 25),
                Align(
                  alignment: Alignment.center,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    label: const Text('Close'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  //*------------ Helper for key-value rows ------------*
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(value, style: const TextStyle(color: Colors.black54)),
          ),
        ],
      ),
    );
  }
}
