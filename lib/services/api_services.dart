// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kakiso_reseller_app/models/brand.dart';
import 'package:kakiso_reseller_app/models/categories.dart';
import 'package:kakiso_reseller_app/models/product.dart';

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

  // --- 1. FETCH CATEGORIES ---
  static Future<List<CategoryModel>> fetchCategories() async {
    final Uri url = Uri.parse(
      '$baseUrl/wp-json/wc/v3/products/categories?per_page=50&hide_empty=true',
    );

    try {
      final response = await http.get(
        url,
        headers: {
          "Authorization": _basicAuth,
          "Content-Type": "application/json",
          "User-Agent": "KakisoResellerApp/1.0",
        },
      );

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

  // --- 2. FETCH ALL PRODUCTS ---
  static Future<List<ProductModel>> fetchProducts() async {
    final Uri url = Uri.parse(
      '$baseUrl/wp-json/wc/v3/products?per_page=20&status=publish',
    );

    try {
      final response = await http.get(
        url,
        headers: {
          "Authorization": _basicAuth,
          "Content-Type": "application/json",
          "User-Agent": "KakisoResellerApp/1.0",
        },
      );

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

  // --- 3. FETCH PRODUCTS BY CATEGORY (With Sort & Filter) ---
  static Future<List<ProductModel>> fetchProductsByCategory(
    int categoryId, {
    String orderBy = 'popularity', // date, price, popularity, rating
    String order = 'desc', // asc, desc
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
      final response = await http.get(
        url,
        headers: {
          "Authorization": _basicAuth,
          "Content-Type": "application/json",
          "User-Agent": "KakisoResellerApp/1.0",
        },
      );

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
      final response = await http.get(
        url,
        headers: {
          "Authorization": _basicAuth,
          "Content-Type": "application/json",
          "User-Agent": "KakisoResellerApp/1.0",
        },
      );

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
      final response = await http.get(
        url,
        headers: {
          "Authorization": _basicAuth,
          "Content-Type": "application/json",
          "User-Agent": "KakisoResellerApp/1.0",
        },
      );

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
      final response = await http.get(
        url,
        headers: {
          "Authorization": _basicAuth,
          "Content-Type": "application/json",
          "User-Agent": "KakisoResellerApp/1.0",
        },
      );

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

  // --- 8. FETCH BRANDS (Using Categories) ---
  static Future<List<BrandModel>> fetchBrands() async {
    final Uri url = Uri.parse(
      '$baseUrl/wp-json/wc/v3/products/categories?per_page=10&orderby=count&order=desc&hide_empty=true',
    );

    try {
      final response = await http.get(
        url,
        headers: {
          "Authorization": _basicAuth,
          "Content-Type": "application/json",
          "User-Agent": "KakisoResellerApp/1.0",
        },
      );

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
      final response = await http.get(
        url,
        headers: {
          "Authorization": _basicAuth,
          "Content-Type": "application/json",
          "User-Agent": "KakisoResellerApp/1.0",
        },
      );

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
}
