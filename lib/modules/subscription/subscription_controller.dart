import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '/others/errors/app_error_handler.dart';
import 'subscription_model.dart';
import 'subscription_charge_model.dart';
import 'subscription_service.dart';
import 'subscription_topup_model.dart';

class SubscriptionController extends GetxController {
  final SubscriptionService _service = SubscriptionService();

  var subscriptions = <SubscriptionModel>[].obs;
  var isLoading = false.obs;
  var error = ''.obs;

  // optional cache for charges
  var chargesBySubscription = <int, List<SubscriptionChargeModel>>{}.obs;

  //_____________________Load all subscriptions_____________________//
  Future<void> loadSubscriptions() async {
    try {
      isLoading.value = true;
      error.value = '';
      debugPrint('🔄 Loading subscriptions for current user');

      subscriptions.value = await _service.fetchSubscriptions();
      debugPrint('✅ Loaded ${subscriptions.length} subscriptions');
    } catch (e, st) {
      debugPrint('❌ loadSubscriptions error: $e\n$st');
      final appEx = AppException.from(e, st);
      error.value = appEx.toUserMessage();
      AppErrorHandler.handle(appEx, stackTrace: st);
    } finally {
      isLoading.value = false;
    }
  }

  //_____________________Load single subscription_____________________//
  Future<SubscriptionModel?> loadSubscriptionDetail(int subscriptionId) async {
    try {
      error.value = '';
      debugPrint('🔄 Loading subscription detail for id=$subscriptionId');
      final s = await _service.fetchSubscriptionDetail(subscriptionId);
      return s;
    } catch (e, st) {
      debugPrint('❌ loadSubscriptionDetail error: $e\n$st');
      final appEx = AppException.from(e, st);
      error.value = appEx.toUserMessage();
      AppErrorHandler.handle(appEx, stackTrace: st);
      return null;
    }
  }

  //_____________________Load charges for subscription_____________________//
  Future<List<SubscriptionChargeModel>> loadCharges(int subscriptionId) async {
    try {
      error.value = '';
      debugPrint('🔄 Loading charges for subscription id=$subscriptionId');

      final list = await _service.fetchCharges(subscriptionId);
      chargesBySubscription[subscriptionId] = list;
      return list;
    } catch (e, st) {
      debugPrint('❌ loadCharges error: $e\n$st');
      final appEx = AppException.from(e, st);
      error.value = appEx.toUserMessage();
      AppErrorHandler.handle(appEx, stackTrace: st);
      return [];
    }
  }

  //_____________________Topup subscription (create charge + checkout)_____________________//
  Future<SubscriptionTopupResult?> topupSubscription({
    required int subscriptionId,
    required int months,
  }) async {
    try {
      error.value = '';
      debugPrint(
        '🔄 Topup subscription id=$subscriptionId for months=$months',
      );
      final res = await _service.topupSubscription(
        subscriptionId: subscriptionId,
        months: months,
      );
      return res;
    } catch (e, st) {
      debugPrint('❌ topupSubscription error: $e\n$st');
      final appEx = AppException.from(e, st);
      error.value = appEx.toUserMessage();
      AppErrorHandler.handle(appEx, stackTrace: st);
      return null;
    }
  }
}
