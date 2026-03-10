import '/modules/packages/package_model.dart';
import '/modules/orders/order_model.dart';

class CartItemModel {
  final int id;
  final PackageModel pkg;
  final int quantity;
  final int numberOfMasterDevices;
  final int numberOfSlaveDevices;
  final String lineTotal;
  final DateTime? addedAt;
  final DateTime? updatedAt;

  CartItemModel({
    required this.id,
    required this.pkg,
    required this.quantity,
    required this.numberOfMasterDevices,
    required this.numberOfSlaveDevices,
    required this.lineTotal,
    required this.addedAt,
    required this.updatedAt,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    DateTime? _tryParse(dynamic v) {
      if (v == null) return null;
      final s = v.toString();
      if (s.isEmpty) return null;
      try {
        return DateTime.parse(s);
      } catch (_) {
        return null;
      }
    }

    final pkgJson = (json['package'] ?? {}) as Map<String, dynamic>;

    return CartItemModel(
      id: json['id'] ?? 0,
      pkg: PackageModel.fromJson(pkgJson),
      quantity: json['quantity'] ?? 0,
      numberOfMasterDevices: json['number_of_master_devices'] ?? 0,
      numberOfSlaveDevices: json['number_of_slave_devices'] ?? 0,
      lineTotal: (json['line_total'] ?? '0').toString(),
      addedAt: _tryParse(json['added_at']),
      updatedAt: _tryParse(json['updated_at']),
    );
  }

  double get lineTotalAsDouble => double.tryParse(lineTotal) ?? 0.0;
}

class CartModel {
  final int id;
  final List<CartItemModel> items;
  final String total;
  final int itemCount;
  final DateTime? expiresAt;
  final bool isExpired;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CartModel({
    required this.id,
    required this.items,
    required this.total,
    required this.itemCount,
    required this.expiresAt,
    required this.isExpired,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CartModel.fromJson(Map<String, dynamic> json) {
    DateTime? _tryParse(dynamic v) {
      if (v == null) return null;
      final s = v.toString();
      if (s.isEmpty) return null;
      try {
        return DateTime.parse(s);
      } catch (_) {
        return null;
      }
    }

    final itemsJson = (json['items'] as List?) ?? [];

    return CartModel(
      id: json['id'] ?? 0,
      items: itemsJson
          .whereType<Map<String, dynamic>>()
          .map((e) => CartItemModel.fromJson(e))
          .toList(),
      total: (json['total'] ?? '0').toString(),
      itemCount: json['item_count'] ?? itemsJson.length,
      expiresAt: _tryParse(json['expires_at']),
      isExpired: json['is_expired'] ?? false,
      createdAt: _tryParse(json['created_at']),
      updatedAt: _tryParse(json['updated_at']),
    );
  }

  double get totalAsDouble => double.tryParse(total) ?? 0.0;
}

class CartCheckoutResult {
  final List<OrderModel> orders;
  final String message;

  CartCheckoutResult({
    required this.orders,
    required this.message,
  });
}
