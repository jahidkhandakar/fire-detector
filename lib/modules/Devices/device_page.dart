import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '/others/widgets/time_field.dart';
import 'device_controller.dart';
import 'device_model.dart';
import 'device_node.dart';
import 'device_register_page.dart';

class DevicePage extends StatefulWidget {
  const DevicePage({super.key});

  @override
  State<DevicePage> createState() => _DevicePageState();
}

class _DevicePageState extends State<DevicePage> {
  final DeviceController _controller = Get.put(DeviceController());

  @override
  void initState() {
    super.initState();
    _controller.loadAll();
    _controller.loadTree();
  }

  @override
  Widget build(BuildContext context) {
    // Parent provides TabBar + Scaffold
    return Obx(() {
      if (_controller.isLoading.value &&
          _controller.devices.isEmpty &&
          _controller.tree.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      if (_controller.error.value.isNotEmpty) {
        return Center(child: Text(_controller.error.value));
      }

      return Column(
        children: [
          // Tabs content
          Expanded(
            child: TabBarView(
              children: [
                // All Devices
                RefreshIndicator(
                  onRefresh: _controller.loadAll,
                  child: _controller.devices.isEmpty
                      ? const Center(child: Text('No devices found.'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _controller.devices.length,
                          itemBuilder: (_, i) =>
                              _buildDeviceCard(_controller.devices[i]),
                        ),
                ),
                // Device Tree
                RefreshIndicator(
                  onRefresh: _controller.loadTree,
                  child: _controller.tree.isEmpty
                      ? const Center(child: Text('No device tree available.'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _controller.tree.length,
                          itemBuilder: (_, i) =>
                              _buildMasterWithSlaves(_controller.tree[i]),
                        ),
                ),
              ],
            ),
          ),

          // Bottom: Register Device
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Register Device'),
                  onPressed: () async {
                    final created =
                        await Get.to<DeviceModel>(() => const DeviceRegisterPage());

                    if (created != null) {
                      // Success: refresh lists, then show success snackbar
                      await _controller.loadAll();
                      await _controller.loadTree();

                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Device registered successfully'),
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    } else {
                      // Failure (no device returned)
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Device registration failed'),
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  // ---------- UI helpers ----------

  Widget _buildDeviceCard(DeviceModel device) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(
          device.deviceRole.toLowerCase() == 'master'
              ? Icons.memory
              : Icons.sensors,
          color: device.online ? Colors.green : Colors.redAccent,
          size: 36,
        ),
        title: Text(
          device.deviceName.trim().isNotEmpty
              ? device.deviceName.trim()
              : 'Unnamed Device',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Role: ${device.deviceRole.toUpperCase()}\n'
          'Status: ${device.effectiveStatus}\n'
          'Owner: ${device.ownerEmail}',
        ),
        trailing: Icon(
          device.online ? Icons.circle : Icons.circle_outlined,
          color: device.online ? Colors.green : Colors.grey,
          size: 18,
        ),
        onTap: () => _showDeviceDetailsDialog(device),
      ),
    );
  }

  Widget _buildMasterWithSlaves(DeviceNode node) {
    final master = node.master;
    final slaves = node.slaves;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ExpansionTile(
        leading: Icon(
          Icons.memory,
          color: master.online ? Colors.green : Colors.redAccent,
          size: 30,
        ),
        title: Text(
          master.deviceName.isNotEmpty
              ? master.deviceName
              : master.hardwareIdentifier,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          'Master • ${master.effectiveStatus} • ${master.ownerEmail}',
          style: const TextStyle(fontSize: 12),
        ),
        childrenPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          if (slaves.isEmpty)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('No slaves connected.',
                  style: TextStyle(color: Colors.black54)),
            )
          else
            ...slaves.map(
              (s) => ListTile(
                leading: const Icon(Icons.sensors),
                title: Text(
                  s.deviceName.isNotEmpty ? s.deviceName : s.hardwareIdentifier,
                ),
                subtitle:
                    Text('Slave • ${s.effectiveStatus} • ${s.ownerEmail}'),
                trailing: Icon(
                  s.online ? Icons.circle : Icons.circle_outlined,
                  color: s.online ? Colors.green : Colors.grey,
                  size: 16,
                ),
                onTap: () => _showDeviceDetailsDialog(s),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _showDeviceDetailsDialog(DeviceModel device) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 8,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Icon(
                    device.deviceRole.toLowerCase() == 'master'
                        ? Icons.memory
                        : Icons.sensors,
                    color: Colors.deepOrangeAccent,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    device.deviceName.trim().isNotEmpty
                        ? device.deviceName.trim().toUpperCase()
                        : 'UNNAMED DEVICE',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrangeAccent,
                    ),
                  ),
                ),
                const Divider(height: 25, thickness: 1.2),

                _detailRow('Device ID', device.id.toString()),
                _detailRow('Hardware Identifier', device.hardwareIdentifier),
                _detailRow('Device Role', device.deviceRole),
                _detailRow('Mesh Alert', device.meshAlert.toString()),
                _detailRow('Latitude', device.latitude),
                _detailRow('Longitude', device.longitude),
                _detailRow('Status', device.status),
                _detailRow('Effective Status', device.effectiveStatus),

                const Divider(height: 20, thickness: 1),
                TimeField(
                  label: 'Registered At',
                  raw: device.registeredAt,
                  icon: Icons.event_available,
                ),
                TimeField(
                  label: 'Last Seen',
                  raw: device.lastSeen,
                  icon: Icons.schedule,
                ),
                const Divider(height: 20, thickness: 1),

                _detailRow('Online', device.online ? 'Yes' : 'No'),
                _detailRow('Owner ID', device.ownerId.toString()),
                _detailRow('Owner Email', device.ownerEmail),
                _detailRow(
                  'Owner Phone',
                  device.ownerPhone.isEmpty ? 'N/A' : device.ownerPhone,
                ),

                const SizedBox(height: 25),
                Align(
                  alignment: Alignment.center,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    label: const Text('Close'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrangeAccent,
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

  Widget _detailRow(String label, String value) {
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
            child: Text(
              value.isEmpty ? 'N/A' : value,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}
