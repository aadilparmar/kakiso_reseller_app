// lib/models/order.dart

// -----------------------------------------------------------
// 1. New Class: Snapshot of a single item in the order
//    (Used to generate invoices with correct HSN/GST)
// -----------------------------------------------------------
class OrderItemSnapshot {
  final String productId;
  final String name;
  final String hsnCode;
  final String gstRate; // e.g. "18"
  final double unitPrice; // Price per unit
  final int quantity;

  OrderItemSnapshot({
    required this.productId,
    required this.name,
    required this.hsnCode,
    required this.gstRate,
    required this.unitPrice,
    required this.quantity,
  });

  // Serialization for local storage
  Map<String, dynamic> toJson() => {
    'productId': productId,
    'name': name,
    'hsnCode': hsnCode,
    'gstRate': gstRate,
    'unitPrice': unitPrice,
    'quantity': quantity,
  };

  factory OrderItemSnapshot.fromJson(Map<String, dynamic> json) {
    return OrderItemSnapshot(
      productId: json['productId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      hsnCode: json['hsnCode']?.toString() ?? 'NA',
      gstRate: json['gstRate']?.toString() ?? '18',
      unitPrice: (json['unitPrice'] is num)
          ? (json['unitPrice'] as num).toDouble()
          : double.tryParse(json['unitPrice'].toString()) ?? 0.0,
      quantity: (json['quantity'] is num)
          ? (json['quantity'] as num).toInt()
          : 1,
    );
  }
}

// -----------------------------------------------------------
// 2. Enum: Order Status
// -----------------------------------------------------------
enum OrderStatus { confirmed, packed, shipped, outForDelivery, delivered }

// -----------------------------------------------------------
// 3. Main Order Class
// -----------------------------------------------------------
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

  // 🔹 NEW: List of items in this order
  final List<OrderItemSnapshot> items;

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
    this.items = const [], // Default to empty
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
      return OrderStatus.outForDelivery;
    }

    // 3) Shipped
    if (s.contains('ship')) {
      return OrderStatus.shipped;
    }

    // 4) Packed
    if (s.contains('pack')) {
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
      // 🔹 Serialize Items
      "items": items.map((e) => e.toJson()).toList(),
    };
  }

  // -----------------------------------------------------------
  // Convert JSON back to Order (from local storage)
  // -----------------------------------------------------------
  factory Order.fromJson(Map<String, dynamic> json) {
    // 🔹 Parse Items
    List<OrderItemSnapshot> parsedItems = [];
    if (json['items'] != null && json['items'] is List) {
      parsedItems = (json['items'] as List)
          .map((e) => OrderItemSnapshot.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return Order(
      id: json["id"]?.toString() ?? "",
      paymentId: json["paymentId"]?.toString() ?? "",
      amount: (json["amount"] is num)
          ? (json["amount"] as num).toDouble()
          : double.tryParse(json["amount"].toString()) ?? 0.0,
      createdAt: DateTime.tryParse(json["createdAt"] ?? "") ?? DateTime.now(),
      businessAddress: json["businessAddress"]?.toString() ?? "",
      customerAddress: json["customerAddress"]?.toString() ?? "",
      userEmail: json['billing']?['email']?.toString() ?? '',
      userId: json['customer_id']?.toString() ?? '',
      userName: json["userName"]?.toString() ?? "",
      isPaid: json["isPaid"] == true,
      status: _statusFromString(json["status"]?.toString() ?? "confirmed"),
      items: parsedItems,
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

    // Billing & shipping maps
    final billing = (json['billing'] is Map)
        ? Map<String, dynamic>.from(json['billing'] as Map)
        : <String, dynamic>{};

    final shipping = (json['shipping'] is Map)
        ? Map<String, dynamic>.from(json['shipping'] as Map)
        : <String, dynamic>{};

    // Amount
    final double parsedAmount = double.tryParse(wooTotal) ?? 0.0;

    // Creation time
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

    final String wooCustomerId = (json['customer_id'] ?? '').toString();
    final String effectiveUserId = appUserId.isNotEmpty
        ? appUserId
        : wooCustomerId;

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

    // ---------------- 🔹 PARSE ITEMS ----------------
    // Map WooCommerce line_items to OrderItemSnapshot
    List<OrderItemSnapshot> loadedItems = [];
    if (json['line_items'] != null && json['line_items'] is List) {
      loadedItems = (json['line_items'] as List).map((i) {
        final Map<String, dynamic> item = i as Map<String, dynamic>;

        final double lineTotal =
            double.tryParse(item['total']?.toString() ?? '0') ?? 0.0;
        final int qty = (item['quantity'] is num)
            ? (item['quantity'] as num).toInt()
            : 1;

        // Calculate unit price from total (since line_items usually gives line total)
        final double unitPrice = qty > 0 ? (lineTotal / qty) : 0.0;

        // Try to get meta data for HSN/GST if passed from checkout, else default
        // WooCommerce doesn't store HSN/GST by default in line_items unless custom meta is added.
        // We default to 'NA' and '18' here if missing to prevent invoice crash.
        String hsn = 'NA';
        String gst = '18';

        if (item['meta_data'] is List) {
          for (var m in item['meta_data']) {
            if (m['key'] == 'hsn_code') hsn = m['value'].toString();
            if (m['key'] == 'gst_rate') gst = m['value'].toString();
          }
        }

        return OrderItemSnapshot(
          productId: item['product_id']?.toString() ?? '',
          name: item['name']?.toString() ?? 'Unknown Product',
          hsnCode: hsn,
          gstRate: gst,
          unitPrice: unitPrice,
          quantity: qty,
        );
      }).toList();
    }

    return Order(
      id: wooId,
      paymentId: wooTransactionId,
      amount: parsedAmount,
      createdAt: createdAt,
      businessAddress: businessAddress,
      customerAddress: customerAddress,
      userId: effectiveUserId,
      userEmail: email,
      userName: fullName.isNotEmpty ? fullName : billingFirstName,
      isPaid: isPaid,
      status: localStatus,
      items: loadedItems, // <--- Assign parsed items
    );
  }
}
