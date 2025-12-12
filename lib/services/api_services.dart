// lib/services/api_services.dart
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
  static const String baseUrl = 'https://prod-kakiso.smitpatadiya.me';

  // Your Keys (WooCommerce consumer key/secret used for wc/v3 endpoints)
  static const String consumerKey =
      'ck_2379795496deebd9ab611ce3e4e54f90ebe9d289';
  static const String consumerSecret =
      'cs_5dc571e56332bd0eb6effd7b318f81bb8c6347c7';

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
  // Product / Category helpers
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
        print(
          "ApiService.fetchAllProductsPaginated: Reached maxPages=$maxPages, stopping.",
        );
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

  // ---------------------------------------------------------------------------
  // 🔹 BRANDS (with logo)
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // 10. ENSURE / GET WOO CUSTOMER BY EMAIL (returns customer_id as String)
  // ---------------------------------------------------------------------------
  static Future<String?> ensureWooCustomer({
    required String email,
    required String name,
  }) async {
    final String trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) return null;

    try {
      // 1) Try to find existing customer by email
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
            final String idStr = id.toString();
            print('[ensureWooCustomer] Found existing customer: id=$idStr');
            return idStr;
          }
        }
      } else {
        print(
          '[ensureWooCustomer] GET customers?email= failed: '
          '${findResp.statusCode} ${findResp.body}',
        );
      }

      // 2) Not found → create a new customer
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
          final String idStr = id.toString();
          print('[ensureWooCustomer] Created new customer: id=$idStr');
          return idStr;
        }
      } else {
        print(
          '[ensureWooCustomer] POST /customers failed: '
          '${createResp.statusCode} ${createResp.body}',
        );
      }
    } catch (e) {
      print('[ensureWooCustomer] exception: $e');
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // 11. updateBusinessDetails -> only WooCommerce billing/shipping + kakiso meta
  // ---------------------------------------------------------------------------
  static Future<void> updateBusinessDetails({
    String? userId,
    required Map<String, dynamic> data,
  }) async {
    final int? customerId = int.tryParse((userId ?? '').trim());
    if (customerId == null || customerId <= 0) {
      print(
        '[ApiService.updateBusinessDetails] Skipping update: invalid/missing userId="$userId"',
      );
      return;
    }

    final Uri url = Uri.parse('$baseUrl/wp-json/wc/v3/customers/$customerId');

    final Map<String, dynamic> payload = {
      "first_name": data["ownerName"],
      "email": data["email"],
      "billing": {
        "first_name": data["ownerName"],
        "company": data["businessName"],
        "address_1": data["address"],
        "city": data["city"],
        "postcode": data["pincode"],
        "country": data["country"] ?? "IN",
        "email": data["email"],
        "phone": data["phone"],
      },
      "shipping": {
        "first_name": data["ownerName"],
        "company": data["businessName"],
        "address_1": data["address"],
        "city": data["city"],
        "postcode": data["pincode"],
        "country": data["country"] ?? "IN",
      },
      "meta_data": [
        {"key": "kakiso_whatsapp", "value": data["whatsapp"]},
        {"key": "kakiso_gstin", "value": data["gstin"]},
        {"key": "kakiso_business_name", "value": data["businessName"]},
      ],
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
    final Uri url = Uri.parse('$baseUrl/wp-login.php?action=lostpassword');

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
          "User-Agent": "KakisoResellerApp/1.0",
        },
        body: {
          'user_login': email,
          'wp-submit': 'Get New Password',
          'redirect_to': baseUrl,
        },
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Password reset request failed (${response.statusCode}).',
        );
      }
    } catch (e) {
      throw Exception('Error requesting password reset: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // 13. FETCH BUSINESS DETAILS FOR CURRENT USER (reads WooCommerce customer)
  // ---------------------------------------------------------------------------
  static Future<Map<String, dynamic>?> fetchBusinessDetails({
    required String userId,
  }) async {
    final int? customerId = int.tryParse(userId.trim());
    if (customerId == null || customerId <= 0) {
      print('[ApiService.fetchBusinessDetails] invalid userId="$userId"');
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

      String? whatsapp;
      String? gstin;
      String? kakisoBusinessName;

      for (final m in meta) {
        if (m is Map<String, dynamic>) {
          final key = m['key'];
          final value = m['value'];
          if (key == 'kakiso_whatsapp') whatsapp = value?.toString();
          if (key == 'kakiso_gstin') gstin = value?.toString();
          if (key == 'kakiso_business_name') {
            kakisoBusinessName = value?.toString();
          }
        }
      }

      return {
        "businessName":
            kakisoBusinessName ?? billing['company']?.toString() ?? '',
        "ownerName": data['first_name']?.toString() ?? '',
        "phone": billing['phone']?.toString() ?? '',
        "whatsapp": whatsapp ?? billing['phone']?.toString() ?? '',
        "email":
            billing['email']?.toString() ?? data['email']?.toString() ?? '',
        "address": billing['address_1']?.toString() ?? '',
        "city": billing['city']?.toString() ?? '',
        "state": billing['state']?.toString() ?? '',
        "country": billing['country']?.toString() ?? 'India',
        "pincode": billing['postcode']?.toString() ?? '',
        "gstin": gstin ?? '',
      };
    } catch (e) {
      throw Exception('Error fetching business details: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // NEW: updateResellerBusinessMeta -> writes reseller-specific fields into user meta
  // ---------------------------------------------------------------------------
  static Future<void> updateResellerBusinessMeta({
    String? userId,
    required Map<String, dynamic> data,
  }) async {
    final int? uid = int.tryParse((userId ?? '').trim());
    if (uid == null || uid <= 0) {
      print(
        '[ApiService.updateResellerBusinessMeta] Skipping update: invalid/missing userId="$userId"',
      );
      return;
    }

    // Build meta payload (exact meta keys that your WP admin expects)
    final Map<String, dynamic> metaPayload = {
      'reseller_store_store_name': data['businessName'] ?? '',
      'reseller_store_business_name': data['ownerName'] ?? '',
      'reseller_store_locality': data['address'] ?? '',
      'reseller_store_city': data['city'] ?? '',
      'reseller_store_state': data['state'] ?? '',
      'reseller_store_country': data['country'] ?? '',
      'reseller_store_postcode': data['pincode'] ?? '',
      'reseller_store_phone': data['phone'] ?? '',
      'reseller_store_whatsapp': data['whatsapp'] ?? '',
      'reseller_store_email': data['email'] ?? '',
      'reseller_store_gstin': data['gstin'] ?? '',
    };

    // 1) Preferred: call a custom REST endpoint that writes user meta on server-side
    final Uri customUrl = Uri.parse('$baseUrl/wp-json/kakiso/v1/reseller-meta');

    try {
      final headers = {
        "Content-Type": "application/json",
        "User-Agent": "KakisoResellerApp/1.0",
      };
      if (appApiKey.isNotEmpty) {
        headers['x-kakiso-api-key'] = appApiKey;
      }

      final response = await http.post(
        customUrl,
        headers: headers,
        body: jsonEncode({'user_id': uid, 'meta': metaPayload}),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // success on custom endpoint
        return;
      } else {
        print(
          '[ApiService.updateResellerBusinessMeta] custom endpoint returned ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      print(
        '[ApiService.updateResellerBusinessMeta] custom endpoint call failed: $e',
      );
      // fallthrough to fallback
    }

    // 2) Fallback: try wp/v2/users/<id> with meta object (server must permit this)
    final Uri wpUsersUrl = Uri.parse('$baseUrl/wp-json/wp/v2/users/$uid');
    try {
      final response = await http.post(
        wpUsersUrl,
        headers: _headers,
        body: jsonEncode({'meta': metaPayload}),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return;
      } else {
        throw Exception(
          'wp/v2/users fallback failed (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error updating reseller business meta: $e');
    }
  }

  // 🔥 Leaderboard category IDs (set these to real IDs from WP)
  static const int topRankingCategoryId = 513;
  static const int hotRankingCategoryId = 512;

  /// Products admin marked as "Top Ranking" (WP category)
  static Future<List<ProductModel>> fetchTopRankingProducts() async {
    try {
      final products = await fetchProductsByCategory(
        topRankingCategoryId,
        orderBy: 'menu_order',
        order: 'asc',
      );

      print(
        '[ApiService.fetchTopRankingProducts] got ${products.length} items for category $topRankingCategoryId',
      );

      if (products.isEmpty) {
        print(
          '[ApiService.fetchTopRankingProducts] empty, falling back to fetchTopSellingProducts()',
        );
        return fetchTopSellingProducts();
      }

      return products;
    } catch (e) {
      print('[ApiService.fetchTopRankingProducts] error: $e');
      return fetchTopSellingProducts();
    }
  }

  /// Products admin marked as "Hot Ranking" (WP category)
  static Future<List<ProductModel>> fetchHotRankingProducts() async {
    try {
      final products = await fetchProductsByCategory(
        hotRankingCategoryId,
        orderBy: 'menu_order',
        order: 'asc',
      );

      print(
        '[ApiService.fetchHotRankingProducts] got ${products.length} items for category $hotRankingCategoryId',
      );

      if (products.isEmpty) {
        print(
          '[ApiService.fetchHotRankingProducts] empty, falling back to fetchTopSellingProducts()',
        );
        return fetchTopSellingProducts();
      }

      return products;
    } catch (e) {
      print('[ApiService.fetchHotRankingProducts] error: $e');
      return fetchTopSellingProducts();
    }
  }

  // ---------------------------------------------------------------------------
  // 14. CREATE WOO ORDER AFTER SUCCESSFUL PAYMENT
  // ---------------------------------------------------------------------------
  /// Creates a WooCommerce order in `wc/v3/orders`.
  ///
  /// - [userId] is expected to be the WooCommerce customer_id (numeric as string).
  ///   - If numeric → used as Woo `customer_id`.
  ///   - In all cases it is also stored in meta_data as `app_user_id`.
  ///
  /// - [orderTotal] when provided will be set as the order-level `total` in the Woo payload.
  ///
  /// Returns the decoded Woo order JSON on success.
  static Future<Map<String, dynamic>> createWooOrder({
    String? userId,
    required List<Map<String, dynamic>> lineItems,
    required Map<String, dynamic> billing,
    required Map<String, dynamic> shipping,
    required String paymentId,
    String paymentMethod = 'razorpay',
    String paymentMethodTitle = 'Razorpay',
    // optional aggregated order total to override what Woo would compute.
    double? orderTotal,
    // optional shipping/fee lines (not required for your current use-case)
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

    // Always store the userId in meta so we can match across devices
    if (trimmedUserId.isNotEmpty) {
      meta.add({'key': 'app_user_id', 'value': trimmedUserId});
    }

    // Also add the billing email lowercased so we can match by email reliably
    final String billingEmail = (billing['email'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    if (billingEmail.isNotEmpty) {
      meta.add({'key': 'app_user_email', 'value': billingEmail});
    }

    // If an aggregated admin total is provided, add it to meta so it's always visible.
    if (orderTotal != null) {
      meta.add({
        'key': 'kakiso_admin_total',
        'value': orderTotal.toStringAsFixed(2),
      });
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

    // Include shipping_lines and fee_lines only if passed and non-empty.
    // These are optional — your current requirement is to send aggregated total,
    // but we support including them if needed later.
    if (shippingLines != null && shippingLines.isNotEmpty) {
      // ensure totals are strings
      final enriched = shippingLines.map((s) {
        final Map<String, dynamic> copy = Map<String, dynamic>.from(s);
        copy['total'] = (copy['total'] ?? '0.00').toString();
        copy['total_tax'] = (copy['total_tax'] ?? '0.00').toString();
        copy['taxes'] = copy['taxes'] ?? <Map<String, dynamic>>[];
        return copy;
      }).toList();
      payload['shipping_lines'] = enriched;

      // also set shipping_total (string) if aggregated total not provided
      if (orderTotal == null) {
        final double shippingSum = enriched.fold(0.0, (double sum, e) {
          final val = double.tryParse((e['total'] ?? '0').toString()) ?? 0.0;
          return sum + val;
        });
        payload['shipping_total'] = shippingSum.toStringAsFixed(2);
      }
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

      if (orderTotal == null) {
        final double feeSum = enriched.fold(0.0, (double sum, e) {
          final val = double.tryParse((e['total'] ?? '0').toString()) ?? 0.0;
          return sum + val;
        });
        payload['fee_total'] = feeSum.toStringAsFixed(2);
      }
    }

    // If aggregated order total is provided, set it as order-level total.
    // Woo accepts 'total' as a string. We also set shipping_total and fee_total to "0.00"
    // to avoid ambiguity in admin if no breakdown is sent.
    if (orderTotal != null) {
      payload['total'] = orderTotal.toStringAsFixed(2);
      // If shipping_total / fee_total are not already set above, set them to "0.00"
      payload['shipping_total'] = payload['shipping_total'] ?? '0.00';
      payload['fee_total'] = payload['fee_total'] ?? '0.00';
    }

    print('==== createWooOrder URL: $url');
    print('==== createWooOrder PAYLOAD: ${jsonEncode(payload)}');

    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode(payload),
      );

      print('==== createWooOrder STATUS: ${response.statusCode}');
      print('==== createWooOrder BODY: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
          'createWooOrder Error: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      print('==== createWooOrder EXCEPTION: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 15. FETCH WOO ORDERS FOR CUSTOMER (by id and/or email)
  // ---------------------------------------------------------------------------
  // replace the existing fetchWooOrdersForCustomer implementation in lib/services/api_services.dart

  static Future<List<Order>> fetchWooOrdersForCustomer({
    String? userId,
    String? userEmail,
  }) async {
    final List<Order> result = [];
    final Set<String> seenIds = {};

    final String rawUserId = (userId ?? '').trim();
    final String rawEmail = (userEmail ?? '').trim();

    print(
      '[ApiService.fetchWooOrdersForCustomer] called userId="$rawUserId" userEmail="$rawEmail"',
    );

    // ---------- 1) Try numeric customer_id ----------
    final int? customerId = int.tryParse(rawUserId);
    if (customerId != null && customerId > 0) {
      final Uri url = Uri.parse(
        '$baseUrl/wp-json/wc/v3/orders?customer=$customerId&per_page=50&orderby=date&order=desc',
      );

      try {
        print('[ApiService.fetchWooOrdersForCustomer] GET $url');
        final response = await http.get(url, headers: _headers);

        print(
          '[ApiService.fetchWooOrdersForCustomer] customer_id response status=${response.statusCode}',
        );
        // Log a short part of body for debugging (avoid huge logs)
        if (response.body.length < 2000) {
          print(
            '[ApiService.fetchWooOrdersForCustomer] body: ${response.body}',
          );
        } else {
          print(
            '[ApiService.fetchWooOrdersForCustomer] body (truncated): ${response.body.substring(0, 1200)} ...',
          );
        }

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
        } else {
          print(
            '[ApiService.fetchWooOrdersForCustomer] (by customer_id) non-200: ${response.statusCode}',
          );
        }
      } catch (e, st) {
        print(
          '[ApiService.fetchWooOrdersForCustomer] exception while fetching by customer_id: $e\n$st',
        );
      }
    } else {
      print(
        '[ApiService.fetchWooOrdersForCustomer] skipping customer_id query (invalid or empty): "$rawUserId"',
      );
    }

    // ---------- 2) Fallback: search by billing email ----------
    final String email = rawEmail;
    if (email.isNotEmpty) {
      final Uri url = Uri.parse(
        '$baseUrl/wp-json/wc/v3/orders?search=${Uri.encodeQueryComponent(email)}&per_page=50&orderby=date&order=desc',
      );

      try {
        print(
          '[ApiService.fetchWooOrdersForCustomer] GET $url (search by email)',
        );
        final response = await http.get(url, headers: _headers);

        print(
          '[ApiService.fetchWooOrdersForCustomer] email search response status=${response.statusCode}',
        );
        if (response.body.length < 2000) {
          print(
            '[ApiService.fetchWooOrdersForCustomer] body: ${response.body}',
          );
        } else {
          print(
            '[ApiService.fetchWooOrdersForCustomer] body (truncated): ${response.body.substring(0, 1200)} ...',
          );
        }

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
        } else {
          print(
            '[ApiService.fetchWooOrdersForCustomer] (by email) non-200: ${response.statusCode}',
          );
        }
      } catch (e, st) {
        print(
          '[ApiService.fetchWooOrdersForCustomer] exception while fetching by email: $e\n$st',
        );
      }
    } else {
      print(
        '[ApiService.fetchWooOrdersForCustomer] skipping email search (empty email)',
      );
    }

    print(
      '[ApiService.fetchWooOrdersForCustomer] finished. total found=${result.length}',
    );
    return result;
  }

  // ---------------------------------------------------------------------------
  // 16. FETCH SINGLE WOO ORDER BY ID (for detail refresh)
  // ---------------------------------------------------------------------------
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
