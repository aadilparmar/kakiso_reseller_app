// lib/models/order.dart

import 'package:flutter/material.dart';

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
    required this.isPaid,
    required this.status,
  });

  // -----------------------------------------------------------
  // Convert enum to string
  // -----------------------------------------------------------
  static String _statusToString(OrderStatus s) {
    switch (s) {
      case OrderStatus.confirmed:
        return "confirmed";
      case OrderStatus.packed:
        return "packed";
      case OrderStatus.shipped:
        return "shipped";
      case OrderStatus.outForDelivery:
        return "out_for_delivery";
      case OrderStatus.delivered:
        return "delivered";
    }
  }

  // -----------------------------------------------------------
  // Convert string back to enum
  // -----------------------------------------------------------
  static OrderStatus _statusFromString(String s) {
    switch (s) {
      case "confirmed":
        return OrderStatus.confirmed;
      case "packed":
        return OrderStatus.packed;
      case "shipped":
        return OrderStatus.shipped;
      case "out_for_delivery":
        return OrderStatus.outForDelivery;
      case "delivered":
        return OrderStatus.delivered;
      default:
        return OrderStatus.confirmed;
    }
  }

  // -----------------------------------------------------------
  // Convert Order to JSON (for GetStorage saving)
  // -----------------------------------------------------------
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "paymentId": paymentId,
      "amount": amount,
      "createdAt": createdAt.toIso8601String(),
      "businessAddress": businessAddress,
      "customerAddress": customerAddress,
      "userId": userId,
      "userEmail": userEmail,
      "userName": userName,
      "isPaid": isPaid,
      "status": _statusToString(status),
    };
  }

  // -----------------------------------------------------------
  // Convert JSON back to Order
  // -----------------------------------------------------------
  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json["id"]?.toString() ?? "",
      paymentId: json["paymentId"]?.toString() ?? "",
      amount: (json["amount"] is num)
          ? (json["amount"] as num).toDouble()
          : double.tryParse(json["amount"].toString()) ?? 0.0,
      createdAt: DateTime.tryParse(json["createdAt"] ?? "") ?? DateTime.now(),
      businessAddress: json["businessAddress"]?.toString() ?? "",
      customerAddress: json["customerAddress"]?.toString() ?? "",
      userId: json["userId"]?.toString() ?? "",
      userEmail: json["userEmail"]?.toString() ?? "",
      userName: json["userName"]?.toString() ?? "",
      isPaid: json["isPaid"] == true,
      status: _statusFromString(json["status"]?.toString() ?? "confirmed"),
    );
  }
}
