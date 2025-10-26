import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum SnackbarPosition { top, bottom, center }
enum SnackbarType { success, error, warning, info }

class CustomSnackbar {
  CustomSnackbar._();
  static final CustomSnackbar _i = CustomSnackbar._();
  factory CustomSnackbar() => _i;

  void show(
    String title,
    String message, {
    SnackbarType type = SnackbarType.info,
    SnackbarPosition position = SnackbarPosition.bottom,
    Duration duration = const Duration(seconds: 3),
  }) {
    final colors = _palette(type);
    final icon = _icon(type);

    if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();

    Get.rawSnackbar(
      titleText: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
      messageText: Text(
        message,
        style: const TextStyle(color: Colors.white, fontSize: 13),
      ),
      backgroundColor: colors,
      borderRadius: 8,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      icon: Icon(icon, color: Colors.white),
      snackPosition: _position(position),
      duration: duration,
    );
  }

  void success(String msg, {String title = 'Success'}) =>
      show(title, msg, type: SnackbarType.success);

  void error(String msg, {String title = 'Error'}) =>
      show(title, msg, type: SnackbarType.error);

  void warning(String msg, {String title = 'Warning'}) =>
      show(title, msg, type: SnackbarType.warning);

  void info(String msg, {String title = 'Info'}) =>
      show(title, msg, type: SnackbarType.info);

  // ---------- helpers ----------
  Color _palette(SnackbarType type) {
    switch (type) {
      case SnackbarType.success:
        return Colors.green.shade600;
      case SnackbarType.error:
        return Colors.red.shade600;
      case SnackbarType.warning:
        return Colors.orange.shade700;
      case SnackbarType.info:
      default:
        return Colors.blue.shade600;
    }
  }

  IconData _icon(SnackbarType type) {
    switch (type) {
      case SnackbarType.success:
        return Icons.check_circle;
      case SnackbarType.error:
        return Icons.error;
      case SnackbarType.warning:
        return Icons.warning;
      case SnackbarType.info:
      default:
        return Icons.info;
    }
  }

  SnackPosition _position(SnackbarPosition pos) {
    switch (pos) {
      case SnackbarPosition.top:
        return SnackPosition.TOP;
      case SnackbarPosition.bottom:
        return SnackPosition.BOTTOM;
      case SnackbarPosition.center:
        return SnackPosition.TOP; // GetX doesn’t have true CENTER
    }
  }
}
