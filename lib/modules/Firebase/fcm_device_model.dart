class FcmDeviceModel {
  final int id;
  final String registrationToken;
  final String deviceName;
  final String deviceType;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastUsedAt;

  FcmDeviceModel({
    required this.id,
    required this.registrationToken,
    required this.deviceName,
    required this.deviceType,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
    this.lastUsedAt,
  });

  factory FcmDeviceModel.fromJson(Map<String, dynamic> json) {
    return FcmDeviceModel(
      id: json['id'],
      registrationToken: json['registration_token'],
      deviceName: json['device_name'],
      deviceType: json['device_type'],
      active: json['active'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      lastUsedAt: json['last_used_at'] != null
          ? DateTime.parse(json['last_used_at'])
          : null,
    );
  }
}
