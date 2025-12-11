// lib/models/order.dart
// Robust Woo order model: tolerant status parsing + solid paid-detection.

enum OrderStatus {
  confirmed,
  packed,
  shipped,
  outForDelivery,
  delivered,
  unknown,
}

/// Normalize a status string: lower + remove non-alphanum except hyphen/underscore
String _normalizeStatus(String? s) {
  if (s == null) return '';
  final raw = s.toString().trim().toLowerCase();
  // keep hyphen and underscore for patterns, remove other non-alnum
  return raw.replaceAll(RegExp(r'[^a-z0-9\-_]'), '');
}

/// Fuzzy mapping: look for keywords rather than exact equality to support custom statuses.
OrderStatus _orderStatusFromString(String? s) {
  final n = _normalizeStatus(s);

  if (n.isEmpty) return OrderStatus.unknown;

  if (n.contains('complete') || n.contains('delivered')) {
    return OrderStatus.delivered;
  }
  if (n.contains('out') &&
      (n.contains('for') || n.contains('deliver') || n.contains('delivery'))) {
    return OrderStatus.outForDelivery;
  }
  if (n.contains('ship') || n.contains('shipped')) {
    return OrderStatus.shipped;
  }
  if (n.contains('pack') || n.contains('packed')) {
    return OrderStatus.packed;
  }
  if (n.contains('process') ||
      n.contains('processing') ||
      n.contains('confirm') ||
      n.contains('confirmed') ||
      n.contains('onhold') ||
      n.contains('on-hold') ||
      n.contains('on_hold')) {
    return OrderStatus.confirmed;
  }

  return OrderStatus.unknown;
}

/// Helper: read a string value from Woo `meta_data` list by key
String? _metaValueString(dynamic metaData, String key) {
  if (metaData == null) return null;
  if (metaData is List) {
    for (final m in metaData) {
      if (m is Map) {
        final k = m['key'];
        final v = m['value'];
        if (k != null && k.toString() == key) {
          return v?.toString();
        }
      }
    }
  }
  return null;
}

class Order {
  final String id; // Woo order id as string (or fallback)
  final String userId; // customer_id OR app_user_id meta
  final String userEmail; // billing.email
  final String userName; // billing/shipping/company
  final double amount; // total
  final String paymentId; // transaction_id or meta payment id
  final DateTime createdAt;
  final String businessAddress; // billing address string
  final String customerAddress; // shipping address string
  final bool isPaid;
  final OrderStatus status;

  Order({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.amount,
    required this.paymentId,
    required this.createdAt,
    required this.businessAddress,
    required this.customerAddress,
    required this.isPaid,
    required this.status,
  });

