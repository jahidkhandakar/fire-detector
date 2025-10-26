import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

final _fmt = DateFormat('MMM d, y • h:mm a'); // e.g., Sep 30, 2025 • 6:37 PM

/// Parses ISO strings that may use +0600 (no colon). We insert the missing colon.
String _fixTz(String iso) {
  // Minimal guard for offsets like +0600 or -0530
  // Example length: 2025-09-30T18:37:17+0600 (len 24, ':' at 22 is missing)
  if (iso.length >= 24) {
    final ch = iso[iso.length - 3];
    if (ch != ':') {
      return iso.substring(0, iso.length - 2) + ':' + iso.substring(iso.length - 2);
    }
  }
  return iso;
}

String formatDate(String iso) {
  try {
    final fixed = _fixTz(iso);
    final dt = DateTime.parse(fixed);
    return _fmt.format(dt.toLocal());
  } catch (_) {
    return iso; // fallback to raw if parse fails
  }
}

String titleize(String s) {
  return s
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) => w.isEmpty ? w : (w[0].toUpperCase() + w.substring(1)))
      .join(' ');
}

Color statusColor(String status) {
  switch (status.toLowerCase()) {
    case 'resolved':
      return Colors.green;
    case 'open':
    case 'active':
      return Colors.deepOrange;
    default:
      return Colors.blueGrey;
  }
}
