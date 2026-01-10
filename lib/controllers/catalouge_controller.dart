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

  // ---------------------------------------------------------------------------
  // 隼 ADDED: copyWith method to fix the error
  // ---------------------------------------------------------------------------
  CatalogueModel copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? createdAt,
    List<ProductModel>? products,
  }) {
    return CatalogueModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      products: products ?? this.products,
    );
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

  /// Handy getter for just the catalogue names (used in bottom sheets / dropdowns).
  List<String> get catalogueNames => myCatalogues
      .map((c) => (c.name.isEmpty ? 'Untitled Catalogue' : c.name))
      .toList();

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

  /// Create a new catalogue *and* add the given product to it.
  ///
  /// Used when user taps "Create New Catalogue" from product card.
  void createCatalogueAndAddProduct(
    String name,
    ProductModel product, {
    String description = '',
  }) {
    final id = _generateId();
    final catalogue = CatalogueModel(
      id: id,
      name: name,
      description: description,
      createdAt: DateTime.now(),
      products: [product],
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
      // Optional: Show a snackbar in UI if you like
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

  /// Convenience: Add product to an *existing* catalogue by its name.
  ///
  /// This is useful when your UI is only dealing with catalogue names.
  void addProductToExistingCatalogueByName(
    String catalogueName,
    ProductModel product,
  ) {
    try {
      final cat = myCatalogues.firstWhere((c) => c.name == catalogueName);
      addProductToCatalogue(cat.id, product);
    } catch (_) {
      // No catalogue with that name – do nothing (or you could create one).
    }
  }

  /// Backwards-compatible wrapper so you can call:
  ///   addProductToExistingCatalogue(catalogueName, product)
  void addProductToExistingCatalogue(
    String catalogueName,
    ProductModel product,
  ) {
    addProductToExistingCatalogueByName(catalogueName, product);
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
