import 'package:flutter/material.dart';

class AlertScreen extends StatelessWidget {
  const AlertScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Example alert data
    final List<Map<String, String>> alerts = [
      {
        'title': 'Fire Detected',
        'description': 'Smoke detected in Building A, Floor 2.',
        'time': '2 min ago',
      },
      {
        'title': 'Sensor Offline',
        'description': 'Sensor #12 is not responding.',
        'time': '10 min ago',
      },
      {
        'title': 'Test Alert',
        'description': 'System test completed successfully.',
        'time': '30 min ago',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts'),
        backgroundColor: Colors.redAccent,
        centerTitle: true,
      ),
      body:
          alerts.isEmpty
              ? const Center(
                child: Text(
                  'No alerts at the moment.',
                  style: TextStyle(fontSize: 18, color: Colors.black54),
                ),
              )
              : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: alerts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final alert = alerts[index];
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: Icon(
                        alert['title'] == 'Fire Detected'
                            ? Icons.warning_amber_rounded
                            : Icons.notifications_active,
                        color: Colors.redAccent,
                        size: 32,
                      ),
                      title: Text(
                        alert['title'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.redAccent,
                        ),
                      ),
                      subtitle: Text(
                        alert['description'] ?? '',
                        style: const TextStyle(fontSize: 15),
                      ),
                      trailing: Text(
                        alert['time'] ?? '',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
