// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kakiso_reseller_app/models/categories.dart';

class ApiService {
  // Your Domain
  static const String baseUrl = 'https://prod-kakiso.smitpatadiya.me';

  // Your Keys
  static const String consumerKey =
      'ck_2379795496deebd9ab611ce3e4e54f90ebe9d289';
  static const String consumerSecret =
      'cs_5dc571e56332bd0eb6effd7b318f81bb8c6347c7';

  static Future<List<CategoryModel>> fetchCategories() async {
    // 1. Construct the URL with keys (Standard Debug Approach)
    final Uri url = Uri.parse(
      '$baseUrl/wp-json/wc/v3/products/categories?consumer_key=$consumerKey&consumer_secret=$consumerSecret&per_page=50&hide_empty=true',
    );

    print("--------------------------------------------------");
    print("1. Attempting to connect to: $url");
    print("--------------------------------------------------");

    try {
      // 2. Send Request with User-Agent
      final response = await http.get(
        url,
        headers: {
          "Accept": "application/json",
          // This tells the server "I am a valid app, not a bot"
          "User-Agent": "KakisoResellerApp/1.0",
        },
      );

      print("2. Response Status Code: ${response.statusCode}");
      print(
        "3. Response Body (Server Message): ${response.body}",
      ); // <--- THIS IS THE IMPORTANT PART
      print("--------------------------------------------------");

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => CategoryModel.fromJson(json)).toList();
      } else {
        throw Exception(
          'Server Error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print("!!! CONNECTION CRASH !!!: $e");
      throw Exception('Error: $e');
    }
  }
}
