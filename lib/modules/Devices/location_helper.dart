import 'package:fire_alarm/others/errors/app_error_handler.dart';
import 'package:geolocator/geolocator.dart';


class LocationHelper {
  /// Ensures permission + service ON, then returns Position.
  static Future<Position> getCurrentPosition() async {
    // 1) Check service
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw AppException(
        type: AppErrorType.unknown,
        message: 'Location services are disabled. Please enable GPS.',
      );
    }

    // 2) Check permission
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw AppException(
          type: AppErrorType.unknown,
          message: 'Location permission denied by user.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw AppException(
        type: AppErrorType.unknown,
        message:
            'Location permissions are permanently denied. Enable from Settings.',
      );
    }

    // 3) Get current position (best accuracy)
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
    } catch (e, st) {
      throw AppException.from(e, st);
    }
  }
}
