// lib/models/order.dart

enum OrderStatus { confirmed, packed, shipped, outForDelivery, delivered }

class Order {
  final String id;
  final String paymentId;
  final double amount;
  final DateTime createdAt;

  final String businessAddress;
  final String customerAddress;

  /// This should be your app's userId (we read it from Woo meta_data.app_user_id if present)
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
  // Convert enum to string (for local storage)
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
  // Convert string back to enum (from local storage)
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
  // Map WooCommerce status → local OrderStatus
  // -----------------------------------------------------------
  static OrderStatus _statusFromWooStatus(String rawStatus) {
    final s = rawStatus.toLowerCase().trim();

    // 1) Delivered / completed
    if (s == 'completed' || s.contains('delivered')) {
      return OrderStatus.delivered;
    }

    // 2) Out for delivery (various spellings)
    if (s.contains('out') && s.contains('deliver')) {
      // e.g. "out-for-delivery", "out_for_delivery", "wc-outfordelivery"
      return OrderStatus.outForDelivery;
    }

    // 3) Shipped
    if (s.contains('ship')) {
      // e.g. "shipped", "order-shipped", "wc-shipped"
      return OrderStatus.shipped;
    }

    // 4) Packed
    if (s.contains('pack')) {
      // e.g. "packed", "packing", "order-packed"
      return OrderStatus.packed;
    }

    // 5) “early” statuses = confirmed
    if (s == 'pending' ||
        s == 'processing' ||
        s == 'on-hold' ||
        s == 'confirmed' ||
        s == 'wc-confirmed') {
      return OrderStatus.confirmed;
    }

    // 6) Fallback
    return OrderStatus.confirmed;
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
  // Convert JSON back to Order (from local storage)
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

  // -----------------------------------------------------------
  // Build Order directly from WooCommerce order JSON
  // -----------------------------------------------------------
  factory Order.fromWooJson(Map<String, dynamic> json) {
    // Raw Woo fields
    final String wooId = (json['id'] ?? '').toString();
    final String wooStatus = (json['status'] ?? '').toString();
    final String wooTotal = (json['total'] ?? '0').toString();
    final String wooTransactionId = (json['transaction_id'] ?? '').toString();

    // Billing & shipping maps (safe copy to Map<String, dynamic>)
    final billing = (json['billing'] is Map)
        ? Map<String, dynamic>.from(json['billing'] as Map)
        : <String, dynamic>{};

    final shipping = (json['shipping'] is Map)
        ? Map<String, dynamic>.from(json['shipping'] as Map)
        : <String, dynamic>{};

    // Amount
    final double parsedAmount = double.tryParse(wooTotal) ?? 0.0;

    // Creation time (prefer GMT if present)
    DateTime createdAt;
    if (json['date_created_gmt'] != null) {
      createdAt =
          DateTime.tryParse(json['date_created_gmt'].toString())?.toLocal() ??
          DateTime.now();
    } else {
      createdAt =
          DateTime.tryParse(json['date_created']?.toString() ?? '') ??
          DateTime.now();
    }

    // ---------------- BUSINESS ADDRESS (billing) ----------------
    final String billingCompany = (billing['company'] ?? '').toString().trim();
    final String billingFirstName = (billing['first_name'] ?? '')
        .toString()
        .trim();
    final String billingLastName = (billing['last_name'] ?? '')
        .toString()
        .trim();
    final String billingStreet = (billing['address_1'] ?? '').toString().trim();
    final String billingCity = (billing['city'] ?? '').toString().trim();
    final String billingState = (billing['state'] ?? '').toString().trim();
    final String billingPostcode = (billing['postcode'] ?? '')
        .toString()
        .trim();
    final String billingCountry = (billing['country'] ?? '').toString().trim();

    final List<String> businessParts = [];
    if (billingCompany.isNotEmpty) businessParts.add(billingCompany);
    if (billingStreet.isNotEmpty) businessParts.add(billingStreet);
    if (billingCity.isNotEmpty) businessParts.add(billingCity);
    if (billingState.isNotEmpty) businessParts.add(billingState);
    if (billingCountry.isNotEmpty) businessParts.add(billingCountry);
    if (billingPostcode.isNotEmpty) businessParts.add(billingPostcode);

    final String businessAddress;
    if (businessParts.isNotEmpty) {
      businessAddress = businessParts.join(', ');
    } else if (billingCompany.isNotEmpty) {
      businessAddress = billingCompany;
    } else {
      businessAddress = 'Business address not available';
    }

    // ---------------- CUSTOMER ADDRESS (shipping) ----------------
    final String shippingStreet = (shipping['address_1'] ?? '')
        .toString()
        .trim();
    final String shippingCity = (shipping['city'] ?? '').toString().trim();
    final String shippingState = (shipping['state'] ?? '').toString().trim();
    final String shippingPostcode = (shipping['postcode'] ?? '')
        .toString()
        .trim();
    final String shippingCountry = (shipping['country'] ?? '')
        .toString()
        .trim();

    final List<String> customerParts = [];
    if (shippingStreet.isNotEmpty) customerParts.add(shippingStreet);
    if (shippingCity.isNotEmpty) customerParts.add(shippingCity);
    if (shippingState.isNotEmpty) customerParts.add(shippingState);
    if (shippingCountry.isNotEmpty) customerParts.add(shippingCountry);
    if (shippingPostcode.isNotEmpty) customerParts.add(shippingPostcode);

    final String customerAddress = customerParts.isEmpty
        ? 'Customer address not available'
        : customerParts.join(', ');

    // ---------------- USER IDENTITY ----------------
    // 1) Try to read your app userId from meta_data.app_user_id
    String appUserId = '';
    if (json['meta_data'] is List) {
      final List meta = json['meta_data'] as List;
      for (final m in meta) {
        if (m is Map<String, dynamic>) {
          if (m['key'] == 'app_user_id' && m['value'] != null) {
            appUserId = m['value'].toString();
            break;
          }
        }
      }
    }

    // 2) Fallback to Woo customer_id (usually 0 for guest)
    final String wooCustomerId = (json['customer_id'] ?? '').toString();

    // Effective userId we store and later use in ordersForUser(userId)
    final String effectiveUserId = appUserId.isNotEmpty
        ? appUserId
        : wooCustomerId;

    // Email & name
    final String email = (billing['email'] ?? '').toString().trim();
    final String fullName = [
      billingFirstName,
      billingLastName,
    ].where((e) => e.isNotEmpty).join(' ').trim();

    // ---------------- PAID? ----------------
    final String statusLower = wooStatus.toLowerCase();
    final bool isPaid =
        statusLower == 'processing' ||
        statusLower == 'completed' ||
        statusLower.contains('paid');

    final OrderStatus localStatus = _statusFromWooStatus(wooStatus);

    return Order(
      id: wooId,
      paymentId: wooTransactionId,
      amount: parsedAmount,
      createdAt: createdAt,
      businessAddress: businessAddress,
      customerAddress: customerAddress,
      userId: effectiveUserId, // ← THIS IS NOW YOUR APP USER ID WHEN AVAILABLE
      userEmail: email,
      userName: fullName.isNotEmpty ? fullName : billingFirstName,
      isPaid: isPaid,
      status: localStatus,
    );
  }
}
