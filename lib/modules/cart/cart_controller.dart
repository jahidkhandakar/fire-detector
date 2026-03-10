import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:fire_alarm/others/widgets/cart_dialog.dart';
import '/modules/cart/cart_model.dart';
import '/modules/cart/cart_service.dart';
import '/modules/packages/package_model.dart';
import '/others/errors/app_error_handler.dart';

class CartController extends GetxController {
  final CartService _service = CartService();

  final cart = Rxn<CartModel>();
  final isLoading = false.obs;
  final isCheckingOut = false.obs;

  /// True only while a PATCH is in-flight (network)
  final isUpdatingItem = false.obs;

  final error = ''.obs;

  // Debounce + pending state per item
  final Map<int, Timer> _debounceTimers = {};
  final Map<int, _PendingItemState> _pending = {};

  int get itemCount => cart.value?.itemCount ?? 0;

  bool get hasPendingUpdates => _pending.isNotEmpty;
  bool hasPendingForItem(int itemId) => _pending.containsKey(itemId);

  // ────────────────────────────────────────────────────────────────────────────
  // LOAD
  // ────────────────────────────────────────────────────────────────────────────
  Future<void> loadCart() async {
    try {
      isLoading.value = true;
      error.value = '';
      debugPrint('🛒 CartController.loadCart()');

      final c = await _service.fetchCart();
      cart.value = c;

      // Server is source of truth after load
      _debounceTimers.values.forEach((t) => t.cancel());
      _debounceTimers.clear();
      _pending.clear();

      debugPrint(
        '✅ Cart loaded: id=${c?.id}, items=${c?.items.length ?? 0}, total=${c?.total}',
      );
    } catch (e, st) {
      final appEx = AppException.from(e, st);
      error.value = appEx.toUserMessage();
      AppErrorHandler.handle(appEx, stackTrace: st);
    } finally {
      isLoading.value = false;
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // PACKAGE RULES
  // ────────────────────────────────────────────────────────────────────────────
  bool _isMesh(PackageModel pkg) => pkg.name.toLowerCase().contains('mesh');

  bool _isStandalone(PackageModel pkg) =>
      pkg.name.toLowerCase().contains('stand') || pkg.isStandalone;

  int _minQtyFor(PackageModel pkg) {
    if (_isMesh(pkg)) return 2; // 1 master + 1 slave
    return 1; // standalone min 1 master
  }

  /// Normalizes masters/slaves to obey package rules.
  /// - Standalone: slaves=0, masters=qty
  /// - Mesh: masters>=1, slaves>=1, qty>=2
  _MSQ _normalizeFromMastersSlaves({
    required PackageModel pkg,
    required int desiredMasters,
    required int desiredSlaves,
  }) {
    final isMesh = _isMesh(pkg);
    final isStandalone = _isStandalone(pkg);

    int masters = desiredMasters;
    int slaves = desiredSlaves;

    // prevent negative
    if (masters < 0) masters = 0;
    if (slaves < 0) slaves = 0;

    if (isStandalone) {
      // Standalone: all are masters
      final qty = masters <= 0 ? 1 : masters;
      return _MSQ(masters: qty, slaves: 0, qty: qty);
    }

    if (isMesh) {
      // Mesh: need >=1 master and >=1 slave
      if (masters < 1) masters = 1;
      if (slaves < 1) slaves = 1;

      int qty = masters + slaves;
      if (qty < _minQtyFor(pkg)) {
        // force min 2 by bumping slaves (or masters)
        qty = _minQtyFor(pkg);
        masters = 1;
        slaves = qty - masters; // => 1
      }

      return _MSQ(masters: masters, slaves: slaves, qty: qty);
    }

    // fallback: treat as (masters+slaves) with at least min
    int qty = masters + slaves;
    if (qty < _minQtyFor(pkg)) qty = _minQtyFor(pkg);

    // if qty increased but we have 0 items, make them masters
    if (masters + slaves == 0) {
      masters = qty;
      slaves = 0;
    }

    return _MSQ(masters: masters, slaves: slaves, qty: qty);
  }

  // ────────────────────────────────────────────────────────────────────────────
  // PRICE HELPERS (POS BILL)
  // ────────────────────────────────────────────────────────────────────────────
  double unitDevicePrice(PackageModel pkg) => pkg.pricePerDevice;
  double unitMrf(PackageModel pkg) => pkg.mrf;

  /// devices subtotal = pricePerDevice * qty
  double devicesSubtotal(PackageModel pkg, int qty) =>
      unitDevicePrice(pkg) * qty;

  /// mrf subtotal = mrf * qty
  double mrfSubtotal(PackageModel pkg, int qty) => unitMrf(pkg) * qty;

  /// total = (pricePerDevice + mrf) * qty
  double grandTotal(PackageModel pkg, int qty) =>
      (unitDevicePrice(pkg) + unitMrf(pkg)) * qty;

  /// Convenience: build “paper bill” lines
  CartBillBreakdown billForItem(CartItemModel item) {
    final pkg = item.pkg;
    final masters = item.numberOfMasterDevices;
    final slaves = item.numberOfSlaveDevices;
    final qty = item.quantity;

    final price = unitDevicePrice(pkg);
    final mrf = unitMrf(pkg);

    return CartBillBreakdown(
      mastersQty: masters,
      mastersUnit: price,
      mastersTotal: price * masters,
      slavesQty: slaves,
      slavesUnit: price,
      slavesTotal: price * slaves,
      mrfQty: qty,
      mrfUnit: mrf,
      mrfTotal: mrf * qty,
      grandTotal: (price + mrf) * qty,
    );
  }

  String _calcLineTotal(PackageModel pkg, int qty) {
    final total = grandTotal(pkg, qty);
    return total.toStringAsFixed(2);
  }

  CartModel _recomputeCartTotals(CartModel c, List<CartItemModel> items) {
    double total = 0;
    int count = 0;

    for (final it in items) {
      total += it.lineTotalAsDouble;
      count += it.quantity;
    }

    final newCart = CartModel(
      id: c.id,
      items: items,
      total: total.toStringAsFixed(2),
      itemCount: count,
      expiresAt: c.expiresAt,
      isExpired: c.isExpired,
      createdAt: c.createdAt,
      updatedAt: DateTime.now(),
    );

    debugPrint(
      '📦 _recomputeCartTotals => items=${items.length}, itemCount=$count, total=${newCart.total}',
    );

    return newCart;
  }

  // ────────────────────────────────────────────────────────────────────────────
  // BLOCK “2 PACKAGES” RULE
  // ────────────────────────────────────────────────────────────────────────────
  bool _hasDifferentPackageInCart(int newPackageId) {
    final c = cart.value;
    if (c == null || c.items.isEmpty) return false;

    final existingPkgId = c.items.first.pkg.id;
    return existingPkgId != newPackageId;
  }

  // ────────────────────────────────────────────────────────────────────────────
  // ADD
  // ────────────────────────────────────────────────────────────────────────────
  Future<void> addPackageToCart({
    required PackageModel pkg,
    required int masters,
    required int slaves,
  }) async {
    final quantity = masters + slaves;
    if (quantity <= 0) {
      error.value = 'Quantity must be greater than 0.';
      return;
    }

    debugPrint(
      '🛒 addPackageToCart pkg=${pkg.id} masters=$masters slaves=$slaves qty=$quantity',
    );

    // Block adding different package (show dialog)
    if (_hasDifferentPackageInCart(pkg.id)) {
      debugPrint('🚫 Different package detected → show clear-cart dialog');
      await showClearCartDialog(onClearCart: clearCart);
      return;
    }

    try {
      error.value = '';

      final norm = _normalizeFromMastersSlaves(
        pkg: pkg,
        desiredMasters: masters,
        desiredSlaves: slaves,
      );

      await _service.addItem(
        packageId: pkg.id,
        quantity: norm.qty,
        masters: norm.masters,
        slaves: norm.slaves,
      );

      await loadCart();
    } catch (e, st) {
      final appEx = AppException.from(e, st);
      error.value = appEx.toUserMessage();
      AppErrorHandler.handle(appEx, stackTrace: st);
      rethrow;
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // LOCAL UPDATE API (Masters/Slaves separately)
  // ────────────────────────────────────────────────────────────────────────────

  /// Use these from UI:
  /// - changeMastersLocal(item, +1/-1)
  /// - changeSlavesLocal(item, +1/-1)
  void changeMastersLocal(CartItemModel item, int delta) {
    setMastersLocal(item, item.numberOfMasterDevices + delta);
  }

  void changeSlavesLocal(CartItemModel item, int delta) {
    setSlavesLocal(item, item.numberOfSlaveDevices + delta);
  }

  void setMastersLocal(CartItemModel item, int desiredMasters) {
    final pkg = item.pkg;

    // Standalone => slaves always 0
    final desiredSlaves = _isStandalone(pkg) ? 0 : item.numberOfSlaveDevices;

    final norm = _normalizeFromMastersSlaves(
      pkg: pkg,
      desiredMasters: desiredMasters,
      desiredSlaves: desiredSlaves,
    );

    _applyLocalAndDebouncePatch(
      item: item,
      masters: norm.masters,
      slaves: norm.slaves,
      qty: norm.qty,
      reason: 'setMastersLocal',
    );
  }

  void setSlavesLocal(CartItemModel item, int desiredSlaves) {
    final pkg = item.pkg;

    // Standalone => ignore slave changes
    if (_isStandalone(pkg)) {
      debugPrint('🚫 setSlavesLocal ignored for standalone item=${item.id}');
      return;
    }

    final norm = _normalizeFromMastersSlaves(
      pkg: pkg,
      desiredMasters: item.numberOfMasterDevices,
      desiredSlaves: desiredSlaves,
    );

    _applyLocalAndDebouncePatch(
      item: item,
      masters: norm.masters,
      slaves: norm.slaves,
      qty: norm.qty,
      reason: 'setSlavesLocal',
    );
  }

  // Keep old quantity methods if you still use them somewhere
  void changeItemQuantityLocal(CartItemModel item, int delta) {
    final targetQty = item.quantity + delta;

    // When changing total qty, preserve masters if possible
    // but still keep mesh constraints (>=1,>=1) and standalone rules.
    final pkg = item.pkg;

    if (_isStandalone(pkg)) {
      // qty === masters
      setMastersLocal(item, targetQty);
      return;
    }

    // mesh (or other): distribute based on current masters
    int desiredMasters = item.numberOfMasterDevices;
    int desiredSlaves = targetQty - desiredMasters;

    final norm = _normalizeFromMastersSlaves(
      pkg: pkg,
      desiredMasters: desiredMasters,
      desiredSlaves: desiredSlaves,
    );

    _applyLocalAndDebouncePatch(
      item: item,
      masters: norm.masters,
      slaves: norm.slaves,
      qty: norm.qty,
      reason: 'changeItemQuantityLocal',
    );
  }

  void _applyLocalAndDebouncePatch({
    required CartItemModel item,
    required int masters,
    required int slaves,
    required int qty,
    required String reason,
  }) {
    final currentCart = cart.value;
    if (currentCart == null) {
      debugPrint('⚠️ $reason: cart is null, ignoring');
      return;
    }

    debugPrint(
      '🧮 $reason item=${item.id} => m=$masters s=$slaves qty=$qty',
    );

    final items = List<CartItemModel>.from(currentCart.items);
    final idx = items.indexWhere((it) => it.id == item.id);

    if (idx == -1) {
      debugPrint('⚠️ $reason: item not found locally, reloading...');
      loadCart();
      return;
    }

    final newLineTotal = _calcLineTotal(item.pkg, qty);

    items[idx] = CartItemModel(
      id: item.id,
      pkg: item.pkg,
      quantity: qty,
      numberOfMasterDevices: masters,
      numberOfSlaveDevices: slaves,
      lineTotal: newLineTotal,
      addedAt: item.addedAt,
      updatedAt: DateTime.now(),
    );

    cart.value = _recomputeCartTotals(currentCart, items);

    // save pending (final patch state)
    _pending[item.id] = _PendingItemState(
      itemId: item.id,
      quantity: qty,
      masters: masters,
      slaves: slaves,
    );

    // debounce PATCH
    _debounceTimers[item.id]?.cancel();
    _debounceTimers[item.id] = Timer(
      const Duration(milliseconds: 700),
      () async => _sendPendingPatch(item.id),
    );

    debugPrint('⏲️ Debounce scheduled PATCH for item=${item.id}');
  }

  Future<void> _sendPendingPatch(int itemId) async {
    final pending = _pending[itemId];
    if (pending == null) {
      debugPrint('ℹ️ _sendPendingPatch: no pending for item=$itemId');
      return;
    }

    debugPrint(
      '🌐 PATCH sending item=$itemId qty=${pending.quantity} m=${pending.masters} s=${pending.slaves}',
    );

    try {
      isUpdatingItem.value = true;
      error.value = '';

      final updatedItem = await _service.updateItem(
        itemId: itemId,
        quantity: pending.quantity,
        masters: pending.masters,
        slaves: pending.slaves,
      );

      final currentCart = cart.value;
      if (currentCart == null) {
        debugPrint('ℹ️ After PATCH, cart is null. Reloading...');
        await loadCart();
        return;
      }

      final items = List<CartItemModel>.from(currentCart.items);
      final idx = items.indexWhere((it) => it.id == itemId);
      if (idx != -1) items[idx] = updatedItem;

      cart.value = _recomputeCartTotals(currentCart, items);

      debugPrint('✅ PATCH success item=$itemId serverQty=${updatedItem.quantity}');

      _pending.remove(itemId);
      _debounceTimers.remove(itemId)?.cancel();
    } catch (e, st) {
      final appEx = AppException.from(e, st);
      error.value = appEx.toUserMessage();
      AppErrorHandler.handle(appEx, stackTrace: st);
      debugPrint('❌ PATCH failed item=$itemId error=${error.value}');
      // keep pending (user can retry / checkout will flush)
    } finally {
      isUpdatingItem.value = false;
    }
  }

  /// Call before checkout to ensure backend gets final patch
  Future<void> flushPendingUpdates() async {
    debugPrint('🧼 flushPendingUpdates() pending=${_pending.length}');
    final ids = _pending.keys.toList();
    for (final id in ids) {
      _debounceTimers.remove(id)?.cancel();
      await _sendPendingPatch(id);
    }
    debugPrint('🧼 flushPendingUpdates() done pending=${_pending.length}');
  }

  // ────────────────────────────────────────────────────────────────────────────
  // REMOVE / CLEAR
  // ────────────────────────────────────────────────────────────────────────────
  Future<void> removeItem(int itemId) async {
    debugPrint('🛒 removeItem itemId=$itemId');
    try {
      error.value = '';

      _debounceTimers.remove(itemId)?.cancel();
      _pending.remove(itemId);

      await _service.removeItem(itemId);

      final currentCart = cart.value;
      if (currentCart == null) {
        debugPrint('ℹ️ Cart was null in removeItem, reloading...');
        await loadCart();
        return;
      }

      final items = List<CartItemModel>.from(currentCart.items)
        ..removeWhere((it) => it.id == itemId);

      if (items.isEmpty) {
        cart.value = CartModel(
          id: currentCart.id,
          items: [],
          total: '0.00',
          itemCount: 0,
          expiresAt: currentCart.expiresAt,
          isExpired: currentCart.isExpired,
          createdAt: currentCart.createdAt,
          updatedAt: DateTime.now(),
        );
        debugPrint('🧹 Cart is now empty after removeItem.');
      } else {
        cart.value = _recomputeCartTotals(currentCart, items);
        debugPrint('🧹 Item removed; remaining items=${items.length}');
      }
    } catch (e, st) {
      final appEx = AppException.from(e, st);
      error.value = appEx.toUserMessage();
      AppErrorHandler.handle(appEx, stackTrace: st);
    }
  }

  Future<void> clearCart() async {
    debugPrint('🛒 clearCart()');
    try {
      error.value = '';

      _debounceTimers.values.forEach((t) => t.cancel());
      _debounceTimers.clear();
      _pending.clear();

      await _service.clearCart();
      cart.value = null;

      debugPrint('✅ Cart cleared locally + server.');
    } catch (e, st) {
      final appEx = AppException.from(e, st);
      error.value = appEx.toUserMessage();
      AppErrorHandler.handle(appEx, stackTrace: st);
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // CHECKOUT
  // ────────────────────────────────────────────────────────────────────────────
  Future<CartCheckoutResult?> checkout(Map<String, dynamic> payload) async {
    debugPrint('🛒 checkout() payload=$payload');

    // backend wants final PATCH first
    await flushPendingUpdates();

    try {
      isCheckingOut.value = true;
      error.value = '';

      final res = await _service.checkout(payload);

      debugPrint(
        '✅ Checkout success: orders=${res.orders.length}, message="${res.message}"',
      );

      await loadCart();
      return res;
    } catch (e, st) {
      final appEx = AppException.from(e, st);
      error.value = appEx.toUserMessage();
      AppErrorHandler.handle(appEx, stackTrace: st);
      return null;
    } finally {
      isCheckingOut.value = false;
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Small helper models
// ──────────────────────────────────────────────────────────────────────────────
class _PendingItemState {
  final int itemId;
  final int quantity;
  final int masters;
  final int slaves;

  _PendingItemState({
    required this.itemId,
    required this.quantity,
    required this.masters,
    required this.slaves,
  });
}

class _MSQ {
  final int masters;
  final int slaves;
  final int qty;

  _MSQ({required this.masters, required this.slaves, required this.qty});
}

/// Use this in UI to render “paper bill” style lines
class CartBillBreakdown {
  final int mastersQty;
  final double mastersUnit;
  final double mastersTotal;

  final int slavesQty;
  final double slavesUnit;
  final double slavesTotal;

  final int mrfQty;
  final double mrfUnit;
  final double mrfTotal;

  final double grandTotal;

  CartBillBreakdown({
    required this.mastersQty,
    required this.mastersUnit,
    required this.mastersTotal,
    required this.slavesQty,
    required this.slavesUnit,
    required this.slavesTotal,
    required this.mrfQty,
    required this.mrfUnit,
    required this.mrfTotal,
    required this.grandTotal,
  });
}
