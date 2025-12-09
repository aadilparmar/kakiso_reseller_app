// lib/controllers/order_controller.dart
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:kakiso_reseller_app/models/order.dart';
import 'package:kakiso_reseller_app/services/api_services.dart';

class OrderController extends GetxController {
  static const String _storageKey = 'orders_v1';

  final GetStorage _box = GetStorage();

  final RxList<Order> _orders = <Order>[].obs;
  List<Order> get orders => _orders;

  @override
  void onInit() {
    super.onInit();
    _loadOrdersFromStorage();
    ever<List<Order>>(_orders, (_) => _saveOrdersToStorage());
  }

  void addOrder(Order order) {
    final existingIndex = _orders.indexWhere((o) => o.id == order.id);
    if (existingIndex >= 0) {
      _orders[existingIndex] = order;
    } else {
      _orders.insert(0, order);
    }
    _orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Order? getOrderById(String id) {
    try {
      return _orders.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Order> ordersForUser(String userId) {
    if (userId.trim().isEmpty) return _orders;
    return _orders.where((o) => o.userId == userId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void _loadOrdersFromStorage() {
    final stored = _box.read<List<dynamic>>(_storageKey);
    if (stored == null) return;

    try {
      final loaded = stored
          .map((e) => Order.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      _orders.assignAll(loaded);
      _orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      _orders.clear();
    }
  }

  void _saveOrdersToStorage() {
    try {
      final data = _orders.map((o) => o.toJson()).toList();
      _box.write(_storageKey, data);
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // Sync from WooCommerce (ALL orders for a user)
  // ---------------------------------------------------------------------------
  Future<void> syncOrdersFromWoo({required String userId}) async {
    if (userId.trim().isEmpty) return;

    try {
      final remoteOrders = await ApiService.fetchWooOrdersForCustomer(
        userId: userId,
      );

      for (final order in remoteOrders) {
        final index = _orders.indexWhere((o) => o.id == order.id);
        if (index >= 0) {
          _orders[index] = order;
        } else {
          _orders.add(order);
        }
      }

      _orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      // optional: log
    }
  }

  // ---------------------------------------------------------------------------
  // NEW: Sync just ONE order from Woo, by orderId
  // ---------------------------------------------------------------------------
  Future<void> syncSingleOrderFromWoo({required String orderId}) async {
    if (orderId.trim().isEmpty) return;

    try {
      final remote = await ApiService.fetchWooOrderById(orderId: orderId);

      final index = _orders.indexWhere((o) => o.id == remote.id);
      if (index >= 0) {
        _orders[index] = remote;
      } else {
        _orders.add(remote);
      }

      _orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      // optional: log
    }
  }
}
