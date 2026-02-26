// lib/controllers/catalouge_controller.dart
//
// UPDATED: Now syncs catalogs with WordPress database via REST API
// Local SharedPreferences is kept as offline cache/fallback.
// Web dashboard and app now share the SAME catalog data.

import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/services/api_services.dart';
import 'package:kakiso_reseller_app/services/session_service.dart';

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

  /// Convert to server format (product IDs only, not full objects)
  Map<String, dynamic> toServerJson() {
    return {
      'id': id,
      'name': name,
      'desc': description,
      'created': createdAt.toIso8601String(),
      'product_ids': products.map((p) => p.id).toList(),
    };
  }

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
  /// All catalogues for this user.
  final RxList<CatalogueModel> myCatalogues = <CatalogueModel>[].obs;

  /// Sync status observable (UI can show sync indicator)
  final RxBool isSyncing = false.obs;

  static const _prefsKey = 'kakiso_catalogues_v1';

  // Cache of product models we've already fetched (avoids re-fetching)
  final Map<int, ProductModel> _productCache = {};

  // ---------------------------------------------------------------------------
  // LIFECYCLE
  // ---------------------------------------------------------------------------

  @override
  void onInit() {
    super.onInit();
    _loadFromStorage(); // Load local first (instant UI)
    _syncFromServer(); // Then sync from server in background
  }

  // ---------------------------------------------------------------------------
  // PUBLIC API – used by your UI (unchanged method signatures!)
  // ---------------------------------------------------------------------------

  CatalogueModel? getById(String id) {
    try {
      return myCatalogues.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

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

    // Push to server in background
    _createOnServer(catalogue);
  }

  /// Create a new catalogue AND add a product to it
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

    // Push to server with product
    _createOnServer(catalogue);
  }

  /// Delete an entire catalogue
  void deleteCatalogue(String id) {
    myCatalogues.removeWhere((c) => c.id == id);
    myCatalogues.refresh();
    _saveToStorage();

    // Delete on server in background
    _deleteOnServer(id);
  }

  /// Add a product to a specific catalogue
  void addProductToCatalogue(String catalogueId, ProductModel product) {
    final index = myCatalogues.indexWhere((c) => c.id == catalogueId);
    if (index == -1) return;

    final cat = myCatalogues[index];
    final alreadyExists = cat.products.any(
      (p) => p.id.toString() == product.id.toString(),
    );
    if (alreadyExists) return;

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

    // Cache the product for future server syncs
    _productCache[product.id] = product;

    // Push to server
    _addProductOnServer(catalogueId, product.id);
  }

  void addProductToExistingCatalogueByName(
    String catalogueName,
    ProductModel product,
  ) {
    try {
      final cat = myCatalogues.firstWhere((c) => c.name == catalogueName);
      addProductToCatalogue(cat.id, product);
    } catch (_) {}
  }

  void addProductToExistingCatalogue(
    String catalogueName,
    ProductModel product,
  ) {
    addProductToExistingCatalogueByName(catalogueName, product);
  }

  /// Remove a product from a catalogue
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

    // Push to server
    _removeProductOnServer(catalogueId, int.tryParse(productId) ?? 0);
  }

  /// Force sync from server (can be called from UI pull-to-refresh)
  Future<void> refreshFromServer() async {
    await _syncFromServer();
  }

  // ---------------------------------------------------------------------------
  // SERVER SYNC — Background operations (never block UI)
  // ---------------------------------------------------------------------------

  Future<String?> _getUserId() async {
    final user = await SessionService.getUser();
    return user?.wooCustomerId.isNotEmpty == true
        ? user!.wooCustomerId
        : user?.userId;
  }

  /// Fetch catalogs from server and merge with local
  Future<void> _syncFromServer() async {
    try {
      isSyncing.value = true;
      final userId = await _getUserId();
      if (userId == null || userId.isEmpty) return;

      final serverCatalogs = await ApiService().fetchCatalogsFromServer(
        userId: userId,
      );

      if (serverCatalogs == null) return; // Network error, keep local

      if (serverCatalogs.isEmpty && myCatalogues.isNotEmpty) {
        // Server is empty but we have local catalogs → push them up
        await _pushAllToServer(userId);
        return;
      }

      // Convert server catalogs (product IDs) to local format (full ProductModels)
      final List<CatalogueModel> converted = [];
      for (final serverCat in serverCatalogs) {
        final catalogModel = await _convertServerCatalog(serverCat);
        if (catalogModel != null) {
          converted.add(catalogModel);
        }
      }

      // Merge: server catalogs + any local-only catalogs
      final Map<String, CatalogueModel> merged = {};

      // Server catalogs take priority
      for (final cat in converted) {
        merged[cat.id] = cat;
      }

      // Add local-only catalogs that don't exist on server
      for (final local in myCatalogues) {
        if (!merged.containsKey(local.id)) {
          merged[local.id] = local;
          // Push this local-only catalog to server
          _createOnServer(local);
        }
      }

      myCatalogues.assignAll(merged.values.toList());
      myCatalogues.refresh();
      _saveToStorage();
    } catch (e) {
      debugPrint('CatalogSync: Error syncing from server: $e');
    } finally {
      isSyncing.value = false;
    }
  }

  /// Convert server catalog format {products: [IDs]} to app format {products: [ProductModels]}
  Future<CatalogueModel?> _convertServerCatalog(
    Map<String, dynamic> serverCat,
  ) async {
    try {
      final String id = serverCat['id'] ?? '';
      final String name = serverCat['name'] ?? 'Untitled';
      final String desc = serverCat['desc'] ?? '';
      final String created = serverCat['created'] ?? '';
      final List<dynamic> productIds = serverCat['products'] ?? [];

      // Fetch product details for each ID
      final List<ProductModel> products = [];
      for (final pid in productIds) {
        final int productId = (pid is int)
            ? pid
            : (int.tryParse(pid.toString()) ?? 0);
        if (productId <= 0) continue;

        // Check cache first
        if (_productCache.containsKey(productId)) {
          products.add(_productCache[productId]!);
          continue;
        }

        // Check if we already have this product in any local catalog
        ProductModel? existing;
        for (final cat in myCatalogues) {
          try {
            existing = cat.products.firstWhere((p) => p.id == productId);
            break;
          } catch (_) {}
        }

        if (existing != null) {
          products.add(existing);
          _productCache[productId] = existing;
          continue;
        }

        // Fetch from WooCommerce API (last resort)
        try {
          final product = await ApiService().fetchProductByIdSafe(
            productId.toString(),
          );
          if (product != null) {
            products.add(product);
            _productCache[productId] = product;
          }
        } catch (e) {
          debugPrint('CatalogSync: Could not fetch product $productId: $e');
        }
      }

      return CatalogueModel(
        id: id,
        name: name,
        description: desc,
        createdAt: DateTime.tryParse(created) ?? DateTime.now(),
        products: products,
      );
    } catch (e) {
      debugPrint('CatalogSync: Error converting server catalog: $e');
      return null;
    }
  }

  /// Push all local catalogs to server (used when server is empty)
  Future<void> _pushAllToServer(String userId) async {
    try {
      final List<Map<String, dynamic>> catalogsForServer = myCatalogues
          .map((c) => c.toServerJson())
          .toList();

      await ApiService().syncCatalogsToServer(
        userId: userId,
        catalogs: catalogsForServer,
      );
    } catch (e) {
      debugPrint('CatalogSync: Error pushing all to server: $e');
    }
  }

  /// Create a single catalog on the server
  Future<void> _createOnServer(CatalogueModel catalogue) async {
    try {
      final userId = await _getUserId();
      if (userId == null || userId.isEmpty) return;

      await ApiService().createCatalogOnServer(
        userId: userId,
        catalogId: catalogue.id,
        name: catalogue.name,
        desc: catalogue.description,
        productIds: catalogue.products.map((p) => p.id).toList(),
      );
    } catch (e) {
      debugPrint('CatalogSync: Error creating on server: $e');
    }
  }

  /// Delete a catalog on the server
  Future<void> _deleteOnServer(String catalogId) async {
    try {
      final userId = await _getUserId();
      if (userId == null || userId.isEmpty) return;

      await ApiService().deleteCatalogOnServer(
        userId: userId,
        catalogId: catalogId,
      );
    } catch (e) {
      debugPrint('CatalogSync: Error deleting on server: $e');
    }
  }

  /// Add a product to a catalog on the server
  Future<void> _addProductOnServer(String catalogId, int productId) async {
    try {
      final userId = await _getUserId();
      if (userId == null || userId.isEmpty) return;

      await ApiService().updateCatalogOnServer(
        userId: userId,
        catalogId: catalogId,
        action: 'add_product',
        productId: productId,
      );
    } catch (e) {
      debugPrint('CatalogSync: Error adding product on server: $e');
    }
  }

  /// Remove a product from a catalog on the server
  Future<void> _removeProductOnServer(String catalogId, int productId) async {
    try {
      final userId = await _getUserId();
      if (userId == null || userId.isEmpty) return;

      await ApiService().updateCatalogOnServer(
        userId: userId,
        catalogId: catalogId,
        action: 'remove_product',
        productId: productId,
      );
    } catch (e) {
      debugPrint('CatalogSync: Error removing product on server: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // LOCAL PERSISTENCE (unchanged — acts as offline cache)
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
      // ignore
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