  /// Parse WooCommerce order JSON into Order
  factory Order.fromWooJson(Map<String, dynamic> json) {
    // Safe accessors
    final billing = (json['billing'] as Map?) ?? <String, dynamic>{};
    final shipping = (json['shipping'] as Map?) ?? <String, dynamic>{};

    // Ids & emails
    final String idStr = (json['id'] ?? json['order_key'] ?? '').toString();
    final String customerIdStr = (json['customer_id'] ?? '').toString();
    final String billingEmail = (billing['email'] ?? '').toString();

    // Names
    final String billingFirst = (billing['first_name'] ?? '').toString();
    final String billingLast = (billing['last_name'] ?? '').toString();
    final String shippingFirst = (shipping['first_name'] ?? '').toString();
    final String billingCompany = (billing['company'] ?? '').toString();

    // Amount: prefer json['total']
    double total = 0.0;
    try {
      final rawTotal = json['total'] ?? json['total_amount'] ?? '0';
      total = double.tryParse(rawTotal.toString()) ?? 0.0;
    } catch (_) {
      total = 0.0;
    }

    // transaction_id
    final String txId = (json['transaction_id'] ?? json['transaction'] ?? '')
        .toString()
        .trim();

    // Try to pick payment id: txId or meta entries
    String paymentId = '';
    if (txId.isNotEmpty) {
      paymentId = txId;
    } else {
      final pm =
          _metaValueString(json['meta_data'], 'razorpay_payment_id') ??
          _metaValueString(json['meta_data'], 'payment_id') ??
          _metaValueString(json['meta_data'], 'transaction_id');
      if (pm != null) paymentId = pm;
    }

    // userId resolution: prefer numeric customer_id >0 else app_user_id meta
    String resolvedUserId = '';
    try {
      if (customerIdStr.isNotEmpty && customerIdStr != '0') {
        resolvedUserId = customerIdStr;
      } else {
        final appUserMeta = _metaValueString(json['meta_data'], 'app_user_id');
        if (appUserMeta != null && appUserMeta.trim().isNotEmpty) {
          resolvedUserId = appUserMeta.trim();
        }
      }
    } catch (_) {
      resolvedUserId = '';
    }

    // createdAt: date_created or date_created_gmt
    DateTime created = DateTime.now();
    try {
      final dateStr = json['date_created'] ?? json['date_created_gmt'] ?? '';
      if (dateStr != null && dateStr.toString().isNotEmpty) {
        created =
            DateTime.tryParse(dateStr.toString())?.toLocal() ?? DateTime.now();
      }
    } catch (_) {
      created = DateTime.now();
    }

    // addresses
    final String billingAddress = [
      billing['address_1'] ?? '',
      billing['city'] ?? '',
      billing['state'] ?? '',
      billing['postcode'] ?? '',
    ].where((s) => s != null && s.toString().trim().isNotEmpty).join(', ');

    final String shippingAddress = [
      shipping['address_1'] ?? '',
      shipping['city'] ?? '',
      shipping['state'] ?? '',
      shipping['postcode'] ?? '',
    ].where((s) => s != null && s.toString().trim().isNotEmpty).join(', ');

    // Status mapping (fuzzy)
    final String rawStatus = (json['status'] ?? '').toString();
    final OrderStatus mappedStatus = _orderStatusFromString(rawStatus);

    // isPaid detection:
    // - explicit set_paid bool
    // - or explicit transaction_id
    // - or payment_method present & not empty
    // - or recognized meta payment id present
    // - fallback: consider processing/completed as paid
    bool paid = false;
    try {
      final dynamic setPaid = json['set_paid'];
      if (setPaid is bool) {
        paid = setPaid;
      } else if (setPaid != null &&
          setPaid.toString().toLowerCase() == 'true') {
        paid = true;
      } else if (txId.isNotEmpty) {
        paid = true;
      } else {
        final pm = (json['payment_method'] ?? '').toString().trim();
        if (pm.isNotEmpty) paid = true;
        final metaPayment =
            _metaValueString(json['meta_data'], 'razorpay_payment_id') ??
            _metaValueString(json['meta_data'], 'payment_id') ??
            _metaValueString(json['meta_data'], 'transaction_id');
        if (!paid && metaPayment != null && metaPayment.trim().isNotEmpty)
          paid = true;
      }
    } catch (_) {
      paid = false;
    }

    // Fallback: if status is processing/completed treat as paid
    if (!paid) {
      if (mappedStatus == OrderStatus.confirmed ||
          mappedStatus == OrderStatus.delivered) {
        paid = true;
      }
    }

    // userName resolution preference
    String resolvedName = '';
    if ((billingFirst + billingLast).trim().isNotEmpty) {
      resolvedName = (billingFirst + ' ' + billingLast).trim();
    } else if (billingCompany.trim().isNotEmpty) {
      resolvedName = billingCompany.trim();
    } else if (shippingFirst.trim().isNotEmpty) {
      resolvedName = shippingFirst.trim();
    }

    return Order(
      id: idStr.isNotEmpty
          ? idStr
          : DateTime.now().millisecondsSinceEpoch.toString(),
      userId: resolvedUserId,
      userEmail: billingEmail,
      userName: resolvedName,
      amount: total,
      paymentId: paymentId,
      createdAt: created,
      businessAddress: billingAddress,
      customerAddress: shippingAddress,
      isPaid: paid,
      status: mappedStatus,
    );
  }

  /// Local persistence serializer
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userEmail': userEmail,
      'userName': userName,
      'amount': amount,
      'paymentId': paymentId,
      'createdAt': createdAt.toIso8601String(),
      'businessAddress': businessAddress,
      'customerAddress': customerAddress,
      'isPaid': isPaid,
      'status': status.toString().split('.').last,
    };
  }

  /// Rehydrate from local storage JSON
  factory Order.fromJson(Map<String, dynamic> map) {
    OrderStatus parsedStatus = OrderStatus.unknown;
    try {
      final s = (map['status'] ?? '').toString();
      parsedStatus = _orderStatusFromString(s);
    } catch (_) {
      parsedStatus = OrderStatus.unknown;
    }

    DateTime created = DateTime.now();
    try {
      final s = (map['createdAt'] ?? map['created_at'] ?? '').toString();
      if (s.isNotEmpty) created = DateTime.tryParse(s) ?? DateTime.now();
    } catch (_) {
      created = DateTime.now();
    }

    double amt = 0.0;
    try {
      final a = map['amount'] ?? map['total'] ?? 0;
      if (a is num)
        amt = a.toDouble();
      else
        amt = double.tryParse(a.toString()) ?? 0.0;
    } catch (_) {
      amt = 0.0;
    }

    bool paid = false;
    try {
      final p = map['isPaid'] ?? map['paid'] ?? false;
      if (p is bool)
        paid = p;
      else
        paid = p.toString().toLowerCase() == 'true';
    } catch (_) {
      paid = false;
    }

    return Order(
      id: (map['id'] ?? '').toString(),
      userId: (map['userId'] ?? '').toString(),
      userEmail: (map['userEmail'] ?? '').toString(),
      userName: (map['userName'] ?? '').toString(),
      amount: amt,
      paymentId: (map['paymentId'] ?? '').toString(),
      createdAt: created,
      businessAddress: (map['businessAddress'] ?? '').toString(),
      customerAddress: (map['customerAddress'] ?? '').toString(),
      isPaid: paid,
      status: parsedStatus,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Order && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
