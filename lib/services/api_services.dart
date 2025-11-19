// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kakiso_reseller_app/models/brand.dart';
import 'package:kakiso_reseller_app/models/categories.dart';
import 'package:kakiso_reseller_app/models/product.dart'; // <--- 1. IMPORT THE PRODUCT MODEL

class ApiService {
  // Your Domain
  static const String baseUrl = 'https://prod-kakiso.smitpatadiya.me';

  // Your Keys (Updated from your snippet)
  static const String consumerKey =
      'ck_2379795496deebd9ab611ce3e4e54f90ebe9d289';
  static const String consumerSecret =
      'cs_5dc571e56332bd0eb6effd7b318f81bb8c6347c7';

  // --- EXISTING: FETCH CATEGORIES ---
  static Future<List<CategoryModel>> fetchCategories() async {
    final Uri url = Uri.parse(
      '$baseUrl/wp-json/wc/v3/products/categories?consumer_key=$consumerKey&consumer_secret=$consumerSecret&per_page=50&hide_empty=true',
    );

    print("--------------------------------------------------");
    print("1. Fetching Categories: $url");
    print("--------------------------------------------------");

    try {
      final response = await http.get(
        url,
        headers: {
          "Accept": "application/json",
          "User-Agent": "KakisoResellerApp/1.0",
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => CategoryModel.fromJson(json)).toList();
      } else {
        throw Exception(
          'Category Error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print("!!! CATEGORY ERROR !!!: $e");
      throw Exception('Error: $e');
    }
  }

  // --- NEW: FETCH PRODUCTS (Add this function) ---
  static Future<List<ProductModel>> fetchProducts() async {
    // 1. Use a clean URL (Keys go in headers for security)
    final Uri url = Uri.parse(
      '$baseUrl/wp-json/wc/v3/products?per_page=20&status=publish',
    );

    // 2. Create Basic Auth Header
    String basicAuth =
        'Basic ' + base64Encode(utf8.encode('$consumerKey:$consumerSecret'));

    print("--------------------------------------------------");
    print("2. Fetching Products: $url");
    print("--------------------------------------------------");

    try {
      final response = await http.get(
        url,
        headers: {
          // Send keys in Header to avoid 403 errors on Products endpoint
          "Authorization": basicAuth,
          "Content-Type": "application/json",
          "User-Agent": "KakisoResellerApp/1.0",
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        // Map JSON to ProductModel
        return data.map((json) => ProductModel.fromJson(json)).toList();
      } else {
        print('Product Error Body: ${response.body}');
        throw Exception('Product Error: ${response.statusCode}');
      }
    } catch (e) {
      print("!!! PRODUCT ERROR !!!: $e");
      throw Exception('Error: $e');
    }
  }
  // ... inside class ApiService ...

  // --- NEW: FETCH TOP SELLING PRODUCTS ---
  static Future<List<ProductModel>> fetchTopSellingProducts() async {
    final Uri url = Uri.parse(
      // 'orderby=popularity' gets the items with the most sales
      '$baseUrl/wp-json/wc/v3/products?per_page=10&status=publish&orderby=popularity',
    );

    String basicAuth =
        'Basic ' + base64Encode(utf8.encode('$consumerKey:$consumerSecret'));

    try {
      final response = await http.get(
        url,
        headers: {
          "Authorization": basicAuth,
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

  static Future<List<ProductModel>> fetchNewestProducts() async {
    final Uri url = Uri.parse(
      // 'orderby=date' sorts by newest first
      '$baseUrl/wp-json/wc/v3/products?per_page=10&status=publish&orderby=date',
    );

    String basicAuth =
        'Basic ' + base64Encode(utf8.encode('$consumerKey:$consumerSecret'));

    try {
      final response = await http.get(
        url,
        headers: {
          "Authorization": basicAuth,
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

  static Future<List<ProductModel>> fetchTrendingProducts() async {
    // We use 'orderby=popularity' to define "Trending"
    final Uri url = Uri.parse(
      '$baseUrl/wp-json/wc/v3/products?per_page=10&status=publish&orderby=popularity',
    );

    String basicAuth =
        'Basic ' + base64Encode(utf8.encode('$consumerKey:$consumerSecret'));

    try {
      final response = await http.get(
        url,
        headers: {
          "Authorization": basicAuth,
          "Content-Type": "application/json",
          "User-Agent": "KakisoResellerApp/1.0",
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ProductModel.fromJson(json)).toList();
      } else {
        throw Exception('Trending Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching trending products: $e');
    }
  }

  static Future<List<BrandModel>> fetchBrands() async {
    // NOTE: If you have a specific "Brands" plugin, change 'categories' to 'brands'
    final Uri url = Uri.parse(
      '$baseUrl/wp-json/wc/v3/products/categories?per_page=10&orderby=count&order=desc&hide_empty=true',
    );

    String basicAuth =
        'Basic ' + base64Encode(utf8.encode('$consumerKey:$consumerSecret'));

    try {
      final response = await http.get(
        url,
        headers: {
          "Authorization": basicAuth,
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
}
