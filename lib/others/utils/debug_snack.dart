import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Shows a snackbar AND mirrors the same message to the debug console.
void debugSnack(
  String title,
  String message, {
  Color? bg, // nullable to allow callers to pass null
  Color? fg, // nullable to allow callers to pass null
  Duration? duration, // allow custom duration
  SnackPosition position = SnackPosition.TOP,
}) {
  // Console mirror
  print('🔔 SNACK [$title]: $message');

  // Defaults if null provided
  final Color bgColor = bg ?? Colors.black87;
  final Color fgColor = fg ?? Colors.white;
  final Duration showFor = duration ?? const Duration(seconds: 3);

  Get.snackbar(
    title,
    message,
    snackPosition: position,
    backgroundColor: bgColor,
    colorText: fgColor,
    duration: showFor,
  );
}
