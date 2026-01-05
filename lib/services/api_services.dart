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
  static const String baseUrl = 'https://stage.kakiso.com';
  static const String consumerKey =
      'ck_a821068196cf8a1153635a362fdec04d4e881051';
  static const String consumerSecret =
      'cs_389ffd5342045eb06ac641085e7885fc3f0db010';
  static const String appApiKey = '';

  // 1. PERFORMANCE: Reusing a single client for connection pooling
  static final http.Client _client = http.Client();

  // 2. PERFORMANCE: Memory cache for static resources
  static List<CategoryModel>? _cachedCategories;
  static List<BrandModel>? _cachedBrands;

  static String get _basicAuth =>
      'Basic ${base64Encode(utf8.encode('$consumerKey:$consumerSecret'))}';

  static Map<String, String> get _headers => {
    "Authorization": _basicAuth,
    "Content-Type": "application/json",
    "User-Agent": "KakisoResellerApp/1.0",
    "Connection": "keep-alive",
  };

  // ---------------------------------------------------------------------------
  // Product / Category helpers
  // ---------------------------------------------------------------------------

  static Future<List<CategoryModel>> fetchCategories() async {
    if (_cachedCategories != null) return _cachedCategories!;

    final Uri url = Uri.parse(
      '$baseUrl/wp-json/wc/v3/products/categories?per_page=50&hide_empty=true',
    );
    try {
      final response = await _client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _cachedCategories = data
            .map((json) => CategoryModel.fromJson(json))
            .toList();
        return _cachedCategories!;
      }
      throw Exception('Category Error: ${response.statusCode}');
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
    List<int>? brandIds, // <--- 1. ADD THIS LINE
  }) async {
    final buffer = StringBuffer(
      '$baseUrl/wp-json/wc/v3/products?status=publish',
    );
    buffer.write('&per_page=$perPage&page=$page&orderby=$orderBy&order=$order');
    if (minPrice != null) buffer.write('&min_price=${minPrice.toInt()}');
    if (maxPrice != null) buffer.write('&max_price=${maxPrice.toInt()}');
    if (brandIds != null && brandIds.isNotEmpty) {
      buffer.write('&brand=${brandIds.join(',')}');
    }
    try {
      final response = await _client.get(
        Uri.parse(buffer.toString()),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ProductModel.fromJson(json)).toList();
      }
      throw Exception('Product Error: ${response.statusCode}');
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
      if (pageItems.length < perPage || page >= maxPages) break;
      page++;
    }
    return all;
  }

  static Future<List<ProductModel>> fetchProductsByCategory(
    int categoryId, {
    String orderBy = 'popularity',
    String order = 'desc',
    double? minPrice,
    double? maxPrice,
    List<int>? brandIds, // <--- 1. ADD THIS LINE
  }) async {
    final buffer = StringBuffer(
      '$baseUrl/wp-json/wc/v3/products?category=$categoryId&status=publish&per_page=20',
    );
    buffer.write('&orderby=$orderBy&order=$order');
    if (minPrice != null) buffer.write('&min_price=${minPrice.toInt()}');
    if (maxPrice != null) buffer.write('&max_price=${maxPrice.toInt()}');
    if (brandIds != null && brandIds.isNotEmpty) {
      buffer.write('&brand=${brandIds.join(',')}');
    }
    try {
      final response = await _client.get(
        Uri.parse(buffer.toString()),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ProductModel.fromJson(json)).toList();
      }
      throw Exception('Category Products Error');
    } catch (e) {
      throw Exception('Error fetching products by category: $e');
    }
  }

  static Future<ProductModel> fetchProductById(int id) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/wp-json/wc/v3/products/$id'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        return ProductModel.fromJson(json.decode(response.body));
      }
      throw Exception('Product Detail Error: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error fetching product: $e');
    }
  }

  static Future<ProductModel?> fetchProductByIdSafe(String id) async {
    final int? pid = int.tryParse(id);
    if (pid == null) return null;
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/wp-json/wc/v3/products/$pid'),
        headers: _headers,
      );
      return response.statusCode == 200
          ? ProductModel.fromJson(json.decode(response.body))
          : null;
    } catch (e) {
      return null;
    }
  }

  static Future<List<ProductModel>> fetchProductsBySku(String sku) async {
    try {
      final response = await _client.get(
        Uri.parse(
          '$baseUrl/wp-json/wc/v3/products?sku=${Uri.encodeQueryComponent(sku)}',
        ),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ProductModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<ProductModel>> fetchTopSellingProducts() async {
    final Uri url = Uri.parse(
      '$baseUrl/wp-json/wc/v3/products?per_page=10&status=publish&orderby=popularity',
    );
    try {
      final response = await _client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ProductModel.fromJson(json)).toList();
      }
      throw Exception('Top Products Error');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  static Future<List<ProductModel>> fetchNewestProducts() async {
    final Uri url = Uri.parse(
      '$baseUrl/wp-json/wc/v3/products?per_page=10&status=publish&orderby=date',
    );
    try {
      final response = await _client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ProductModel.fromJson(json)).toList();
      }
      throw Exception('Newest Products Error');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  static Future<List<ProductModel>> fetchTrendingProducts() =>
      fetchTopSellingProducts();

  static Future<List<BrandModel>> fetchBrands() async {
    if (_cachedBrands != null) return _cachedBrands!;
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/wp-json/wc/v3/products/brands?per_page=100'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _cachedBrands = data.map((json) => BrandModel.fromJson(json)).toList();
        return _cachedBrands!;
      }
      throw Exception('Brands Error');
    } catch (e) {
      throw Exception('Error fetching brands: $e');
    }
  }

  static Future<List<ProductModel>> searchProducts(String query) async {
    final Uri url = Uri.parse(
      '$baseUrl/wp-json/wc/v3/products?search=${Uri.encodeQueryComponent(query)}&status=publish&per_page=20',
    );
    try {
      final response = await _client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ProductModel.fromJson(json)).toList();
      }
      throw Exception('Search Error');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  static Future<XFile> downloadImageAsFile(String imageUrl) async {
    final response = await _client.get(Uri.parse(imageUrl));
    if (response.statusCode != 200) throw Exception('Image download failed');
    final tempDir = await getTemporaryDirectory();
    final file = File(
      "${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg",
    );
    await file.writeAsBytes(response.bodyBytes);
    return XFile(file.path);
  }

  static Future<String?> ensureWooCustomer({
    required String email,
    required String name,
  }) async {
    final String trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) return null;
    try {
      final findResp = await _client.get(
        Uri.parse(
          '$baseUrl/wp-json/wc/v3/customers?email=${Uri.encodeQueryComponent(trimmedEmail)}',
        ),
        headers: _headers,
      );
      if (findResp.statusCode == 200) {
        final List list = json.decode(findResp.body);
        if (list.isNotEmpty) return list.first['id'].toString();
      }
      final createResp = await _client.post(
        Uri.parse('$baseUrl/wp-json/wc/v3/customers'),
        headers: _headers,
        body: jsonEncode({
          'email': trimmedEmail,
          'first_name': name.trim().isNotEmpty
              ? name.trim()
              : trimmedEmail.split('@').first,
          'username': trimmedEmail,
        }),
      );
      if (createResp.statusCode == 201 || createResp.statusCode == 200) {
        return json.decode(createResp.body)['id'].toString();
      }
    } catch (e) {}
    return null;
  }

  static Future<void> updateBusinessDetails({
    String? userId,
    required Map<String, dynamic> data,
  }) async {
    final int? customerId = int.tryParse((userId ?? '').trim());
    if (customerId == null || customerId <= 0) return;

    final String fullName = (data["ownerName"] ?? "").toString().trim();
    final parts = fullName.split(" ");
    final fName = parts.isNotEmpty ? parts[0] : "";
    final lName = parts.length > 1 ? parts.sublist(1).join(" ") : "";

    final Map<String, dynamic> payload = {
      "first_name": fName,
      "last_name": lName,
      "email": data["email"],
      "billing": {
        "first_name": fName,
        "last_name": lName,
        "company": data["businessName"] ?? "",
        "address_1": data["addressLine1"] ?? "",
        "city": data["city"] ?? "",
        "state": data["state"] ?? "",
        "postcode": data["pincode"] ?? "",
        "country": data["country"] ?? "IN",
        "email": data["email"] ?? "",
        "phone": data["phone"] ?? "",
      },
      "meta_data": [
        {"key": "kakiso_whatsapp", "value": data["whatsapp"]},
        {"key": "kakiso_gstin", "value": data["gstin"]},
        {
          "key": "reseller_store_store_name",
          "value": data["businessName"] ?? "",
        },
      ],
    };
    await _client.put(
      Uri.parse('$baseUrl/wp-json/wc/v3/customers/$customerId'),
      headers: _headers,
      body: jsonEncode(payload),
    );
  }

  static Future<void> requestPasswordReset(String email) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/wp-json/kakiso/v1/password-reset'),
      headers: {
        "Content-Type": "application/json",
        "User-Agent": "KakisoResellerApp/1.0",
      },
      body: jsonEncode({'email': email.trim()}),
    );
    if (response.statusCode != 200) throw Exception('Reset failed');
  }

  static Future<Map<String, dynamic>?> fetchBusinessDetails({
    required String userId,
  }) async {
    final int? customerId = int.tryParse(userId.trim());
    if (customerId == null || customerId <= 0) return null;
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/wp-json/wc/v3/customers/$customerId'),
        headers: _headers,
      );
      if (response.statusCode != 200) return null;
      final Map<String, dynamic> data = json.decode(response.body);
      final billing = data['billing'] ?? {};
      return {
        "businessName": billing['company'] ?? '',
        "ownerName": "${data['first_name']} ${data['last_name']}".trim(),
        "phone": billing['phone'] ?? '',
        "email": data['email'] ?? '',
        "addressLine1": billing['address_1'] ?? '',
        "city": billing['city'] ?? '',
        "state": billing['state'] ?? '',
        "pincode": billing['postcode'] ?? '',
        "gstin": '', // Added missing key
      };
    } catch (e) {
      return null;
    }
  }

  // FIXED: Removed the invalid 'return' text and fixed the arrow syntax error
  static Future<void> updateResellerBusinessMeta({
    String? userId,
    required Map<String, dynamic> data,
  }) async {
    return;
  }

  static const int topRankingCategoryId = 513;
  static const int hotRankingCategoryId = 512;

  static Future<List<ProductModel>> fetchTopRankingProducts() async {
    final products = await fetchProductsByCategory(
      topRankingCategoryId,
      orderBy: 'menu_order',
      order: 'asc',
    );
    return products.isEmpty ? fetchTopSellingProducts() : products;
  }

  static Future<List<ProductModel>> fetchHotRankingProducts() async {
    final products = await fetchProductsByCategory(
      hotRankingCategoryId,
      orderBy: 'menu_order',
      order: 'asc',
    );
    return products.isEmpty ? fetchTopSellingProducts() : products;
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
    final payload = {
      'payment_method': paymentMethod,
      'payment_method_title': paymentMethodTitle,
      'set_paid': true,
      'customer_id': int.tryParse(userId ?? '0'),
      'billing': billing,
      'shipping': shipping,
      'line_items': lineItems,
      'meta_data': [
        {'key': 'razorpay_payment_id', 'value': paymentId},
      ],
      if (shippingLines != null) 'shipping_lines': shippingLines,
      if (feeLines != null) 'fee_lines': feeLines,
    };
    final response = await _client.post(
      Uri.parse('$baseUrl/wp-json/wc/v3/orders'),
      headers: _headers,
      body: jsonEncode(payload),
    );
    if (response.statusCode == 201 || response.statusCode == 200)
      return json.decode(response.body);
    throw Exception('Order Creation Failed');
  }

  static Future<List<Order>> fetchWooOrdersForCustomer({
    String? userId,
    String? userEmail,
  }) async {
    final List<Order> result = [];
    final Set<String> seenIds = {};
    final futures = <Future<http.Response>>[];

    if (userId != null && userId.trim().isNotEmpty) {
      futures.add(
        _client.get(
          Uri.parse(
            '$baseUrl/wp-json/wc/v3/orders?customer=${userId.trim()}&per_page=50',
          ),
          headers: _headers,
        ),
      );
    }
    if (userEmail != null && userEmail.trim().isNotEmpty) {
      futures.add(
        _client.get(
          Uri.parse(
            '$baseUrl/wp-json/wc/v3/orders?search=${Uri.encodeQueryComponent(userEmail.trim())}&per_page=50',
          ),
          headers: _headers,
        ),
      );
    }

    final responses = await Future.wait(futures);
    for (var resp in responses) {
      if (resp.statusCode == 200) {
        for (var raw in json.decode(resp.body)) {
          final order = Order.fromWooJson(raw);
          if (!seenIds.contains(order.id)) {
            seenIds.add(order.id);
            result.add(order);
          }
        }
      }
    }
    return result..sort((a, b) => b.id.compareTo(a.id));
  }

  static Future<Order> fetchWooOrderById({required String orderId}) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/wp-json/wc/v3/orders/$orderId'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return Order.fromWooJson(json.decode(response.body));
    }
    throw Exception('Order Fetch Error');
  }

  static Future<void> trackProductView({
    required String userId,
    required int productId,
  }) async {
    try {
      final Uri url = Uri.parse('$baseUrl/wp-json/kakiso/v1/track-view');
      await _client.post(
        url,
        headers: _headers,
        body: jsonEncode({
          'user_id': userId,
          'product_id': productId,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
    } catch (e) {
      // Silently fail so it doesn't interrupt the user experience
      print("Tracking error: $e");
    }
  }
}
