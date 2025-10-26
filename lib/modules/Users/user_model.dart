import 'package:fire_alarm/modules/Devices/device_model.dart';

class UserModel {
  final int id;
  final String email;
  final String phoneNumber;
  final String role;
  final String? fullName;
  final String? address;
  final List<DeviceModel> devices;

  UserModel({
    required this.id,
    required this.email,
    required this.phoneNumber,
    required this.role,
    this.fullName,
    this.address,
    required this.devices,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final deviceList = (json['devices'] as List<dynamic>?)
            ?.map((d) => DeviceModel.fromJson(d))
            .toList() ??
        [];

    return UserModel(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      role: json['role'] ?? '',
      fullName: json['full_name'],
      address: json['address'],
      devices: deviceList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "email": email,
      "phone_number": phoneNumber,
      "role": role,
      "full_name": fullName,
      "address": address,
      "devices": devices.map((d) => d.toJson()).toList(),
    };
  }
}
