class AlertModel {
  final int id;
  final int device;
  final String deviceHardwareIdentifier;
  final String alertType;
  final String status;
  final DateTime triggeredAt;
  final DateTime? resolvedAt;
  final int ownerId;
  final String ownerEmail;
  final String ownerPhone;

  AlertModel({
    required this.id,
    required this.device,
    required this.deviceHardwareIdentifier,
    required this.alertType,
    required this.status,
    required this.triggeredAt,
    this.resolvedAt,
    required this.ownerId,
    required this.ownerEmail,
    required this.ownerPhone,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id'] ?? 0,
      device: json['device'] ?? 0,
      deviceHardwareIdentifier: json['device_hardware_identifier'] ?? '',
      alertType: json['alert_type'] ?? '',
      status: json['status'] ?? '',
      triggeredAt: DateTime.tryParse(json['triggered_at'] ?? '') ?? DateTime.now(),
      resolvedAt: json['resolved_at'] != null
          ? DateTime.tryParse(json['resolved_at'])
          : null,
      ownerId: json['owner_id'] ?? 0,
      ownerEmail: json['owner_email'] ?? '',
      ownerPhone: json['owner_phone'] ?? '',
    );
  }
}
