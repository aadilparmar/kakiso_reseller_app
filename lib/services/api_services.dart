// lib/services/api_services.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:kakiso_reseller_app/models/brand.dart';
import 'package:kakiso_reseller_app/models/categories.dart';
import 'package:kakiso_reseller_app/models/order.dart';
import 'package:kakiso_reseller_app/models/product.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ApiService {
  // Your Domain
  static const String baseUrl = 'https://stage.kakiso.com';

  // Your Keys (WooCommerce consumer key/secret used for wc/v3 endpoints)
  static const String consumerKey =
      'ck_a821068196cf8a1153635a362fdec04d4e881051';
  static const String consumerSecret =
      'cs_389ffd5342045eb06ac641085e7885fc3f0db010';

  // Optional app-only API key header for your custom endpoint (leave empty if unused)
  static const String appApiKey = '';

  // Helper for Basic Auth Header
  static String get _basicAuth =>
      'Basic ${base64Encode(utf8.encode('$consumerKey:$consumerSecret'))}';

  // Common headers for WooCommerce endpoints
  static Map<String, String> get _headers => {
    "Authorization": _basicAuth,
    "Content-Type": "application/json",
    "User-Agent": "KakisoResellerApp/1.0",
  };

  // ---------------------------------------------------------------------------
  // Product / Category helpers (Unchanged)
  // ---------------------------------------------------------------------------
  static Future<List<CategoryModel>> fetchCategories() async {
    final Uri url = Uri.parse(
      '$baseUrl/wp-json/wc/v3/products/categories?per_page=50&hide_empty=true',
    );

    try {
      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => CategoryModel.fromJson(json)).toList();
      } else {
        throw Exception('Category Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching categories: $e');
    }
  }

  static Future<List<ProductModel>> fetchProducts({
    int page = 1,
    int perPage = 20,
    String orderBy = 'date',
    String order = 'desc',
    double? minPrice,
    double? maxPrice,
  }) async {
    String queryParams = 'status=publish&per_page=$perPage&page=$page';
    queryParams += '&orderby=$orderBy&order=$order';
    if (minPrice != null) queryParams += '&min_price=${minPrice.toInt()}';
    if (maxPrice != null) queryParams += '&max_price=${maxPrice.toInt()}';

    final Uri url = Uri.parse('$baseUrl/wp-json/wc/v3/products?$queryParams');

    try {
      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ProductModel.fromJson(json)).toList();
      } else {
        throw Exception('Product Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching products: $e');
    }
  }

  static Future<List<ProductModel>> fetchAllProductsPaginated({
    String orderBy = 'date',
    String order = 'desc',
    double? minPrice,
    double? maxPrice,
    int perPage = 50,
    int maxPages = 20,
  }) async {
    final List<ProductModel> all = [];
    int page = 1;

    while (true) {
      final List<ProductModel> pageItems = await fetchProducts(
        page: page,
        perPage: perPage,
        orderBy: orderBy,
        order: order,
        minPrice: minPrice,
        maxPrice: maxPrice,
      );

      if (pageItems.isEmpty) break;
      all.addAll(pageItems);
      if (pageItems.length < perPage) break;
      page++;
      if (page > maxPages) {
        break;
      }
    }

    return all;
  }

  static Future<List<ProductModel>> fetchProductsByCategory(
    int categoryId, {
    String orderBy = 'popularity',
    String order = 'desc',
    double? minPrice,
    double? maxPrice,
  }) async {
    String queryParams = 'category=$categoryId&status=publish&per_page=20';
    queryParams += '&orderby=$orderBy&order=$order';
    if (minPrice != null) queryParams += '&min_price=${minPrice.toInt()}';
    if (maxPrice != null) queryParams += '&max_price=${maxPrice.toInt()}';

    final Uri url = Uri.parse('$baseUrl/wp-json/wc/v3/products?$queryParams');

    try {
      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ProductModel.fromJson(json)).toList();
      } else {
        throw Exception('Category Products Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching category products: $e');
    }
  }

  static Future<ProductModel> fetchProductById(int id) async {
    final Uri url = Uri.parse('$baseUrl/wp-json/wc/v3/products/$id');

    try {
      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200) {
        return ProductModel.fromJson(json.decode(response.body));
      } else {
        throw Exception('Product Detail Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching product detail: $e');
    }
  }

  static Future<List<ProductModel>> fetchTopSellingProducts() async {
    final Uri url = Uri.parse(
      '$baseUrl/wp-json/wc/v3/products?per_page=10&status=publish&orderby=popularity',
    );
    try {
      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ProductModel.fromJson(json)).toList();
      } else {
        throw Exception('Top Products Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching top products: $e');
    }
  }

  static Future<List<ProductModel>> fetchNewestProducts() async {
    final Uri url = Uri.parse(
      '$baseUrl/wp-json/wc/v3/products?per_page=10&status=publish&orderby=date',
    );
    try {
      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ProductModel.fromJson(json)).toList();
      } else {
        throw Exception('Newest Products Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching newest products: $e');
    }
  }

  static Future<List<ProductModel>> fetchTrendingProducts() async {
    return fetchTopSellingProducts();
  }

  static Future<List<BrandModel>> fetchBrands() async {
    final Uri url = Uri.parse('$baseUrl/wp-json/wc/v3/brands?per_page=100');

    try {
      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => BrandModel.fromJson(json)).toList();
      } else {
        throw Exception(
          'Brands Error: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching brands: $e');
    }
  }

  static Future<List<ProductModel>> searchProducts(String query) async {
    final Uri url = Uri.parse(
      '$baseUrl/wp-json/wc/v3/products?search=$query&status=publish&per_page=20',
    );
    try {
      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ProductModel.fromJson(json)).toList();
      } else {
        throw Exception('Search Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching products: $e');
    }
  }

  static Future<XFile> downloadImageAsFile(String imageUrl) async {
    final response = await http.get(Uri.parse(imageUrl));
    if (response.statusCode != 200) {
      throw Exception('Failed to download image for WhatsApp share');
    }
    final tempDir = await getTemporaryDirectory();
    final filePath =
        "${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg";
    final file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    return XFile(filePath);
  }

  static Future<String?> ensureWooCustomer({
    required String email,
    required String name,
  }) async {
    final String trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) return null;

    try {
      final Uri findUrl = Uri.parse(
        '$baseUrl/wp-json/wc/v3/customers?email=${Uri.encodeQueryComponent(trimmedEmail)}',
      );

      final findResp = await http.get(findUrl, headers: _headers);

      if (findResp.statusCode == 200) {
        final List<dynamic> list = json.decode(findResp.body) as List<dynamic>;
        if (list.isNotEmpty) {
          final Map<String, dynamic> first = list.first as Map<String, dynamic>;
          final dynamic id = first['id'];
          if (id != null) {
            return id.toString();
          }
        }
      }

      final Uri createUrl = Uri.parse('$baseUrl/wp-json/wc/v3/customers');

      final String finalName = name.trim().isNotEmpty
          ? name.trim()
          : trimmedEmail.split('@').first;

      final Map<String, dynamic> payload = {
        'email': trimmedEmail,
        'first_name': finalName,
        'username': trimmedEmail,
      };

      final createResp = await http.post(
        createUrl,
        headers: _headers,
        body: jsonEncode(payload),
      );

      if (createResp.statusCode == 201 || createResp.statusCode == 200) {
        final Map<String, dynamic> data =
            json.decode(createResp.body) as Map<String, dynamic>;
        final dynamic id = data['id'];
        if (id != null) {
          return id.toString();
        }
      }
    } catch (e) {}

    return null;
  }

  // ---------------------------------------------------------------------------
  // 11. updateBusinessDetails -> UPDATES BOTH BILLING AND RESELLER META
  // ---------------------------------------------------------------------------
  static Future<void> updateBusinessDetails({
    String? userId,
    required Map<String, dynamic> data,
  }) async {
    final int? customerId = int.tryParse((userId ?? '').trim());
    if (customerId == null || customerId <= 0) {
      return;
    }

    final Uri url = Uri.parse('$baseUrl/wp-json/wc/v3/customers/$customerId');

    // 1. Prepare Billing Data
    String fullOwnerName = (data["ownerName"] ?? "").toString().trim();
    String fName = fullOwnerName;
    String lName = "";
    if (fullOwnerName.contains(" ")) {
      final parts = fullOwnerName.split(" ");
      fName = parts.first;
      lName = parts.sublist(1).join(" ");
    }

    final Map<String, dynamic> billingBlock = {
      "first_name": fName,
      "last_name": lName,
      "company": data["businessName"] ?? "",
      "address_1": data["addressLine1"] ?? "",
      "address_2": data["addressLine2"] ?? "",
      "city": data["city"] ?? "",
      "state": data["state"] ?? "",
      "postcode": data["pincode"] ?? "",
      "country": data["country"] ?? "IN",
      "email": data["email"] ?? "",
      "phone": data["phone"] ?? "",
    };

    // 2. Prepare Meta Data (Matches the screenshot fields exactly)
    // - "Address" field in screenshot -> reseller_store_address
    // - "Locality" field in screenshot -> reseller_store_locality
    // - "Pincode" field in screenshot -> reseller_store_pincode
    final List<Map<String, dynamic>> metaData = [
      // Standard Custom Keys
      {"key": "kakiso_whatsapp", "value": data["whatsapp"]},
      {"key": "kakiso_gstin", "value": data["gstin"]},
      {"key": "kakiso_business_name", "value": data["businessName"]},

      // Reseller Profile Keys (For the specific backend section)
      {"key": "reseller_store_store_name", "value": data["businessName"] ?? ""},
      {
        "key": "billing_businessname",
        "value": data["ownerName"] ?? "",
      }, // Or business name if preferred
      {"key": "reseller_store_address", "value": data["addressLine1"] ?? ""},
      {"key": "reseller_store_locality", "value": data["addressLine2"] ?? ""},
      {"key": "reseller_store_city", "value": data["city"] ?? ""},
      {"key": "reseller_store_state", "value": data["state"] ?? ""},
      {"key": "reseller_store_pincode", "value": data["pincode"] ?? ""},
      {
        "key": "reseller_store_postcode",
        "value": data["pincode"] ?? "",
      }, // Redundancy for safety
      {"key": "reseller_store_country", "value": data["country"] ?? "IN"},
      {"key": "reseller_store_phone", "value": data["phone"] ?? ""},
      {"key": "reseller_store_email", "value": data["email"] ?? ""},
      {"key": "billing_gstin", "value": data["gstin"] ?? ""},
    ];

    final Map<String, dynamic> payload = {
      "first_name": fName,
      "last_name": lName,
      "email": data["email"],
      "billing": billingBlock,
      "meta_data": metaData,
    };

    try {
      final response = await http.put(
        url,
        headers: _headers,
        body: jsonEncode(payload),
      );
      if (response.statusCode != 200) {
        throw Exception(
          'Business Details Error: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error saving business details: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // 12. REQUEST PASSWORD RESET
  // ---------------------------------------------------------------------------
  static Future<void> requestPasswordReset(String email) async {
    final String trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) {
      throw Exception('Email address is required');
    }

    final Uri url = Uri.parse('$baseUrl/wp-json/kakiso/v1/password-reset');

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "User-Agent": "KakisoResellerApp/1.0",
        },
        body: jsonEncode({'email': trimmedEmail}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return;
        } else {
          throw Exception(data['message'] ?? 'Failed to send new password');
        }
      } else if (response.statusCode == 400) {
        final data = json.decode(response.body);
        throw Exception(data['message'] ?? 'Invalid email address');
      } else if (response.statusCode == 500) {
        throw Exception('Failed to send email. Please try again later.');
      } else {
        try {
          final data = json.decode(response.body);
          throw Exception(
            data['message'] ?? 'Failed to request password reset',
          );
        } catch (e) {
          throw Exception('Network error. Please check your connection.');
        }
      }
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }

  // ---------------------------------------------------------------------------
  // 13. FETCH BUSINESS DETAILS -> READS RESELLER META FIRST
  // ---------------------------------------------------------------------------
  static Future<Map<String, dynamic>?> fetchBusinessDetails({
    required String userId,
  }) async {
    final int? customerId = int.tryParse(userId.trim());
    if (customerId == null || customerId <= 0) {
      return null;
    }

    final Uri url = Uri.parse('$baseUrl/wp-json/wc/v3/customers/$customerId');

    try {
      final response = await http.get(url, headers: _headers);

      if (response.statusCode != 200) {
        throw Exception(
          'fetchBusinessDetails Error: ${response.statusCode} ${response.body}',
        );
      }

      final Map<String, dynamic> data = json.decode(response.body);
      final billing = (data['billing'] as Map?) ?? {};
      final List meta = (data['meta_data'] as List?) ?? [];

      // Extract specific meta keys
      String? metaStoreName;
      String? metaBusinessName;
      String? metaAddress;
      String? metaLocality;
      String? metaCity;
      String? metaState;
      String? metaPincode;
      String? metaGstin;
      String? metaPhone;
      String? metaEmail;

      for (final m in meta) {
        if (m is Map<String, dynamic>) {
          final key = m['key'];
          final value = m['value']?.toString() ?? '';

          if (key == 'reseller_store_store_name') metaStoreName = value;
          if (key == 'reseller_store_business_name') metaBusinessName = value;
          if (key == 'reseller_store_address') metaAddress = value;
          if (key == 'reseller_store_locality') metaLocality = value;
          if (key == 'reseller_store_city') metaCity = value;
          if (key == 'reseller_store_state') metaState = value;
          if (key == 'reseller_store_pincode') metaPincode = value;
          if (key == 'reseller_store_gstin' || key == 'kakiso_gstin')
            metaGstin = value;
          if (key == 'reseller_store_phone') metaPhone = value;
          if (key == 'reseller_store_email') metaEmail = value;
        }
      }

      // Reconstruct Owner Name from Billing first+last if meta is missing
      String bFirst = billing['first_name']?.toString() ?? '';
      String bLast = billing['last_name']?.toString() ?? '';
      String billingOwner = '$bFirst $bLast'.trim();
      if (billingOwner.isEmpty) {
        billingOwner = data['first_name']?.toString() ?? '';
      }

      // PRIORITY: Reseller Meta > Billing > Root
      return {
        "businessName": metaStoreName ?? billing['company']?.toString() ?? '',
        "ownerName": metaBusinessName ?? billingOwner,
        "phone": metaPhone ?? billing['phone']?.toString() ?? '',
        "whatsapp":
            metaPhone ??
            billing['phone']?.toString() ??
            '', // Default whatsapp to phone
        "email":
            metaEmail ??
            billing['email']?.toString() ??
            data['email']?.toString() ??
            '',

        // Address Mapping
        "addressLine1": metaAddress ?? billing['address_1']?.toString() ?? '',
        "addressLine2": metaLocality ?? billing['address_2']?.toString() ?? '',
        "address":
            metaAddress ??
            billing['address_1']?.toString() ??
            '', // Legacy support

        "city": metaCity ?? billing['city']?.toString() ?? '',
        "state": metaState ?? billing['state']?.toString() ?? '',
        "country": billing['country']?.toString() ?? 'India',
        "pincode": metaPincode ?? billing['postcode']?.toString() ?? '',
        "gstin": metaGstin ?? '',
      };
    } catch (e) {
      throw Exception('Error fetching business details: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // NEW: updateResellerBusinessMeta (Deprecated but kept for compatibility)
  // ---------------------------------------------------------------------------
  static Future<void> updateResellerBusinessMeta({
    String? userId,
    required Map<String, dynamic> data,
  }) async {
    // This is now effectively handled inside updateBusinessDetails via meta_data
    // You can keep this empty or remove it if you only use updateBusinessDetails
    return;
  }

  // ... [Rest of the file remains unchanged: Categories, Leaderboards, Orders] ...
  static const int topRankingCategoryId = 513;
  static const int hotRankingCategoryId = 512;

  static Future<List<ProductModel>> fetchTopRankingProducts() async {
    try {
      final products = await fetchProductsByCategory(
        topRankingCategoryId,
        orderBy: 'menu_order',
        order: 'asc',
      );
      if (products.isEmpty) {
        return fetchTopSellingProducts();
      }
      return products;
    } catch (e) {
      return fetchTopSellingProducts();
    }
  }

  static Future<List<ProductModel>> fetchHotRankingProducts() async {
    try {
      final products = await fetchProductsByCategory(
        hotRankingCategoryId,
        orderBy: 'menu_order',
        order: 'asc',
      );
      if (products.isEmpty) {
        return fetchTopSellingProducts();
      }
      return products;
    } catch (e) {
      return fetchTopSellingProducts();
    }
  }

  static Future<Map<String, dynamic>> createWooOrder({
    String? userId,
    required List<Map<String, dynamic>> lineItems,
    required Map<String, dynamic> billing,
    required Map<String, dynamic> shipping,
    required String paymentId,
    String paymentMethod = 'razorpay',
    String paymentMethodTitle = 'Razorpay',
    List<Map<String, dynamic>>? shippingLines,
    List<Map<String, dynamic>>? feeLines,
  }) async {
    final Uri url = Uri.parse('$baseUrl/wp-json/wc/v3/orders');

    final String trimmedUserId = (userId ?? '').trim();
    final int? customerId = int.tryParse(trimmedUserId);

    final List<Map<String, dynamic>> meta = [
      {'key': 'razorpay_payment_id', 'value': paymentId},
      {'key': 'kakiso_order_source', 'value': 'kakiso_reseller_app'},
    ];

    if (trimmedUserId.isNotEmpty) {
      meta.add({'key': 'app_user_id', 'value': trimmedUserId});
    }

    final String billingEmail = (billing['email'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    if (billingEmail.isNotEmpty) {
      meta.add({'key': 'app_user_email', 'value': billingEmail});
    }

    final Map<String, dynamic> payload = {
      'payment_method': paymentMethod,
      'payment_method_title': paymentMethodTitle,
      'set_paid': true,
      'billing': billing,
      'shipping': shipping,
      'line_items': lineItems,
      'meta_data': meta,
    };

    if (customerId != null && customerId > 0) {
      payload['customer_id'] = customerId;
    }

    if (shippingLines != null && shippingLines.isNotEmpty) {
      final enriched = shippingLines.map((s) {
        final Map<String, dynamic> copy = Map<String, dynamic>.from(s);
        copy['total'] = (copy['total'] ?? '0.00').toString();
        copy['total_tax'] = (copy['total_tax'] ?? '0.00').toString();
        copy['taxes'] = copy['taxes'] ?? <Map<String, dynamic>>[];
        return copy;
      }).toList();
      payload['shipping_lines'] = enriched;

      final double shippingSum = enriched.fold(0.0, (double sum, e) {
        final val = double.tryParse((e['total'] ?? '0').toString()) ?? 0.0;
        return sum + val;
      });
      payload['shipping_total'] = shippingSum.toStringAsFixed(2);
    }

    if (feeLines != null && feeLines.isNotEmpty) {
      final enriched = feeLines.map((f) {
        final Map<String, dynamic> copy = Map<String, dynamic>.from(f);
        copy['total'] = (copy['total'] ?? '0.00').toString();
        copy['tax_class'] = copy['tax_class'] ?? '';
        copy['total_tax'] = (copy['total_tax'] ?? '0.00').toString();
        copy['taxes'] = copy['taxes'] ?? <Map<String, dynamic>>[];
        return copy;
      }).toList();
      payload['fee_lines'] = enriched;

      final double feeSum = enriched.fold(0.0, (double sum, e) {
        final val = double.tryParse((e['total'] ?? '0').toString()) ?? 0.0;
        return sum + val;
      });
      payload['fee_total'] = feeSum.toStringAsFixed(2);
    }

    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode(payload),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
          'createWooOrder Error: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<List<Order>> fetchWooOrdersForCustomer({
    String? userId,
    String? userEmail,
  }) async {
    final List<Order> result = [];
    final Set<String> seenIds = {};

    final String rawUserId = (userId ?? '').trim();
    final String rawEmail = (userEmail ?? '').trim();

    final int? customerId = int.tryParse(rawUserId);
    if (customerId != null && customerId > 0) {
      final Uri url = Uri.parse(
        '$baseUrl/wp-json/wc/v3/orders?customer=$customerId&per_page=50&orderby=date&order=desc',
      );

      try {
        final response = await http.get(url, headers: _headers);

        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          for (final raw in data) {
            if (raw is Map<String, dynamic>) {
              final Order order = Order.fromWooJson(raw);
              if (!seenIds.contains(order.id)) {
                seenIds.add(order.id);
                result.add(order);
              }
            }
          }
        }
      } catch (e) {}
    }

    final String email = rawEmail;
    if (email.isNotEmpty) {
      final Uri url = Uri.parse(
        '$baseUrl/wp-json/wc/v3/orders?search=${Uri.encodeQueryComponent(email)}&per_page=50&orderby=date&order=desc',
      );

      try {
        final response = await http.get(url, headers: _headers);

        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          for (final raw in data) {
            if (raw is Map<String, dynamic>) {
              final Order order = Order.fromWooJson(raw);
              if (!seenIds.contains(order.id)) {
                seenIds.add(order.id);
                result.add(order);
              }
            }
          }
        }
      } catch (e) {}
    }

    return result;
  }

  static Future<Order> fetchWooOrderById({required String orderId}) async {
    final Uri url = Uri.parse('$baseUrl/wp-json/wc/v3/orders/$orderId');

    try {
      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Order.fromWooJson(data);
      } else {
        throw Exception(
          'fetchWooOrderById Error: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching woo order by id: $e');
    }
  }
}
