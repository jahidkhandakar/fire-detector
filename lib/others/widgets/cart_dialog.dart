import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fire_alarm/others/widgets/custom_message.dart';

Future<void> showClearCartDialog({
  required Future<void> Function() onClearCart,
}) async {
  debugPrint('🧯 showClearCartDialog() opened');

  await Get.dialog(
    AlertDialog(
      title: const Text('Clear cart?'),

      // ✅ stop dialog from becoming a giant billboard
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: CustomMessage(
          message: 'You already have a package in your cart.\n\n'
              'To add a different package, please clear the cart first.',
          // optional: make it calmer for dialogs
          fontSize: 14,
          color: Colors.black87,
          fontWeight: FontWeight.w500,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          center: false,
          textAlign: TextAlign.start,
        ),
      ),

      actions: [
        TextButton(
          onPressed: () {
            debugPrint('🧯 Cancel pressed -> closing dialog');

            // ✅ closes dialog reliably
            if (Get.isDialogOpen == true) {
              Get.back(closeOverlays: true);
              return;
            }

            // ✅ fallback (in case GetX route stack is funky)
            final ctx = Get.context;
            if (ctx != null && Navigator.of(ctx).canPop()) {
              Navigator.of(ctx).pop();
            }
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            debugPrint('🧯 Clear cart pressed');

            if (Get.isDialogOpen == true) {
              Get.back(closeOverlays: true);
            }

            await onClearCart();

            Get.snackbar(
              'Cart cleared',
              'Now you can add another package.',
              snackPosition: SnackPosition.BOTTOM,
            );
          },
          child: const Text('Clear cart'),
        ),
      ],
    ),
    barrierDismissible: true,
  );
}
