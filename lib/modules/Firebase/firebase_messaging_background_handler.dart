import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final _fln = FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Expect data like: {type: "alert", status: "unresolved", alertId: "30", ...}
  final data = message.data;
  if (data['type'] == 'alert' && (data['status'] ?? '') != 'resolved') {
    // Show high-priority notification with custom siren
    const android = AndroidNotificationDetails(
      'fire_alerts',                 // channel id
      'Fire Alerts',                 // channel name
      channelDescription: 'Unresolved fire alerts',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('siren'), // res/raw/siren.mp3
      fullScreenIntent: true, // pops on lock screen
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.alarm,
    );
    const notif = NotificationDetails(android: android);
    await _fln.show(
      1001,                          // notification id
      '🔥 Fire Alert!',
      'Tap to resolve Alert #${data['alertId']}',
      notif,
      payload: data['alertId'],
    );
  }
}
