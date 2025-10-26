class ShurjoInitiateResponse {
  final int? transactionId;
  final String checkoutUrl;
  final String spOrderId;
  final String? customerOrderId;

  ShurjoInitiateResponse({
    required this.transactionId,
    required this.checkoutUrl,
    required this.spOrderId,
    required this.customerOrderId,
  });

  factory ShurjoInitiateResponse.fromJson(Map<String, dynamic> json) {
    int? _toInt(dynamic v) => v == null ? null : int.tryParse(v.toString());
    return ShurjoInitiateResponse(
      transactionId: _toInt(json['transaction_id']),
      checkoutUrl: (json['checkout_url'] ?? '').toString(),
      spOrderId: (json['sp_order_id'] ?? '').toString(),
      customerOrderId: json['customer_order_id']?.toString(),
    );
  }
}


class ShurjoVerifyResponse {
  final String? spCode;
  final String? message;

  ShurjoVerifyResponse({this.spCode, this.message});

  factory ShurjoVerifyResponse.fromJson(Map<String, dynamic> json) {
    return ShurjoVerifyResponse(
      spCode: json['sp_code']?.toString(),
      message: json['message']?.toString(),
    );
  }

  bool get isSuccess => spCode == '1000';
}
