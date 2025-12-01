class SubscriptionDevice {
  final int id;
  final String hardwareIdentifier;
  final String deviceName;
  final String deviceRole;
  final String status;

  SubscriptionDevice({
    required this.id,
    required this.hardwareIdentifier,
    required this.deviceName,
    required this.deviceRole,
    required this.status,
  });

  factory SubscriptionDevice.fromJson(Map<String, dynamic> json) {
    return SubscriptionDevice(
      id: json['id'] as int,
      hardwareIdentifier: (json['hardware_identifier'] ?? '').toString(),
      deviceName: (json['device_name'] ?? '').toString(),
      deviceRole: (json['device_role'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
    );
  }
}

class SubscriptionModel {
  final int id;
  final SubscriptionDevice device;
  final String status;
  final String monthlyAmount;
  final DateTime? billingAnchor;
  final DateTime? lastPaidThrough;
  final DateTime? nextDueAt;
  final DateTime? graceExpiresAt;
  final DateTime? adminOverrideUntil;
  final int daysRemaining;
  final bool isAccessible;

  SubscriptionModel({
    required this.id,
    required this.device,
    required this.status,
    required this.monthlyAmount,
    required this.billingAnchor,
    required this.lastPaidThrough,
    required this.nextDueAt,
    required this.graceExpiresAt,
    required this.adminOverrideUntil,
    required this.daysRemaining,
    required this.isAccessible,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
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

    return SubscriptionModel(
      id: json['id'] as int,
      device: SubscriptionDevice.fromJson(
        Map<String, dynamic>.from(json['device'] as Map),
      ),
      status: (json['status'] ?? '').toString(),
      monthlyAmount: (json['monthly_amount'] ?? '0.00').toString(),
      billingAnchor: _parseDate(json['billing_anchor']),
      lastPaidThrough: _parseDate(json['last_paid_through']),
      nextDueAt: _parseDate(json['next_due_at']),
      graceExpiresAt: _parseDate(json['grace_expires_at']),
      adminOverrideUntil: _parseDate(json['admin_override_until']),
      daysRemaining: _toInt(json['days_remaining']),
      isAccessible: json['is_accessible'] == true,
    );
  }
}
