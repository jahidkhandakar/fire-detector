import 'package:audioplayers/audioplayers.dart';
import 'package:get/get.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter/foundation.dart';

class AlarmService extends GetxService {
  final AudioPlayer _player = AudioPlayer();
  final RxBool _active = false.obs;
  bool _starting = false;
  bool _stopping = false;

  bool get isActive => _active.value;

  @override
  void onInit() {
    super.onInit();
    // Configure as an ALARM so it’s loud + allowed over Do Not Disturb on Android (where possible)
    AudioPlayer.global.setAudioContext(
      AudioContext(
        android: const AudioContextAndroid(
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.alarm,
          audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          isSpeakerphoneOn: true,
          stayAwake: true,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          // mix so we don't kill other audio sessions instantly
          options: {AVAudioSessionOptions.mixWithOthers},
        ),
      ),
    );
  }
  //*--- 🔹 Start the alarm sound + vibration ----*/
  Future<void> start() async {
    if (_active.value || _starting) return;
    _starting = true;
    try {
      try { await _player.stop(); } catch (_) {}
      await _player.setReleaseMode(ReleaseMode.loop);
      // keep your asset path the same as your pubspec.yaml
      await _player.play(AssetSource('sounds/fire_alarm.mp3'));

      try {
        if (await Vibration.hasVibrator()) {
          Vibration.vibrate(
            pattern: [0, 800, 400, 800, 400, 800],
            intensities: [128, 255, 128, 255, 128, 255],
            repeat: 0,
          );
        }
      } catch (e) {
        if (kDebugMode) debugPrint('Vibration error: $e');
      }

      _active.value = true;
    } finally {
      _starting = false;
    }
  }
  //*--- 🔹 Stop the alarm sound + vibration ----*/
  Future<void> stop() async {
    if (!_active.value || _stopping) return;
    _stopping = true;
    try {
      try { await _player.stop(); } catch (_) {}
      try { await Vibration.cancel(); } catch (_) {}
      _active.value = false;
    } finally {
      _stopping = false;
    }
  }
}

// Ensure there’s a single, app-wide AlarmService instance.
AlarmService ensureAlarm() {
  if (!Get.isRegistered<AlarmService>()) {
    Get.put(AlarmService(), permanent: true);
  }
  return Get.find<AlarmService>();
}
