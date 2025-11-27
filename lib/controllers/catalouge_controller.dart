import 'dart:convert';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kakiso_reseller_app/models/product.dart';

class CatalogueModel {
  final String id;
  final String name;
  final String description;
  final RxList<ProductModel> products; // observable
  final DateTime createdAt;

  CatalogueModel({
    required this.id,
    required this.name,
    required this.description,
    List<ProductModel>? products,
    DateTime? createdAt,
  }) : products = (products ?? <ProductModel>[]).obs,
       createdAt = createdAt ?? DateTime.now();

  // ---- SERIALIZATION HELPERS ----

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      // Convert each ProductModel to json
      'products': products.map((p) => p.toJson()).toList(),
    };
  }

  factory CatalogueModel.fromJson(Map<String, dynamic> json) {
    return CatalogueModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      products: (json['products'] as List<dynamic>? ?? [])
          .map((p) => ProductModel.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CatalogueController extends GetxController {
  static const String _storageKey = 'my_catalogues_v1';

  final RxList<CatalogueModel> myCatalogues = <CatalogueModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadFromStorage();
  }

  // ---- PUBLIC API ----

  void createCatalogue(String name, String description) {
    final newCat = CatalogueModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
    );
    myCatalogues.add(newCat);
    myCatalogues.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _saveToStorage();
  }

  void deleteCatalogue(String id) {
    myCatalogues.removeWhere((c) => c.id == id);
    _saveToStorage();
  }

  CatalogueModel? getById(String id) {
    try {
      return myCatalogues.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  void addProductToCatalogue(String catalogId, ProductModel product) {
    final cat = getById(catalogId);
    if (cat == null) return;

    final alreadyExists = cat.products.any(
      (p) => p.id == product.id,
    ); // assuming ProductModel has id

    if (!alreadyExists) {
      cat.products.add(product);
      Get.snackbar("Added", "Added to ${cat.name}");
      _saveToStorage();
    } else {
      Get.snackbar("Info", "Product already in ${cat.name}");
    }
  }

  void removeProductFromCatalogue(String catalogId, String productId) {
    final cat = getById(catalogId);
    if (cat == null) return;
    cat.products.removeWhere((p) => p.id == productId);
    _saveToStorage();
  }

  // ---- PERSISTENCE ----

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Convert entire list to json string
      final List<Map<String, dynamic>> raw = myCatalogues
          .map((c) => c.toJson())
          .toList();
      final jsonStr = jsonEncode(raw);
      await prefs.setString(_storageKey, jsonStr);
    } catch (e) {
      // optional: log error
      // debugPrint("Error saving catalogues: $e");
    }
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);
      if (jsonStr == null || jsonStr.isEmpty) return;

      final List<dynamic> decoded = jsonDecode(jsonStr);
      final List<CatalogueModel> loaded = decoded
          .map((c) => CatalogueModel.fromJson(c as Map<String, dynamic>))
          .toList();

      myCatalogues.assignAll(loaded);
      myCatalogues.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      // optional: log error and ignore
      // debugPrint("Error loading catalogues: $e");
    }
  }
}
