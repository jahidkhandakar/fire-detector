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
    final ctx = Get.context;
    if (ctx == null) {
      debugPrint('⚠️ CustomSnackbar: Get.context is null, cannot show SnackBar');
      return;
    }

    final bg = _palette(type);
    final icon = _icon(type);

    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final messenger = ScaffoldMessenger.of(ctx);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: content,
          backgroundColor: bg,
          behavior: SnackBarBehavior.floating,
          duration: duration,
          margin: _marginForPosition(ctx, position),
        ),
      );
  }

  // Convenience wrappers
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
        return Icons.info;
    }
  }

  EdgeInsets _marginForPosition(BuildContext context, SnackbarPosition pos) {
    final base = const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
    final size = MediaQuery.of(context).size;

    switch (pos) {
      case SnackbarPosition.bottom:
        return base.copyWith(bottom: 16);
      case SnackbarPosition.top:
        // Push it near the top using a big bottom margin
        return EdgeInsets.fromLTRB(16, 16, 16, size.height - 120);
      case SnackbarPosition.center:
        // Rough center-ish
        return EdgeInsets.fromLTRB(
          16,
          size.height / 2 - 40,
          16,
          size.height / 2 - 40,
        );
    }
  }
}
