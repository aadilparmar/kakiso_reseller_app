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

  /// Add or replace an order (latest first).
  void addOrder(Order order) {
    final existingIndex = _orders.indexWhere((o) => o.id == order.id);
    if (existingIndex >= 0) {
      _orders[existingIndex] = order;
    } else {
      _orders.insert(0, order);
    }

    _orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Find order by id (used by OrderDetailsPage)
  Order? getOrderById(String id) {
    try {
      return _orders.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  /// All orders for a specific app userId
  List<Order> ordersForUser(String userId) {
    if (userId.trim().isEmpty) return _orders;
    return _orders.where((o) => o.userId == userId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // ---------------------------------------------------------------------------
  // Local persistence
  // ---------------------------------------------------------------------------

  void _loadOrdersFromStorage() {
    final stored = _box.read<List<dynamic>>(_storageKey);
    if (stored == null) return;

    try {
      // Convert dynamic to Order explicitly
      final List loaded = stored.map((e) {
        return Order.fromJson(Map<String, dynamic>.from(e));
      }).toList();

      _orders.assignAll(
        loaded as Iterable<Order>,
      ); // Now correctly typed as List<Order>
      _orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      // print('[OrderController] load error: $e\n$st');
      _orders.clear();
    }
  }

  void _saveOrdersToStorage() {
    try {
      final data = _orders.map((o) => o.toJson()).toList();
      _box.write(_storageKey, data);
    } catch (_) {
      // ignore – do not crash on storage error
    }
  }

  // ---------------------------------------------------------------------------
  // Sync ALL orders for a user from WooCommerce
  // ---------------------------------------------------------------------------
  /// Returns true on success, false on failure (useful for UI feedback)
  Future<bool> syncOrdersFromWoo({String? userId, String? userEmail}) async {
    final String rawUserId = (userId ?? '').trim();
    final String rawEmail = (userEmail ?? '').trim();

    // if (rawUserId.isEmpty && rawEmail.isEmpty) {
    //   print(
    //     '[OrderController.syncOrdersFromWoo] abort: no userId & no userEmail',
    //   );
    //   return false;
    // }

    // print(
    //   '[OrderController.syncOrdersFromWoo] START userId="$rawUserId" userEmail="$rawEmail"',
    // );

    try {
      // Call ApiService. We pass null for empty strings so the API can choose strategy
      final List<Order> remoteOrders =
          await ApiService.fetchWooOrdersForCustomer(
            userId: rawUserId.isNotEmpty ? rawUserId : null,
            userEmail: rawEmail.isNotEmpty ? rawEmail : null,
          );

      // print(
      //   '[OrderController.syncOrdersFromWoo] fetched remoteOrders count=${remoteOrders.length}',
      // );

      // if (remoteOrders.isEmpty) {
      //   // still merge nothing, but log
      //   print('[OrderController.syncOrdersFromWoo] remote returned 0 orders.');
      // }

      // Merge remote orders into local list
      for (final order in remoteOrders) {
        final index = _orders.indexWhere((o) => o.id == order.id);
        if (index >= 0) {
          _orders[index] = order;
        } else {
          _orders.add(order);
        }
      }

      _orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      // print(
      //   '[OrderController.syncOrdersFromWoo] MERGE COMPLETE. localCount=${_orders.length}',
      // );
      return true;
    } catch (e) {
      // print(
      //   '[OrderController.syncOrdersFromWoo] ERROR while syncing orders: $e\nStackTrace:\n$st',
      // );
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Sync just ONE order from Woo, by orderId (for details screen)
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
    } catch (_) {
      // optional: log
    }
  }
}
