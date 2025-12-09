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
  // If you set this, ensure your server's permission callback checks it.
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
    // NOTE:
    // This assumes you're using a WooCommerce Brands plugin that exposes:
    //   GET /wp-json/wc/v3/brands
    //
    // BrandModel.fromJson should read fields like:
    //   id, name, slug, and image['src'] for logo URL.
    //
    // If your plugin uses a different route (e.g. /wp-json/wp/v2/pwb-brand),
    // just change the URL below but keep the rest of the logic the same.
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
        // Log & fallthrough to fallback attempt
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
  static const int topRankingCategoryId = 513; // TODO: change to your real ID
  static const int hotRankingCategoryId = 512; // TODO: change to your real ID

  /// Products admin marked as "Top Ranking" (WP category)
  static Future<List<ProductModel>> fetchTopRankingProducts() async {
    try {
      final products = await fetchProductsByCategory(
        topRankingCategoryId,
        // use custom sorting (menu order) if you sort in Woo admin
        orderBy: 'menu_order',
        order: 'asc',
      );

      print(
        '[ApiService.fetchTopRankingProducts] got ${products.length} items for category $topRankingCategoryId',
      );

      // Fallback so app UI doesn't look empty while you configure WP
      if (products.isEmpty) {
        print(
          '[ApiService.fetchTopRankingProducts] empty, falling back to fetchTopSellingProducts()',
        );
        return fetchTopSellingProducts();
      }

      return products;
    } catch (e) {
      print('[ApiService.fetchTopRankingProducts] error: $e');
      // Fallback on error too
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
  /// You must build:
  ///  - [lineItems]: list like
  ///      [{'product_id': 123, 'quantity': 2}, {'product_id': 456, 'quantity': 1}]
  ///  - [billing] and [shipping]: maps matching WooCommerce billing/shipping schema
  ///  - [paymentId]: Razorpay payment id
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
  }) async {
    final Uri url = Uri.parse('$baseUrl/wp-json/wc/v3/orders');

    final int? customerId = int.tryParse((userId ?? '').trim());

    final Map<String, dynamic> payload = {
      'payment_method': paymentMethod,
      'payment_method_title': paymentMethodTitle,
      'set_paid': true,
      'billing': billing,
      'shipping': shipping,
      'line_items': lineItems,
      'meta_data': [
        {'key': 'razorpay_payment_id', 'value': paymentId},
        {'key': 'kakiso_order_source', 'value': 'kakiso_reseller_app'},
      ],
    };

    if (customerId != null && customerId > 0) {
      payload['customer_id'] = customerId;
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
  // 15. FETCH WOO ORDERS FOR CUSTOMER (order history)
  // ---------------------------------------------------------------------------
  static Future<List<Order>> fetchWooOrdersForCustomer({
    required String userId,
  }) async {
    final int? customerId = int.tryParse(userId.trim());
    if (customerId == null || customerId <= 0) {
      return [];
    }

    final Uri url = Uri.parse(
      '$baseUrl/wp-json/wc/v3/orders?customer=$customerId&per_page=50&orderby=date&order=desc',
    );

    try {
      final response = await http.get(url, headers: _headers);

      if (response.statusCode != 200) {
        throw Exception(
          'fetchWooOrdersForCustomer Error: ${response.statusCode} ${response.body}',
        );
      }

      final List<dynamic> data = json.decode(response.body);

      return data
          .map<Order>(
            (jsonOrder) =>
                _mapWooOrderToLocalOrder(jsonOrder as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      // On any error, just return empty and keep app working
      return [];
    }
  }

  /// Internal helper to convert Woo order JSON → local Order model.
  static Order _mapWooOrderToLocalOrder(Map<String, dynamic> jsonOrder) {
    final Map<String, dynamic> billing =
        (jsonOrder['billing'] ?? {}) as Map<String, dynamic>;
    final Map<String, dynamic> shipping =
        (jsonOrder['shipping'] ?? {}) as Map<String, dynamic>;
    final List<dynamic> meta = (jsonOrder['meta_data'] ?? []) as List<dynamic>;

    // Try to read Razorpay payment id from meta_data
    String paymentId = '';
    for (final m in meta) {
      if (m is Map<String, dynamic> && m['key'] == 'razorpay_payment_id') {
        paymentId = (m['value'] ?? '').toString();
        break;
      }
    }

    final String wooStatus = (jsonOrder['status'] ?? '').toString();

    OrderStatus status;
    switch (wooStatus) {
      case 'processing':
        status = OrderStatus.packed;
        break;
      case 'completed':
        status = OrderStatus.delivered;
        break;
      case 'pending':
      case 'on-hold':
      case 'cancelled':
      case 'refunded':
      case 'failed':
      default:
        status = OrderStatus.confirmed;
        break;
    }

    final double amount =
        double.tryParse((jsonOrder['total'] ?? '0').toString()) ?? 0.0;

    final DateTime createdAt =
        DateTime.tryParse((jsonOrder['date_created'] ?? '').toString()) ??
        DateTime.now();

    return Order(
      id: (jsonOrder['id'] ?? '').toString(),
      paymentId: paymentId,
      amount: amount,
      createdAt: createdAt,
      businessAddress: _buildWooAddressString(billing),
      customerAddress: _buildWooAddressString(shipping),
      userId: (jsonOrder['customer_id'] ?? '').toString(),
      userEmail: (billing['email'] ?? '').toString(),
      userName: (billing['first_name'] ?? '').toString(),
      isPaid: wooStatus == 'processing' || wooStatus == 'completed',
      status: status,
    );
  }

  static String _buildWooAddressString(Map<String, dynamic> data) {
    final parts = <String>[];

    void add(dynamic v) {
      if (v == null) return;
      final s = v.toString().trim();
      if (s.isNotEmpty) parts.add(s);
    }

    add(data['company']);
    add(data['first_name']);
    add(data['address_1']);
    add(data['address_2']);
    add(data['city']);
    add(data['state']);
    add(data['country']);
    add(data['postcode']);

    return parts.join(', ');
  }

  static Future<Order> fetchWooOrderById({required String orderId}) async {
    final Uri url = Uri.parse('$baseUrl/wp-json/wc/v3/orders/$orderId');

    try {
      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        // assumes you already have Order.fromWooJson(...)
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
