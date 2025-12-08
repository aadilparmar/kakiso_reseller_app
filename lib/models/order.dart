// lib/models/order.dart
enum OrderStatus { confirmed, packed, shipped, outForDelivery, delivered }

class Order {
  final String id;
  final String paymentId;
  final double amount;
  final DateTime createdAt;

  final String businessAddress;
  final String customerAddress;
  final String userId;
  final String userEmail;
  final String userName;

  final bool isPaid;
  final OrderStatus status;

  Order({
    required this.id,
    required this.paymentId,
    required this.amount,
    required this.createdAt,
    required this.businessAddress,
    required this.customerAddress,
    required this.userId,
    required this.userEmail,
    required this.userName,
    this.isPaid = true,
    this.status = OrderStatus.confirmed,
  });
}
