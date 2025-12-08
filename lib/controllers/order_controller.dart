// lib/controllers/order_controller.dart
import 'package:get/get.dart';
import 'package:kakiso_reseller_app/models/order.dart';

class OrderController extends GetxController {
  final RxList<Order> _orders = <Order>[].obs;

  List<Order> get orders => _orders;

  void addOrder(Order order) {
    _orders.insert(0, order); // latest first
  }

  Order? getOrderById(String id) {
    try {
      return _orders.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }
}
