import 'package:firebase_messaging/firebase_messaging.dart';
class AppMessages {
  static const loudChannelId   = 'high_smoke_alerts_v2';
  static const loudChannelName = 'High Smoke Alerts';
  static const silentChannelId   = 'high_smoke_alerts_silent';
  static const silentChannelName = 'High Smoke Alerts (Silent)';

  static const snackbarDurationSeconds = 4;

  static const dialogTitleFallback   = 'High Smoke Detected';
  static const dialogContentFallback =
      'Turn off sound and vibration? You can resolve the alert from the Alerts screen.';
  static const dialogKeepRinging = 'Keep Ringing';
  static const dialogAcknowledge = 'Acknowledge';
}

class FirebaseMessage {
  final String? title;
  final String? body;
  final Map<String, dynamic> data;

  const FirebaseMessage({required this.title, required this.body, required this.data});

  factory FirebaseMessage.fromRemoteMessage(RemoteMessage remoteMessage) {
    final d = remoteMessage.data;
    final t = _nonEmpty(remoteMessage.notification?.title) ?? _nonEmpty(d['title']?.toString());
    final b = _nonEmpty(remoteMessage.notification?.body ) ?? _nonEmpty(d['body'] ?.toString());
    return FirebaseMessage(title: t, body: b, data: d);
  }

  factory FirebaseMessage.fromMap(Map<String, dynamic> d) {
    final t = _nonEmpty(d['title']?.toString());
    final b = _nonEmpty(d['body'] ?.toString());
    return FirebaseMessage(title: t, body: b, data: d);
  }

  bool get isActive => (data['status'] ?? '').toString().toLowerCase() != 'resolved';
  int  get alertId  => int.tryParse('${data['alert_id'] ?? ''}') ?? -1;

  bool get hasExplicitText =>
      (title != null && title!.trim().isNotEmpty) ||
      (body  != null && body! .trim().isNotEmpty);

  String get dedupeKey =>
      '${data['device_id'] ?? ''}|${data['alert_id'] ?? ''}|${data['status'] ?? ''}';

  int get stableNotificationId =>
      ('${data['device_id'] ?? ''}|${data['alert_id'] ?? ''}').hashCode;

  static String? _nonEmpty(String? v) {
    if (v == null) return null;
    final t = v.trim();
    return t.isEmpty ? null : t;
  }
}

