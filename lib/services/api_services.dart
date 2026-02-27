// lib/services/api_services.dart

import 'dart:async'; // Added for Completer
import 'dart:convert';
import 'dart:io'; // Added for SocketException
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_cache_interceptor_hive_store/dio_cache_interceptor_hive_store.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

// Import your models
import 'package:kakiso_reseller_app/models/brand.dart';
import 'package:kakiso_reseller_app/models/categories.dart';
import 'package:kakiso_reseller_app/models/order.dart';
import 'package:kakiso_reseller_app/models/product.dart';

// --- CUSTOM EXCEPTION CLASS ---
class KakisoApiException implements Exception {
  final String message;
  final int? statusCode;

  KakisoApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

// --- TOP LEVEL PARSER FUNCTIONS ---
// Wrapped in try-catch to prevent Isolate crashes on bad JSON
List<CategoryModel> _parseCategories(dynamic data) {
  try {
    return (data as List).map((json) => CategoryModel.fromJson(json)).toList();
  } catch (e) {
    debugPrint("Parse Error (Categories): $e");
    return [];
  }
}

List<ProductModel> _parseProducts(dynamic data) {
  try {
    return (data as List).map((json) => ProductModel.fromJson(json)).toList();
  } catch (e) {
    debugPrint("Parse Error (Products): $e");
    return [];
  }
}

List<BrandModel> _parseBrands(dynamic data) {
  try {
    return (data as List).map((json) => BrandModel.fromJson(json)).toList();
  } catch (e) {
    debugPrint("Parse Error (Brands): $e");
    return [];
  }
}

List<Order> _parseOrders(dynamic data) {
  try {
    return (data as List).map((json) => Order.fromWooJson(json)).toList();
  } catch (e) {
    debugPrint("Parse Error (Orders): $e");
    return [];
  }
}

class ApiService {
  // --- 1. SINGLETON PATTERN ---
  static final ApiService _instance = ApiService._internal();

  factory ApiService() => _instance;

  late final Dio _dio;
  // Completer prevents multiple inits running at the same time
  Completer<void>? _initCompleter;

  ApiService._internal();

  // --- 2. INITIALIZATION ---
  Future<void> init() async {
    if (_initCompleter != null) {
      return _initCompleter!.future;
    }

    _initCompleter = Completer<void>();

    try {
      // Load environment variables
      await dotenv.load(fileName: "assets/.env");

      final String baseUrl =
          dotenv.env['BASE_URL'] ?? 'https://stage.kakiso.com';
      final String consumerKey = dotenv.env['CONSUMER_KEY'] ?? '';
      final String consumerSecret = dotenv.env['CONSUMER_SECRET'] ?? '';

      final dir = await getTemporaryDirectory();
      final cacheStore = HiveCacheStore(
        dir.path,
        hiveBoxName: "kakiso_api_cache_v4_opt", // Bumped version for new logic
      );

      final cacheOptions = CacheOptions(
        store: cacheStore,
        policy: CachePolicy.forceCache,
        hitCacheOnErrorExcept: [401, 403, 500],
        maxStale: const Duration(days: 7), // Increased for offline support
        priority: CachePriority.normal,
      );

      _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          // Increased timeouts for slow networks
          connectTimeout: const Duration(seconds: 45),
          receiveTimeout: const Duration(seconds: 45),
          headers: {
            "Authorization":
                'Basic ${base64Encode(utf8.encode('$consumerKey:$consumerSecret'))}',
            "Content-Type": "application/json",
            "User-Agent": "KakisoResellerApp/2.2",
          },
        ),
      );

      _dio.interceptors.add(DioCacheInterceptor(options: cacheOptions));

      if (kDebugMode) {
        _dio.interceptors.add(LogInterceptor(responseBody: false));
      }

