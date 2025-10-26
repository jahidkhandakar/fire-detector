class OrderModel {
  final int id;
  final int user;
  final int packageId;
  final int quantity;
  final String amount;
  final String currency;
  final String reference;
  final String customerName;
  final String customerAddress;
  final String customerPhone;
  final String customerCity;
  final String customerPostCode;
  final String customerEmail;
  final String orderStatus;
  final String gatewayTransactionId;
  final dynamic gatewayResponse;
  final String shippingAddress;
  final DateTime orderedAt;

  OrderModel({
    required this.id,
    required this.user,
    required this.packageId,
    required this.quantity,
    required this.amount,
    required this.currency,
    required this.reference,
    required this.customerName,
    required this.customerAddress,
    required this.customerPhone,
    required this.customerCity,
    required this.customerPostCode,
    required this.customerEmail,
    required this.orderStatus,
    required this.gatewayTransactionId,
    required this.gatewayResponse,
    required this.shippingAddress,
    required this.orderedAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'],
      user: json['user'],
      packageId: json['package'],
      quantity: json['quantity'],
      amount: json['amount'],
      currency: json['currency'],
      reference: json['reference'],
      customerName: json['customer_name'],
      customerAddress: json['customer_address'],
      customerPhone: json['customer_phone'],
      customerCity: json['customer_city'],
      customerPostCode: json['customer_post_code'],
      customerEmail: json['customer_email'],
      orderStatus: json['order_status'],
      gatewayTransactionId: json['gateway_transaction_id'] ?? '',
      gatewayResponse: json['gateway_response'],
      shippingAddress: json['shipping_address'],
      orderedAt: DateTime.parse(json['ordered_at']),
    );
  }
}
