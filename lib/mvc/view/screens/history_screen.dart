import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Example history data
    final List<Map<String, String>> history = [
      {
        'event': 'Fire Alarm Triggered',
        'details': 'Building B, Floor 3',
        'date': 'Sep 3, 2025 - 14:32',
      },
      {
        'event': 'System Test',
        'details': 'All sensors checked',
        'date': 'Sep 2, 2025 - 09:15',
      },
      {
        'event': 'Sensor Restored',
        'details': 'Sensor #7 online',
        'date': 'Sep 1, 2025 - 17:48',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        backgroundColor: Colors.redAccent,
        centerTitle: true,
      ),
      body:
          history.isEmpty
              ? const Center(
                child: Text(
                  'No history records found.',
                  style: TextStyle(fontSize: 18, color: Colors.black54),
                ),
              )
              : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: history.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final record = history[index];
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.history,
                        color: Colors.redAccent,
                        size: 32,
                      ),
                      title: Text(
                        record['event'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: Colors.redAccent,
                        ),
                      ),
                      subtitle: Text(
                        record['details'] ?? '',
                        style: const TextStyle(fontSize: 15),
                      ),
                      trailing: Text(
                        record['date'] ?? '',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
