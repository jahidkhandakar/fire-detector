import 'package:flutter/foundation.dart';

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
  final String paymentMethod;
  final String orderStatus;
  final String gatewayTransactionId;
  final dynamic gatewayResponse;
  final String shippingAddress;
  final int numberOfMasterDevices;
  final int numberOfSlaveDevices;
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
    required this.paymentMethod,
    required this.orderStatus,
    required this.gatewayTransactionId,
    required this.gatewayResponse,
    required this.shippingAddress,
    required this.numberOfMasterDevices,
    required this.numberOfSlaveDevices,
    required this.orderedAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    debugPrint('🧾 OrderModel.fromJson input: $json');

    // package can now be either:
    // - an int (legacy API)
    // - a map { id: ..., name: ... } (current API)
    final pkg = json['package'];
    int resolvedPackageId;

    if (pkg is int) {
      resolvedPackageId = pkg;
    } else if (pkg is Map<String, dynamic>) {
      resolvedPackageId = (pkg['id'] as num?)?.toInt() ?? 0;
      debugPrint('📦 Parsed package as object, id=$resolvedPackageId, name=${pkg['name']}');
    } else {
      debugPrint('⚠️ Unexpected package type: ${pkg.runtimeType}, value=$pkg');
      resolvedPackageId = 0; // fallback so app doesn’t crash
    }

    final orderedAtStr = json['ordered_at']?.toString();
    final parsedOrderedAt =
        orderedAtStr != null ? DateTime.tryParse(orderedAtStr) : null;

    return OrderModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      user: (json['user'] as num?)?.toInt() ?? 0,
      packageId: resolvedPackageId,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      amount: json['amount']?.toString() ?? '0.00',
      currency: json['currency']?.toString() ?? 'BDT',
      reference: json['reference']?.toString() ?? '',
      customerName: json['customer_name']?.toString() ?? '',
      customerAddress: json['customer_address']?.toString() ?? '',
      customerPhone: json['customer_phone']?.toString() ?? '',
      customerCity: json['customer_city']?.toString() ?? '',
      customerPostCode: json['customer_post_code']?.toString() ?? '',
      customerEmail: json['customer_email']?.toString() ?? '',
      paymentMethod: (json['payment_method'] ?? 'online').toString(),
      orderStatus: json['order_status']?.toString() ?? '',
      gatewayTransactionId:
          json['gateway_transaction_id']?.toString() ?? '',
      gatewayResponse: json['gateway_response'],
      shippingAddress: json['shipping_address']?.toString() ?? '',
      numberOfMasterDevices:
          (json['number_of_master_devices'] as num?)?.toInt() ?? 0,
      numberOfSlaveDevices:
          (json['number_of_slave_devices'] as num?)?.toInt() ?? 0,
      orderedAt: parsedOrderedAt ?? DateTime.now(),
    );
  }
}
