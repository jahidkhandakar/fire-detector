import 'device_model.dart';

class DeviceNode {
  final DeviceModel master;
  final List<DeviceModel> slaves;

  DeviceNode({required this.master, required this.slaves});

  factory DeviceNode.fromJson(Map<String, dynamic> json) {
    final master = DeviceModel.fromJson(json);
    final rawSlaves = (json['slaves'] as List?) ?? const [];
    final slaves = rawSlaves
        .where((e) => e != null)
        .map((e) => DeviceModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return DeviceNode(master: master, slaves: slaves);
  }
}
