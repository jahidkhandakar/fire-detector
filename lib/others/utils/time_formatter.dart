import 'package:intl/intl.dart';

DateTime? parseApiDateTime(String input) {
  if (input.isEmpty) return null;

  // If ends with +HHMM or -HHMM, insert the colon
  final tzFix = RegExp(r'([+-]\d{2})(\d{2})$');
  var fixed = input;
  if (tzFix.hasMatch(input)) {
    fixed = input.replaceFirstMapped(tzFix, (m) => '${m[1]}:${m[2]}');
  }

  try {
    return DateTime.parse(fixed);
  } catch (_) {
    return null;
  }
}

String formatAbsolute(DateTime dt) {
  // Example: Oct 6, 2025 · 8:28 AM
  final d = DateFormat('MMM d, y · h:mm a');
  return d.format(dt);
}

String formatRelative(DateTime dt, {DateTime? now}) {
  now ??= DateTime.now();
  final diff = now.difference(dt);

  if (diff.inSeconds.abs() < 60) return 'just now';
  if (diff.inMinutes.abs() < 60) {
    final m = diff.inMinutes.abs();
    return diff.isNegative ? 'in $m min' : '$m min ago';
  }
  if (diff.inHours.abs() < 24) {
    final h = diff.inHours.abs();
    return diff.isNegative ? 'in $h hr' : '$h hr ago';
  }

  // Fallback to days
  final d = diff.inDays.abs();
  return diff.isNegative ? 'in $d days' : '$d days ago';
}

/// Full human label: "Oct 6, 2025 · 8:28 AM (14 min ago)"
String formatHuman(DateTime dt, {DateTime? now}) {
  return '${formatAbsolute(dt)} (${formatRelative(dt, now: now)})';
}
