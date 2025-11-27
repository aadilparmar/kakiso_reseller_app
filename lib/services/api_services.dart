import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:kakiso_reseller_app/models/brand.dart';
import 'package:kakiso_reseller_app/models/categories.dart';
import 'package:kakiso_reseller_app/models/product.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ApiService {
  // Your Domain
  static const String baseUrl = 'https://prod-kakiso.smitpatadiya.me';

  // Your Keys
  static const String consumerKey =
      'ck_2379795496deebd9ab611ce3e4e54f90ebe9d289';
  static const String consumerSecret =
      'cs_5dc571e56332bd0eb6effd7b318f81bb8c6347c7';

  // Helper for Basic Auth Header
  static String get _basicAuth =>
      'Basic ' + base64Encode(utf8.encode('$consumerKey:$consumerSecret'));

  // Common headers
  static Map<String, String> get _headers => {
    "Authorization": _basicAuth,
    "Content-Type": "application/json",
    "User-Agent": "KakisoResellerApp/1.0",
  };

  // --- 1. FETCH CATEGORIES ---
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

  // --- 2. FETCH PRODUCTS (Single Page: Supports Pagination, Sort, Filter) ---
  static Future<List<ProductModel>> fetchProducts({
    int page = 1,
    int perPage = 20,
    String orderBy = 'date', // date, price, popularity, rating
    String order = 'desc', // asc, desc
    double? minPrice,
    double? maxPrice,
  }) async {
    // Build Query Parameters
    String queryParams = 'status=publish&per_page=$perPage&page=$page';

    // Add Sorting
    queryParams += '&orderby=$orderBy&order=$order';

    // Add Filtering
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

  // --- 2B. FETCH ALL PRODUCTS (MULTI-PAGE) ---
  /// Loops through WooCommerce pages and returns ALL products.
  /// Used in ProductPickerScreen so you can see the full catalogue.
  static Future<List<ProductModel>> fetchAllProductsPaginated({
    String orderBy = 'date',
    String order = 'desc',
    double? minPrice,
    double? maxPrice,
    int perPage = 50,
    int maxPages = 20, // safety cap
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

      if (pageItems.isEmpty) {
        break;
      }

      all.addAll(pageItems);

      // If we got less than perPage, it’s likely the last page
      if (pageItems.length < perPage) {
        break;
      }

      page++;

      if (page > maxPages) {
        // Avoid infinite loops if API misbehaves
        print(
          "ApiService.fetchAllProductsPaginated: Reached maxPages=$maxPages, stopping.",
        );
        break;
      }
    }

    return all;
  }

  // --- 3. FETCH PRODUCTS BY CATEGORY (With Sort & Filter) ---
  static Future<List<ProductModel>> fetchProductsByCategory(
    int categoryId, {
    String orderBy = 'popularity',
    String order = 'desc',
    double? minPrice,
    double? maxPrice,
  }) async {
    // Build Query
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

  // --- 4. FETCH SINGLE PRODUCT BY ID ---
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

  // --- 5. FETCH TOP SELLING ---
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

  // --- 6. FETCH NEWEST ---
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

  // --- 7. FETCH TRENDING ---
  static Future<List<ProductModel>> fetchTrendingProducts() async {
    return fetchTopSellingProducts();
  }

  // --- 8. FETCH BRANDS ---
  static Future<List<BrandModel>> fetchBrands() async {
    final Uri url = Uri.parse(
      '$baseUrl/wp-json/wc/v3/products/categories?per_page=10&orderby=count&order=desc&hide_empty=true',
    );

    try {
      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => BrandModel.fromJson(json)).toList();
      } else {
        throw Exception('Brands Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching brands: $e');
    }
  }

  // --- 9. SEARCH PRODUCTS ---
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

  // --- 10. DOWNLOAD IMAGE AS FILE (For WhatsApp catalogue sharing) ---
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
}
