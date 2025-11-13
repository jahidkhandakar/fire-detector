import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TimeField extends StatelessWidget {
  final String label;
  final String? raw; // can be null or empty
  final IconData icon;
  final String? fallback; // optional custom fallback text
  final String? localeTag; // e.g. 'en_US', 'bn_BD'; null = device locale

  const TimeField({
    super.key,
    required this.label,
    required this.raw,
    required this.icon,
    this.fallback,
    this.localeTag,
  });

  @override
  Widget build(BuildContext context) {
    final dt = _parseBackendTime(raw);
    final loc =
        localeTag ??
        Localizations.localeOf(context).toLanguageTag().replaceAll('-', '_');
    final text =
        dt != null
            ? DateFormat('d MMMM yyyy, h:mm a', loc).format(dt)
            : (fallback ?? '—');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.black54),
          const SizedBox(width: 8),

          // ⬇️ Stack label above the formatted time to avoid vertical wrapping
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  text, // e.g., "12 November 2025, 8:00 PM"
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
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

    // Fast path: ISO/RFC3339
    try {
      final dt = DateTime.parse(normalized);
      return dt.toLocal();
    } catch (_) {}

    // Fallback: RFC822-style "Z" (use normalized here too)
    try {
      final fmt = DateFormat("yyyy-MM-dd'T'HH:mm:ssZ");
      final dt = fmt.parseUtc(normalized);
      return dt.toLocal();
    } catch (_) {}

    return null;
  }
}
