import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

import '/others/utils/api.dart';
import '/others/widgets/alarm_service.dart';              // ensureAlarm()
import '/others/widgets/custom_dialog.dart' as ui;       // showSilenceAlarmDialog / showResolveDialog
import '/modules/Firebase/message.dart';                 // AppMessages, FirebaseMessage

class PushNotificationService {
  // ---- one-time init guard ----
  static bool _initialized = false;

  // ---- firebase + local notif clients ----
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();
  static final http.Client _http = http.Client();

  // ---- de-dupe recent alerts (tray/snackbar spam) ----
  static final Map<String, DateTime> _recentKeys = <String, DateTime>{};
  static const Duration _dedupeTtl = Duration(minutes: 2);

  // ---- show Acknowledge dialog only once per alert (works for fg + tap) ----
  static final Set<String> _ackDialogShown = <String>{};
  static String _ackKeyFor(FirebaseMessage m) {
    if (m.alertId > 0) return 'id:${m.alertId}';
    final k = m.dedupeKey.trim();
    if (k.isNotEmpty) return 'key:$k';
    return 'tb:${m.title ?? ''}|${m.body ?? ''}';
  }

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // Register background handler early
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 1) Permissions
    await _fcm.requestPermission(alert: true, badge: true, sound: true);
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2) Local notifications init
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const init = InitializationSettings(android: androidInit, iOS: iosInit);

    await _local.initialize(
      init,
      onDidReceiveNotificationResponse: (resp) {
        final payload = resp.payload;
        if (payload != null && payload.isNotEmpty) {
          try {
            final map = jsonDecode(payload) as Map<String, dynamic>;
            _routeFromPayload(map, armAfterRoute: true);
          } catch (_) {
            // Fall back to Alerts screen
            Get.toNamed('/alerts');
          }
        } else {
          Get.toNamed('/alerts');
        }
      },
    );

    // 3) Create BOTH channels (Android 8+)
    final androidImpl =
        _local.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    // Loud channel (with siren) — MUST match AndroidManifest default channel
    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        AppMessages.loudChannelId,
        AppMessages.loudChannelName,
        description: 'Unresolved fire/smoke alerts',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('fire_alarm'),
        enableVibration: true,
      ),
    );

    // Silent channel (no extra audio while foreground)
    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        AppMessages.silentChannelId,
        AppMessages.silentChannelName,
        description: 'Foreground visual alerts without sound',
        importance: Importance.max,
        playSound: false,
        enableVibration: false,
      ),
    );

    // 4) Register device token (+ refresh)
    final tok = await _fcm.getToken();
    if (tok != null && tok.isNotEmpty) {
      await _registerDeviceToken(tok);
    }
    _fcm.onTokenRefresh.listen((t) async => _registerDeviceToken(t));

    // 5) Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage rm) async {
      final msg = FirebaseMessage.fromRemoteMessage(rm);

      // Deduplicate frequent repeats for a short window
      _recentKeys.removeWhere((_, exp) => DateTime.now().isAfter(exp));
      final key = msg.dedupeKey.trim();
      if (key.isNotEmpty) {
        if (_recentKeys.containsKey(key)) {
          debugPrint('⏭️ Skipping duplicate alert within TTL: $key');
          return;
        }
        _recentKeys[key] = DateTime.now().add(_dedupeTtl);
      }

      final isLoggedIn = _isLoggedIn();

      // Optional: show snackbar only if we have text
      if (msg.hasExplicitText) {
        if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
        Get.snackbar(
          msg.title!, msg.body!,
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
          icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
          duration: const Duration(seconds: AppMessages.snackbarDurationSeconds),
        );
      }

      // 👉 Foreground path: for ACTIVE alerts we always pop the Acknowledge dialog (once)
      if (isLoggedIn && msg.isActive) {
        final ackKey = _ackKeyFor(msg);
        if (_ackDialogShown.add(ackKey)) {
          // start alarm (ring+vibrate)
          await ensureAlarm().start();

          // show a SILENT tray only if text present (visual cue)
          if (msg.hasExplicitText) {
            await _showLocalNotification(
              title: msg.title ?? '',
              body: msg.body ?? '',
              data: msg.data,
              channelId: AppMessages.silentChannelId,
              channelName: AppMessages.silentChannelName,
              iosPlaySound: false,
            );
          }

          // small delay so overlay context is ready
          await Future.delayed(const Duration(milliseconds: 150));

          await ui.showSilenceAlarmDialog(
            title: msg.title ?? AppMessages.dialogTitleFallback,
            body:  msg.body  ?? AppMessages.dialogContentFallback,
            alertId: msg.alertId > 0 ? msg.alertId : null,
          );
        }
      } else {
        // Logged out or resolved: show LOUD tray if there is text
        if (msg.hasExplicitText) {
          await _showLocalNotification(
            title: msg.title ?? '',
            body: msg.body ?? '',
            data: msg.data,
            channelId: AppMessages.loudChannelId,
            channelName: AppMessages.loudChannelName,
            iosPlaySound: true,
          );
        }
      }
    });

    // 6) Tapped from background
    FirebaseMessaging.onMessageOpenedApp.listen(
      (RemoteMessage rm) => _routeFromPayload(rm.data, armAfterRoute: true),
    );

    // 7) Launched from terminated
    final initial = await _fcm.getInitialMessage();
    if (initial != null) {
      _routeFromPayload(initial.data, armAfterRoute: true);
    }
  }

  // -------- public helpers
  static Future<bool> ensureRegisteredNow() async {
    final t = await _fcm.getToken();
    if (t == null || t.isEmpty) return false;
    return _registerDeviceToken(t);
  }

  static Future<void> registerAfterAuth() async {
    final t = await _fcm.getToken();
    if (t == null || t.isEmpty) return;
    await _registerDeviceToken(t);
  }

  static Future<void> stopAlarmExternally() => ensureAlarm().stop();

  // -------- internals
  static Map<String, String> _authHeaders() {
    final box = GetStorage();
    final token = box.read<String>('access');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Future<bool> _registerDeviceToken(String token) async {
    final uri = Uri.parse('${Api.baseUrl}/api/fcm/devices/');
    final body = jsonEncode({
      'registration_token': token,
      'device_name': 'FireAlarm-${DateTime.now().millisecondsSinceEpoch}',
      'device_type': 'android',
      'active': true,
    });

    try {
      final res = await _http.post(uri, headers: _authHeaders(), body: body);
      if (res.statusCode == 200 || res.statusCode == 201) return true;

      if (res.statusCode == 400 || res.statusCode == 409) {
        final put = await _http.put(uri, headers: _authHeaders(), body: body);
        return put.statusCode >= 200 && put.statusCode < 300;
      }
    } catch (e) {
      debugPrint('⚠️ registerDeviceToken error: $e');
    }
    return false;
  }

  /// Use requested channel (silent/loud). Channel controls sound on Android 8+.
  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    required Map<String, dynamic> data,
    required String channelId,
    required String channelName,
    required bool iosPlaySound,
  }) async {
    final payload = jsonEncode(data);

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: 'Fire/smoke alerts',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: iosPlaySound,
    );

    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _local.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  static bool _isLoggedIn() {
    final box = GetStorage();
    final token = box.read<String>('access');
    return token != null && token.isNotEmpty;
  }

  /// Navigate based on payload; optionally arm after route (for tap cases).
  static void _routeFromPayload(
    Map<String, dynamic> data, {
    bool armAfterRoute = false,
  }) async {
    final msg = FirebaseMessage.fromMap(data);

    if (_isLoggedIn()) {
      // Navigate where you want:
      if (msg.data['device_id'] != null) {
        Get.toNamed(
          '/device_alerts',
          arguments: {'device_id': msg.data['device_id'].toString()},
        );
      } else {
        // Fallback route (adjust to your actual alerts page route)
        Get.toNamed('/alerts');
      }

      if (armAfterRoute) {
        await Future.delayed(const Duration(milliseconds: 150));

        if (msg.isActive) {
          final ackKey = _ackKeyFor(msg);
          if (_ackDialogShown.add(ackKey)) {
            // Start alarm + show Acknowledge dialog once
            await ensureAlarm().start();
            await ui.showSilenceAlarmDialog(
              title: msg.title ?? AppMessages.dialogTitleFallback,
              body:  msg.body  ?? AppMessages.dialogContentFallback,
              alertId: msg.alertId > 0 ? msg.alertId : null,
            );
          }
        }
      }
    } else {
      Get.offAllNamed('/login');
    }
  }
}

