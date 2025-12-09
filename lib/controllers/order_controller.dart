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

    // Persist automatically whenever list changes
    ever<List<Order>>(_orders, (_) => _saveOrdersToStorage());
  }

  /// Add/replace an order (latest first).
  void addOrder(Order order) {
    final existingIndex = _orders.indexWhere((o) => o.id == order.id);
    if (existingIndex >= 0) {
      _orders[existingIndex] = order;
    } else {
      _orders.insert(0, order);
    }

    // Keep list sorted by date (newest first)
    _orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get order by id (for OrderDetailsPage)
  Order? getOrderById(String id) {
    try {
      return _orders.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  /// All orders for a specific user (used by OrdersPage)
  List<Order> ordersForUser(String userId) {
    if (userId.trim().isEmpty) return _orders;
    return _orders.where((o) => o.userId == userId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // ---------------------------------------------------------------------------
  // Persistence (local)
  // ---------------------------------------------------------------------------

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
      // If anything is corrupted, just reset
      _orders.clear();
    }
  }

  void _saveOrdersToStorage() {
    try {
      final data = _orders.map((o) => o.toJson()).toList();
      _box.write(_storageKey, data);
    } catch (_) {
      // ignore – we don't want app to crash due to storage failure
    }
  }

  // ---------------------------------------------------------------------------
  // Sync from WooCommerce (remote history)
  // ---------------------------------------------------------------------------

  /// Pull existing WooCommerce orders for this customer and merge with local.
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
      // Silent fail – we still have local orders
      // You can log if needed:
      // debugPrint('syncOrdersFromWoo error: $e');
    }
  }
}
