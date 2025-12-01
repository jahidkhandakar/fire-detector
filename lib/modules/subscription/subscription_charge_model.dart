class SubscriptionChargeModel {
  final int id;
  final int deviceId;
  final String deviceName;
  final String amount;
  final int cycles;
  final String status;
  final String statusDisplay;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final String providerReference;
  final bool isManual;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SubscriptionChargeModel({
    required this.id,
    required this.deviceId,
    required this.deviceName,
    required this.amount,
    required this.cycles,
    required this.status,
    required this.statusDisplay,
    required this.periodStart,
    required this.periodEnd,
    required this.providerReference,
    required this.isManual,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SubscriptionChargeModel.fromJson(Map<String, dynamic> json) {
    DateTime? _parseDate(dynamic v) {
      if (v == null) return null;
      if (v is String && v.isNotEmpty) {
        return DateTime.parse(v);
      }
      return null;
    }

    int _toInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      return int.tryParse(v.toString()) ?? 0;
    }

    return SubscriptionChargeModel(
      id: json['id'] as int,
      deviceId: _toInt(json['device_id']),
      deviceName: (json['device_name'] ?? '').toString(),
      amount: (json['amount'] ?? '0.00').toString(),
      cycles: _toInt(json['cycles']),
      status: (json['status'] ?? '').toString(),
      statusDisplay: (json['status_display'] ?? '').toString(),
      periodStart: _parseDate(json['period_start']),
      periodEnd: _parseDate(json['period_end']),
      providerReference: (json['provider_reference'] ?? '').toString(),
      isManual: json['is_manual'] == true,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }
}
