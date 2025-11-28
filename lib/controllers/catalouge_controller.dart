// lib/controllers/catalouge_controller.dart

import 'dart:convert';
import 'dart:math';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kakiso_reseller_app/models/product.dart';

/// Model for a single catalogue.
class CatalogueModel {
  final String id;
  String name;
  String description;
  DateTime createdAt;
  List<ProductModel> products;

  CatalogueModel({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.products,
  });

  /// JSON serialization – used for local persistence.
  factory CatalogueModel.fromJson(Map<String, dynamic> json) {
    return CatalogueModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      products: (json['products'] as List<dynamic>? ?? [])
          .map((p) => ProductModel.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'products': products.map((p) => p.toJson()).toList(),
    };
  }
}

class CatalogueController extends GetxController {
  /// All catalogues for this device / user.
  final RxList<CatalogueModel> myCatalogues = <CatalogueModel>[].obs;

  static const _prefsKey = 'kakiso_catalogues_v1';

  // ---------------------------------------------------------------------------
  // LIFECYCLE
  // ---------------------------------------------------------------------------

  @override
  void onInit() {
    super.onInit();
    _loadFromStorage();
  }

  // ---------------------------------------------------------------------------
  // PUBLIC API – used by your UI
  // ---------------------------------------------------------------------------

  CatalogueModel? getById(String id) {
    try {
      return myCatalogues.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Create a new empty catalogue
  void createCatalogue(String name, String description) {
    final id = _generateId();
    final catalogue = CatalogueModel(
      id: id,
      name: name,
      description: description,
      createdAt: DateTime.now(),
      products: [],
    );

    myCatalogues.add(catalogue);
    myCatalogues.refresh();
    _saveToStorage();
  }

  /// Delete an entire catalogue
  void deleteCatalogue(String id) {
    myCatalogues.removeWhere((c) => c.id == id);
    myCatalogues.refresh();
    _saveToStorage();
  }

  /// Add a product to a specific catalogue (if not already present)
  void addProductToCatalogue(String catalogueId, ProductModel product) {
    final index = myCatalogues.indexWhere((c) => c.id == catalogueId);
    if (index == -1) return;

    final cat = myCatalogues[index];

    final alreadyExists = cat.products.any(
      (p) => p.id.toString() == product.id.toString(),
    );
    if (alreadyExists) {
      // You already handled snackbar in UI if you want; so just return
      return;
    }

    cat.products.add(product);
    myCatalogues[index] = CatalogueModel(
      id: cat.id,
      name: cat.name,
      description: cat.description,
      createdAt: cat.createdAt,
      products: List<ProductModel>.from(cat.products),
    );

    myCatalogues.refresh();
    _saveToStorage();
  }

  /// Remove a product from a catalogue by productId
  void removeProductFromCatalogue(String catalogueId, String productId) {
    final index = myCatalogues.indexWhere((c) => c.id == catalogueId);
    if (index == -1) return;

    final cat = myCatalogues[index];

    cat.products.removeWhere((p) => p.id.toString() == productId.toString());

    myCatalogues[index] = CatalogueModel(
      id: cat.id,
      name: cat.name,
      description: cat.description,
      createdAt: cat.createdAt,
      products: List<ProductModel>.from(cat.products),
    );

    myCatalogues.refresh();
    _saveToStorage();
  }

  // ---------------------------------------------------------------------------
  // PERSISTENCE
  // ---------------------------------------------------------------------------

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_prefsKey);
      if (jsonString == null || jsonString.isEmpty) return;

      final List<dynamic> decoded = jsonDecode(jsonString) as List<dynamic>;
      final loaded = decoded
          .map((e) => CatalogueModel.fromJson(e as Map<String, dynamic>))
          .toList();

      myCatalogues.assignAll(loaded);
      myCatalogues.refresh();
    } catch (e) {
      // If anything goes wrong, don't crash – just start fresh
      // (You can add debugPrint here if you want)
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> list = myCatalogues
          .map((c) => c.toJson())
          .toList();
      final jsonString = jsonEncode(list);
      await prefs.setString(_prefsKey, jsonString);
    } catch (e) {
      // ignore for now or log
    }
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  String _generateId() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final rand = Random().nextInt(999999);
    return 'cat_${ts}_$rand';
  }
}
