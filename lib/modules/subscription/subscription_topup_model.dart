import 'subscription_charge_model.dart';

class SubscriptionTopupResult {
  final SubscriptionChargeModel charge;
  final String checkoutUrl;
  final int transactionId;

  SubscriptionTopupResult({
    required this.charge,
    required this.checkoutUrl,
    required this.transactionId,
  });

  factory SubscriptionTopupResult.fromJson(Map<String, dynamic> json) {
    int _toInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      return int.tryParse(v.toString()) ?? 0;
    }

    return SubscriptionTopupResult(
      charge: SubscriptionChargeModel.fromJson(
        Map<String, dynamic>.from(json['charge'] as Map),
      ),
      checkoutUrl: (json['checkout_url'] ?? '').toString(),
      transactionId: _toInt(json['transaction_id']),
    );
  }
}
