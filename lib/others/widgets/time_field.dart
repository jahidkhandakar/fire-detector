import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TimeField extends StatelessWidget {
  final String label;
  final String? raw;     // can be null or empty
  final IconData icon;
  final String? fallback; // optional custom fallback text

  const TimeField({
    super.key,
    required this.label,
    required this.raw,
    required this.icon,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final dt = _parseBackendTime(raw);
    final text = dt != null
        ? DateFormat('MMM d, yyyy, h:mm a').format(dt) // local time
        : (fallback ?? '—');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.black54),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Text(
            text,
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  /// Parses backend timestamps like:
  ///  - "2025-10-23T14:11:32+0600"  (no colon in offset)
  ///  - "2025-10-23T14:11:32+06:00" (ISO)
  /// Returns a local DateTime (device timezone), or null on failure/empty.
  DateTime? _parseBackendTime(String? v) {
    if (v == null) return null;
    final s0 = v.trim();
    if (s0.isEmpty || s0.toLowerCase() == 'null') return null;

    // Normalize "+0600" -> "+06:00"
    final normalized = s0.replaceFirst(
      RegExp(r'([+-]\d{2})(\d{2})$'),
      r'\1:\2',
    );

    // Try fast path with DateTime.parse
    try {
      final dt = DateTime.parse(normalized);
      return dt.toLocal();
    } catch (_) {}

    // Fallback using intl parser that understands RFC822 Z format
    try {
      final fmt = DateFormat("yyyy-MM-dd'T'HH:mm:ssZ");
      // parseUtc returns a UTC moment; convert to local display
      final dt = fmt.parseUtc(s0);
      return dt.toLocal();
    } catch (_) {}

    return null;
  }
}