      _initCompleter!.complete();
    } catch (e) {
      _initCompleter!.completeError(e);
      _initCompleter = null; // Reset on failure so we can try again
      rethrow;
    }
  }

  Future<Dio> get _client async {
    if (_initCompleter == null) await init();
    await _initCompleter!.future;
    return _dio;
  }

  // Helper for error handling
  KakisoApiException _handleError(dynamic error) {
    if (error is DioException) {
      if (error.error is SocketException ||
          error.type == DioExceptionType.connectionTimeout) {
        return KakisoApiException('Slow or No Internet Connection');
      }
      if (error.response?.statusCode == 401) {
        return KakisoApiException(
          'Unauthorized. Please login again.',
          statusCode: 401,
        );
      }
      return KakisoApiException(
        error.message ?? 'Server Error: ${error.response?.statusCode}',
        statusCode: error.response?.statusCode,
      );
    }
    return KakisoApiException(error.toString());
  }

  // --- 3. IMAGE OPTIMIZATION (NEW) ---
  /// Converts heavy WordPress images to lightweight WebP on the fly.
  /// Use this in your UI: CachedNetworkImage(imageUrl: ApiService.getOptimizedImageUrl(url))
  static String getOptimizedImageUrl(String originalUrl, {int width = 400}) {
    if (originalUrl.isEmpty) return "";
    // Using 'wsrv.nl' (free global CDN) to resize and compress.
    // This is safe to use and very fast for mobile apps.
    final encoded = Uri.encodeComponent(originalUrl);
    return "https://wsrv.nl/?url=$encoded&w=$width&q=75&output=webp";
  }

  // --- 4. CATEGORIES ---
  Future<List<CategoryModel>> fetchCategories() async {
    final dio = await _client;
    try {
      final response = await dio.get(
        '/wp-json/wc/v3/products/categories',
        queryParameters: {'per_page': 50, 'hide_empty': true},
      );
      return compute(_parseCategories, response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // --- 5. PRODUCTS ---
  Future<List<ProductModel>> fetchProducts({
    int page = 1,
    int perPage = 20,
    String orderBy = 'date',
    String order = 'desc',
    double? minPrice,
    double? maxPrice,
    List<int>? brandIds,
  }) async {
    final dio = await _client;
    final Map<String, dynamic> params = {
      'status': 'publish',
      'per_page': perPage,
      'page': page,
      'orderby': orderBy,
      'order': order,
    };

    if (minPrice != null) params['min_price'] = minPrice.toInt();
    if (maxPrice != null) params['max_price'] = maxPrice.toInt();
    if (brandIds != null && brandIds.isNotEmpty) {
      params['brand'] = brandIds.join(',');
    }

    try {
      final options = page == 1
          ? Options(extra: {'cache_policy': CachePolicy.refresh})
          : null;

      final response = await dio.get(
        '/wp-json/wc/v3/products',
        queryParameters: params,
        options: options,
      );

      return compute(_parseProducts, response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // FIXED: Safer pagination logic with delay to prevent choking
  Future<List<ProductModel>> fetchAllProductsPaginated({
    String orderBy = 'date',
    String order = 'desc',
    double? minPrice,
    double? maxPrice,
    int perPage = 50,
    int maxPages = 10,
  }) async {
    final List<ProductModel> all = [];
    int page = 1;

    try {
      while (page <= maxPages) {
        final pageItems = await fetchProducts(
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
        // Small delay to be kind to the server
        await Future.delayed(const Duration(milliseconds: 150));
      }
      return all;
    } catch (e) {
      return all;
    }
  }

  // Find the fetchProductsByCategory method and update it to this:

  Future<List<ProductModel>> fetchProductsByCategory(
    int categoryId, {
    int page = 1, // <--- 1. ADD THIS PARAMETER
    String orderBy = 'popularity',
    String order = 'desc',
    double? minPrice,
    double? maxPrice,
    List<int>? brandIds,
  }) async {
    final dio = await _client;
    final Map<String, dynamic> params = {
      'category': categoryId,
      'status': 'publish',
      'per_page': 20,
      'page': page, // <--- 2. PASS IT TO WORDPRESS HERE
      'orderby': orderBy,
      'order': order,
    };
    if (minPrice != null) params['min_price'] = minPrice.toInt();
    if (maxPrice != null) params['max_price'] = maxPrice.toInt();
    if (brandIds != null && brandIds.isNotEmpty) {
      params['brand'] = brandIds.join(',');
    }

    try {
      final response = await dio.get(
        '/wp-json/wc/v3/products',
        queryParameters: params,
      );
      return compute(_parseProducts, response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ProductModel> fetchProductById(int id) async {
    final dio = await _client;
    try {
      final response = await dio.get('/wp-json/wc/v3/products/$id');
      return ProductModel.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ProductModel?> fetchProductByIdSafe(String id) async {
    final int? pid = int.tryParse(id);
    if (pid == null) return null;
    final dio = await _client;
    try {
      final response = await dio.get('/wp-json/wc/v3/products/$pid');
      return ProductModel.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }

  // --- 6. OPTIMIZED SEARCH (SEQUENTIAL) ---
  Future<List<ProductModel>> fetchProductsByUniqueCode(String code) async {
    final String cleanCode = code.trim();
    if (cleanCode.isEmpty) return [];

    final dio = await _client;

    try {
      // 1. Try SKU first (Fastest/Most Exact)
      final skuResponse = await dio.get(
        '/wp-json/wc/v3/products',
        queryParameters: {'sku': cleanCode},
      );
      if ((skuResponse.data as List).isNotEmpty) {
        return compute(_parseProducts, skuResponse.data);
      }

      // 2. Try Meta Key (Unique Code)
      final metaResponse = await dio.get(
        '/wp-json/wc/v3/products',
        queryParameters: {
          'filter[meta_key]': '_unique_product_code',
          'filter[meta_value]': cleanCode,
          'status': 'publish',
        },
      );
      if ((metaResponse.data as List).isNotEmpty) {
        return compute(_parseProducts, metaResponse.data);
      }

      // 3. Fallback to broad search (Slowest)
      final searchResponse = await dio.get(
        '/wp-json/wc/v3/products',
        queryParameters: {'search': cleanCode, 'status': 'publish'},
      );
      return compute(_parseProducts, searchResponse.data);
    } catch (e) {
      return [];
    }
  }

  Future<List<ProductModel>> searchProducts(String query) async {
    final dio = await _client;
    try {
      final response = await dio.get(
        '/wp-json/wc/v3/products',
        queryParameters: {'search': query, 'status': 'publish', 'per_page': 20},
      );
      return compute(_parseProducts, response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // --- 7. RANKING & LISTS ---
  Future<List<ProductModel>> fetchTopSellingProducts() async {
    final dio = await _client;
    try {
      final response = await dio.get(
        '/wp-json/wc/v3/products',
        queryParameters: {
          'per_page': 10,
          'status': 'publish',
          'orderby': 'popularity',
        },
      );
      return compute(_parseProducts, response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<ProductModel>> fetchNewestProducts() async {
    final dio = await _client;
    try {
      final response = await dio.get(
        '/wp-json/wc/v3/products',
        queryParameters: {
          'per_page': 10,
          'status': 'publish',
          'orderby': 'date',
        },
      );
      return compute(_parseProducts, response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<ProductModel>> fetchTrendingProducts() =>
      fetchTopSellingProducts();

  static const int topRankingCategoryId = 90;
  static const int hotRankingCategoryId = 91;

  Future<List<ProductModel>> fetchTopRankingProducts() async {
    final products = await fetchProductsByCategory(
      topRankingCategoryId,
      orderBy: 'menu_order',
      order: 'asc',
    );
    return products.isEmpty ? fetchTopSellingProducts() : products;
  }

  Future<List<ProductModel>> fetchHotRankingProducts() async {
    final products = await fetchProductsByCategory(
      hotRankingCategoryId,
      orderBy: 'menu_order',
      order: 'asc',
    );
    return products.isEmpty ? fetchTopSellingProducts() : products;
  }

  // --- 8. BRANDS & MISC ---
  Future<List<BrandModel>> fetchBrands() async {
    final dio = await _client;
    try {
      final response = await dio.get(
        '/wp-json/wc/v3/products/brands',
        queryParameters: {'per_page': 100},
      );
      return compute(_parseBrands, response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // UPDATED: Robust download with retries for slow networks
  Future<XFile> downloadImageAsFile(String imageUrl) async {
    final dio = await _client;
    int retries = 3;

    while (retries > 0) {
      try {
        final tempDir = await getTemporaryDirectory();
        final savePath =
            "${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg";

        await dio.download(
          imageUrl,
          savePath,
          options: Options(
            // Extra long timeout for downloads
            receiveTimeout: const Duration(minutes: 2),
          ),
        );
        return XFile(savePath);
      } catch (e) {
        retries--;
        if (retries == 0) {
          throw KakisoApiException(
            'Failed to download image after 3 attempts. Check internet.',
          );
        }
        // Wait 2 seconds before retrying
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    throw KakisoApiException('Download failed');
  }

  // --- 9. USER & BUSINESS ---
  Future<String?> ensureWooCustomer({
    required String email,
    required String name,
  }) async {
    final String trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) return null;
    final dio = await _client;

    try {
      final findResp = await dio.get(
        '/wp-json/wc/v3/customers',
        queryParameters: {'email': trimmedEmail},
        options: Options(extra: {'cache_policy': CachePolicy.noCache}),
      );

      if ((findResp.data as List).isNotEmpty) {
        return findResp.data[0]['id'].toString();
      }

      final createResp = await dio.post(
        '/wp-json/wc/v3/customers',
        data: {
          'email': trimmedEmail,
          'first_name': name.trim().isNotEmpty
              ? name.trim()
              : trimmedEmail.split('@').first,
          'username': trimmedEmail,
        },
      );
      return createResp.data['id'].toString();
    } catch (e) {
      return null;
    }
  }

  Future<void> updateBusinessDetails({
    String? userId,
    required Map<String, dynamic> data,
  }) async {
    final int? customerId = int.tryParse((userId ?? '').trim());
    if (customerId == null || customerId <= 0) return;
    final dio = await _client;

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
        {"key": "reseller_store_name", "value": data["businessName"] ?? ""},
      ],
    };

    await dio.put('/wp-json/wc/v3/customers/$customerId', data: payload);
  }

  Future<Map<String, dynamic>?> fetchBusinessDetails({
    required String userId,
  }) async {
    final int? customerId = int.tryParse(userId.trim());
    if (customerId == null || customerId <= 0) return null;
    final dio = await _client;

    try {
      final response = await dio.get(
        '/wp-json/wc/v3/customers/$customerId',
        options: Options(extra: {'cache_policy': CachePolicy.noCache}),
      );
      final data = response.data;
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
        "gstin": '',
      };
    } catch (e) {
      return null;
    }
  }

  Future<void> requestPasswordReset(String email) async {
    final dio = await _client;
    try {
      await dio.post(
        '/wp-json/kakiso/v1/password-reset',
        data: {'email': email.trim()},
      );
    } catch (e) {
      throw KakisoApiException('Reset failed');
    }
  }

  // --- 10. ORDERS ---
  Future<Map<String, dynamic>> createWooOrder({
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
    final dio = await _client;
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

    try {
      final response = await dio.post('/wp-json/wc/v3/orders', data: payload);
      return response.data;
    } catch (e) {
      throw KakisoApiException('Order Creation Failed: ${e.toString()}');
    }
  }

  Future<List<Order>> fetchWooOrdersForCustomer({
    String? userId,
    String? userEmail,
  }) async {
    final dio = await _client;
    final futures = <Future<Response>>[];

    if (userId != null && userId.trim().isNotEmpty) {
      futures.add(
        dio.get(
          '/wp-json/wc/v3/orders',
          queryParameters: {'customer': userId.trim(), 'per_page': 50},
        ),
      );
    }
    if (userEmail != null && userEmail.trim().isNotEmpty) {
      futures.add(
        dio.get(
          '/wp-json/wc/v3/orders',
          queryParameters: {'search': userEmail.trim(), 'per_page': 50},
        ),
      );
    }

    try {
      final responses = await Future.wait(futures);
      final List<dynamic> combinedData = [];

      for (var resp in responses) {
        combinedData.addAll(resp.data);
      }

      List<Order> allOrders = await compute(_parseOrders, combinedData);

      // Cleaned up Deduplication:
      final Map<String, Order> uniqueMap = {
        for (var order in allOrders) order.id: order,
      };

      final result = uniqueMap.values.toList();
      result.sort((a, b) => b.id.compareTo(a.id));

      return result;
    } catch (e) {
      return [];
    }
  }

  Future<Order> fetchWooOrderById({required String orderId}) async {
    final dio = await _client;
    try {
      final response = await dio.get('/wp-json/wc/v3/orders/$orderId');
      return Order.fromWooJson(response.data);
    } catch (e) {
      throw KakisoApiException('Order Fetch Error');
    }
  }

  // --- 11. TRACKING ---
  Future<void> trackProductView({
    required String userId,
    required int productId,
  }) async {
    try {
      final dio = await _client;
      dio
          .post(
            '/wp-json/kakiso/v1/track-view',
            data: {
              'user_id': userId,
              'product_id': productId,
              'timestamp': DateTime.now().toIso8601String(),
            },
          )
          // ignore: body_might_complete_normally_catch_error
          .catchError((e) {
            // Silently catch errors so tracking never crashes app
          });
    } catch (e) {
      // Ignore
    }
  }

  static Future<void> updateResellerBusinessMeta({
    String? userId,
    required Map<String, dynamic> data,
  }) async {
    return;
  }
  // ===========================================================================
  // 12. CATALOG SYNC API — ALL POST ROUTES
  // ===========================================================================

  // ===========================================================================

  /// Fetch all catalogs from server
  Future<List<Map<String, dynamic>>?> fetchCatalogsFromServer({
    required String userId,
  }) async {
    final dio = await _client;
    try {
      debugPrint('CatalogAPI: GET /catalogs?user_id=$userId');
      final response = await dio.get(
        '/wp-json/kakiso/v1/catalogs',
        queryParameters: {
          'user_id': userId,
          '_t': DateTime.now().millisecondsSinceEpoch, // ← ADD THIS LINE
        },
        options: Options(extra: {'cache_policy': CachePolicy.noCache}),
      );
      final data = response.data;
      if (data is Map && data['success'] == true && data['catalogs'] is List) {
        final list = List<Map<String, dynamic>>.from(
          (data['catalogs'] as List).map((c) => Map<String, dynamic>.from(c)),
        );
        debugPrint('CatalogAPI: Fetched ${list.length} catalogs');
        return list;
      }
      return [];
    } catch (e) {
      debugPrint('CatalogAPI: fetch error: $e');
      return null;
    }
  }

  /// Create a catalog on server
  Future<bool> createCatalogOnServer({
    required String userId,
    required String catalogId,
    required String name,
    String desc = '',
    List<int> productIds = const [],
  }) async {
    final dio = await _client;
    try {
      debugPrint('CatalogAPI: POST /catalogs/create name=$name');
      final response = await dio.post(
        '/wp-json/kakiso/v1/catalogs/create',
        data: {
          'user_id': int.tryParse(userId) ?? userId,
          'catalog_id': catalogId,
          'name': name,
          'desc': desc,
          'product_ids': productIds,
          'source': 'app',
        },
      );
      final ok = response.data['success'] == true;
      debugPrint('CatalogAPI: create result=$ok');
      return ok;
    } catch (e) {
      debugPrint('CatalogAPI: create error: $e');
      return false;
    }
  }

  /// Update a catalog on server
  Future<bool> updateCatalogOnServer({
    required String userId,
    required String catalogId,
    required String action,
    int? productId,
    List<int>? productIds,
    String? name,
    String? desc,
  }) async {
    final dio = await _client;
    try {
      final Map<String, dynamic> payload = {
        'user_id': int.tryParse(userId) ?? userId,
        'catalog_id': catalogId,
        'action': action,
      };
      if (productId != null) payload['product_id'] = productId;
      if (productIds != null) payload['product_ids'] = productIds;
      if (name != null) payload['name'] = name;
      if (desc != null) payload['desc'] = desc;

      debugPrint(
        'CatalogAPI: POST /catalogs/update action=$action catalog=$catalogId',
      );
      final response = await dio.post(
        '/wp-json/kakiso/v1/catalogs/update',
        data: payload,
      );
      final ok = response.data['success'] == true;
      debugPrint('CatalogAPI: update result=$ok');
      return ok;
    } catch (e) {
      debugPrint('CatalogAPI: update error: $e');
      return false;
    }
  }

  /// Delete a catalog on server
  Future<bool> deleteCatalogOnServer({
    required String userId,
    required String catalogId,
  }) async {
    final dio = await _client;
    try {
      debugPrint('CatalogAPI: POST /catalogs/delete catalog=$catalogId');
      final response = await dio.post(
        '/wp-json/kakiso/v1/catalogs/delete',
        data: {
          'user_id': int.tryParse(userId) ?? userId,
          'catalog_id': catalogId,
        },
      );
      final ok = response.data['success'] == true;
      debugPrint('CatalogAPI: delete result=$ok');
      return ok;
    } catch (e) {
      debugPrint('CatalogAPI: delete error: $e');
      return false;
    }
  }

  /// Full sync — push all app catalogs to server
  Future<List<Map<String, dynamic>>?> syncCatalogsToServer({
    required String userId,
    required List<Map<String, dynamic>> catalogs,
  }) async {
    final dio = await _client;
    try {
      debugPrint('CatalogAPI: POST /catalogs/sync count=${catalogs.length}');
      final response = await dio.post(
        '/wp-json/kakiso/v1/catalogs/sync',
        data: {'user_id': int.tryParse(userId) ?? userId, 'catalogs': catalogs},
      );
      final data = response.data;
      if (data is Map && data['success'] == true && data['catalogs'] is List) {
        return List<Map<String, dynamic>>.from(
          (data['catalogs'] as List).map((c) => Map<String, dynamic>.from(c)),
        );
      }
      return null;
    } catch (e) {
      debugPrint('CatalogAPI: sync error: $e');
      return null;
    }
  }

  /// Batch fetch product details — single request for up to 200 products
  Future<List<ProductModel>?> batchFetchProducts({
    required List<int> productIds,
  }) async {
    if (productIds.isEmpty) return [];
    final dio = await _client;
    try {
      debugPrint(
        'CatalogAPI: POST /catalogs/products count=${productIds.length}',
      );
      final response = await dio.post(
        '/wp-json/kakiso/v1/catalogs/products',
        data: {'product_ids': productIds},
      );
      final data = response.data;
      if (data is Map && data['success'] == true && data['products'] is List) {
        final list = (data['products'] as List)
            .map((p) => ProductModel.fromJson(Map<String, dynamic>.from(p)))
            .toList();
        debugPrint('CatalogAPI: batch fetched ${list.length} products');
        return list;
      }
      return null;
    } catch (e) {
      debugPrint('CatalogAPI: batchFetch error: $e');
      return null;
    }
  }
  // ===========================================================================
  // 13. BUSINESS DETAILS API — Syncs with web dashboard's reseller_* meta keys
  // ===========================================================================
  // ADD these methods inside ApiService class, BEFORE the final closing }
  // ===========================================================================

  /// Fetch ALL business details from server (same data as web dashboard)
  Future<Map<String, dynamic>?> fetchFullBusinessDetails({
    required String userId,
  }) async {
    final dio = await _client;
    try {
      debugPrint('BusinessAPI: GET /business?user_id=$userId');
      final response = await dio.get(
        '/wp-json/kakiso/v1/business',
        queryParameters: {
          'user_id': userId,
          '_t': DateTime.now().millisecondsSinceEpoch,
        },
        options: Options(extra: {'cache_policy': CachePolicy.noCache}),
      );
      final data = response.data;
      if (data is Map && data['success'] == true) {
        debugPrint('BusinessAPI: Fetched business details');
        return Map<String, dynamic>.from(data);
      }
      return null;
    } catch (e) {
      debugPrint('BusinessAPI: fetch error: $e');
      return null;
    }
  }

  /// Save ALL business details to server (syncs with web dashboard)
  Future<bool> saveFullBusinessDetails({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    final dio = await _client;
    try {
      final payload = Map<String, dynamic>.from(data);
      payload['user_id'] = int.tryParse(userId) ?? userId;

      debugPrint('BusinessAPI: POST /business/save');
      final response = await dio.post(
        '/wp-json/kakiso/v1/business/save',
        data: payload,
      );
      final ok = response.data['success'] == true;
      debugPrint('BusinessAPI: save result=$ok');
      return ok;
    } catch (e) {
      debugPrint('BusinessAPI: save error: $e');
      return false;
    }
  }
}
