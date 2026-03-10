class PackageModel {
  final int id;
  final String name;
  final int minQuantity;
  final int maxQuantity;

  // ✅ money fields as double (your current approach)
  final double pricePerDevice;
  final double mrf;

  PackageModel({
    required this.id,
    required this.name,
    required this.minQuantity,
    required this.maxQuantity,
    required this.pricePerDevice,
    required this.mrf,
  });

  /// ✅ Standalone detection
  bool get isStandalone {
    final n = name.toLowerCase().replaceAll(' ', '').replaceAll('-', '');
    return n.contains('standalone');
  }

  /// ✅ Mesh detection (optional but handy)
  bool get isMesh {
    final n = name.toLowerCase();
    return n.contains('mesh');
  }

  /// ✅ total per device incl. mrf (handy in UI)
  double get unitTotal => pricePerDevice + mrf;

  factory PackageModel.fromJson(Map<String, dynamic> json) {
    double _toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    int _toInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    return PackageModel(
      id: _toInt(json['id']),
      name: (json['name'] ?? '').toString(),
      minQuantity: _toInt(json['min_quantity']),
      maxQuantity: _toInt(json['max_quantity']),
      pricePerDevice: _toDouble(json['price_per_device']),
      mrf: _toDouble(json['mrf']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'min_quantity': minQuantity,
        'max_quantity': maxQuantity,
        // keep these numeric (backend friendly)
        'price_per_device': pricePerDevice,
        'mrf': mrf,
      };
}
