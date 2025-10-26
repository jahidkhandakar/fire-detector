class PackageModel {
  final int id;
  final String name;
  final int minQuantity;
  final int maxQuantity;
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

  factory PackageModel.fromJson(Map<String, dynamic> json) {
    double _toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    return PackageModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      minQuantity: json['min_quantity'] ?? 0,
      maxQuantity: json['max_quantity'] ?? 0,
      pricePerDevice: _toDouble(json['price_per_device']),
      mrf: _toDouble(json['mrf']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'min_quantity': minQuantity,
        'max_quantity': maxQuantity,
        'price_per_device': pricePerDevice.toStringAsFixed(2),
        'mrf': mrf.toStringAsFixed(2),
      };
}