// ================== BACKGROUND HANDLER (same file) ==================

final FlutterLocalNotificationsPlugin _bgLocal = FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final data = message.data;

  // If "notification" payload exists, Android already shows a system notif.
  // Skip ours unless explicitly forced via data flag (force_local=1).
  final forceLocal = (data['force_local'] ?? '0').toString() == '1';
  if (message.notification != null && !forceLocal) {
    return;
  }

  // Minimal init for background isolate
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosInit = DarwinInitializationSettings();
  const init = InitializationSettings(android: androidInit, iOS: iosInit);
  await _bgLocal.initialize(init);

  // Loud (must match foreground + Manifest)
  final androidDetails = AndroidNotificationDetails(
    AppMessages.loudChannelId,
    AppMessages.loudChannelName,
    channelDescription: 'Unresolved fire alerts',
    importance: Importance.max,
    priority: Priority.max,
    playSound: true,
    sound: const RawResourceAndroidNotificationSound('fire_alarm'),
    fullScreenIntent: true,
    visibility: NotificationVisibility.public,
    category: AndroidNotificationCategory.alarm,
    enableVibration: true,
  );

  final notif = NotificationDetails(
    android: androidDetails,
    iOS: const DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: true,
    ),
  );

  // Use data-only text; if missing, pass a single space to avoid fallback strings,
  // while still allowing the loud channel to play the siren.
  final String? rawTitle = (data['title'] as String?)?.trim();
  final String? rawBody  = (data['body']  as String?)?.trim();
  final String safeTitle = (rawTitle != null && rawTitle.isNotEmpty) ? rawTitle : ' ';
  final String safeBody  = (rawBody  != null && rawBody .isNotEmpty) ? rawBody  : ' ';

  await _bgLocal.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    safeTitle,
    safeBody,
    notif,
    payload: jsonEncode(data),
  );
}
