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
    debugPrint('[AlarmService] onInit called.');
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
          options: {AVAudioSessionOptions.mixWithOthers},
        ),
      ),
    );
  }

  //*--- 🔹 Start the alarm sound + vibration ----*/
  Future<void> start() async {
    debugPrint(
        '[AlarmService] start() called. isActive=$_active, _starting=$_starting, _stopping=$_stopping');
    if (_active.value || _starting) {
      debugPrint(
          '[AlarmService] start() aborted. Already active or starting in progress.');
      return;
    }
    _starting = true;
    try {
      try {
        await _player.stop();
      } catch (_) {
        debugPrint('[AlarmService] start() _player.stop() threw but ignored.');
      }
      await _player.setReleaseMode(ReleaseMode.loop);
      debugPrint('[AlarmService] Playing fire_alarm.mp3 in loop.');
      await _player.play(AssetSource('sounds/fire_alarm.mp3'));

      try {
        if (await Vibration.hasVibrator()) {
          debugPrint('[AlarmService] Starting vibration pattern.');
          Vibration.vibrate(
            pattern: [0, 800, 400, 800, 400, 800],
            intensities: [128, 255, 128, 255, 128, 255],
            repeat: 0,
          );
        } else {
          debugPrint('[AlarmService] Device has no vibrator.');
        }
      } catch (e) {
        debugPrint('[AlarmService] Vibration error: $e');
      }

      _active.value = true;
      debugPrint('[AlarmService] Alarm marked as active.');
    } finally {
      _starting = false;
      debugPrint('[AlarmService] start() finished.');
    }
  }

  //*--- 🔹 Stop the alarm sound + vibration ----*/
  Future<void> stop() async {
    debugPrint(
        '[AlarmService] stop() called. isActive=$_active, _stopping=$_stopping');
    if (!_active.value || _stopping) {
      debugPrint(
          '[AlarmService] stop() aborted. Not active or already stopping.');
      return;
    }
    _stopping = true;
    try {
      try {
        await _player.stop();
        debugPrint('[AlarmService] Audio player stopped.');
      } catch (e) {
        debugPrint('[AlarmService] _player.stop() error: $e');
      }
      try {
        await Vibration.cancel();
        debugPrint('[AlarmService] Vibration cancelled.');
      } catch (e) {
        debugPrint('[AlarmService] Vibration.cancel() error: $e');
      }
      _active.value = false;
      debugPrint('[AlarmService] Alarm marked as inactive.');
    } finally {
      _stopping = false;
      debugPrint('[AlarmService] stop() finished.');
    }
  }
}

// Ensure there’s a single, app-wide AlarmService instance.
AlarmService ensureAlarm() {
  if (!Get.isRegistered<AlarmService>()) {
    debugPrint('[AlarmService] Not registered → putting new AlarmService.');
    Get.put(AlarmService(), permanent: true);
  } else {
    debugPrint('[AlarmService] Already registered → returning existing.');
  }
  return Get.find<AlarmService>();
}
