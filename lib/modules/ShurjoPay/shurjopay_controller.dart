import 'package:get/get.dart';
import 'shurjopay_models.dart';
import 'shurjopay_service.dart';
import '/others/errors/app_error_handler.dart';

class ShurjoPayController extends GetxController {
  final ShurjoPayService _service = ShurjoPayService();

  final isProcessing = false.obs;
  final error = ''.obs;

  //*______________ Start payment ______________*//
  Future<ShurjoInitiateResponse?> startPayment(
    Map<String, dynamic> payload,
  ) async {
    try {
      isProcessing.value = true;
      error.value = '';
      final res = await _service.initiate(payload);
      return res;
    } catch (e, st) {
      final appEx = AppException.from(e, st);
      error.value = appEx.toUserMessage();
      AppErrorHandler.handle(appEx, stackTrace: st);
      return null;
    } finally {
      isProcessing.value = false;
    }
  }

  //*______________ Verify payment (authoritative) ______________*//
  Future<ShurjoVerifyResponse?> verifyPayment(String orderId) async {
    try {
      error.value = '';
      final res = await _service.verify(orderId);
      return res;
    } catch (e, st) {
      final appEx = AppException.from(e, st);
      error.value = appEx.toUserMessage();
      AppErrorHandler.handle(appEx, stackTrace: st);
      return null;
    }
  }

  //*______________ Handle Return (browser redirect) ______________*//
  /// Calls GET /shurjopay/return/?order_id=... on your server.
  /// Returns a ShurjoVerifyResponse built from the embedded `details`.
  Future<ShurjoVerifyResponse?> returnPayment(String orderId) async {
    try {
      error.value = '';
      final res = await _service.returnUrl(orderId);
      return res; // may be null if details missing
    } catch (e, st) {
      final appEx = AppException.from(e, st);
      error.value = appEx.toUserMessage();
      AppErrorHandler.handle(appEx, stackTrace: st);
      return null;
    }
  }

  //*______________ Handle Cancel (browser redirect) ______________*//
  /// Calls GET /shurjopay/cancel/?order_id=...
  /// Returns true on success, false on error.
  Future<bool> cancelPayment(String orderId) async {
    try {
      error.value = '';
      return await _service.cancel(orderId);
    } catch (e, st) {
      final appEx = AppException.from(e, st);
      error.value = appEx.toUserMessage();
      AppErrorHandler.handle(appEx, stackTrace: st);
      return false;
    }
  }

  //*______________ Status by transaction_id (optional) ______________*//
  /// Calls GET /shurjopay/status/?transaction_id=...
  /// Returns a raw Map (matches your sample), or null on error.
  Future<Map<String, dynamic>?> paymentStatus(int transactionId) async {
    try {
      error.value = '';
      return await _service.status(transactionId);
    } catch (e, st) {
      final appEx = AppException.from(e, st);
      error.value = appEx.toUserMessage();
      AppErrorHandler.handle(appEx, stackTrace: st);
      return null;
    }
  }
}
