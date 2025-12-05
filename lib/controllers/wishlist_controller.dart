// lib/controllers/wishlist_controller.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:kakiso_reseller_app/models/product.dart';

class WishlistController extends GetxController {
  static WishlistController get instance => Get.find<WishlistController>();

  final RxList<ProductModel> wishlistItems = <ProductModel>[].obs;

  static const String _wishlistStorageKey = 'wishlist_items_v1';

  // Using same secure storage you already use for auth
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void onInit() {
    super.onInit();
    _loadWishlistFromStorage();
  }

  // ---------------------------------------------------------------------------
  // PERSISTENCE
  // ---------------------------------------------------------------------------

  Future<void> _loadWishlistFromStorage() async {
    try {
      final String? raw = await _storage.read(key: _wishlistStorageKey);
      if (raw == null || raw.isEmpty) return;

      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;

      final List<ProductModel> loaded = decoded
          .map(
            (e) => ProductModel.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();

      wishlistItems.assignAll(loaded);
    } catch (e) {
      debugPrint('WishlistController: error loading wishlist -> $e');
    }
  }

  Future<void> _saveWishlistToStorage() async {
    try {
      final List<Map<String, dynamic>> data = wishlistItems
          .map((p) => p.toJson())
          .toList();
      final String raw = jsonEncode(data);
      await _storage.write(key: _wishlistStorageKey, value: raw);
    } catch (e) {
      debugPrint('WishlistController: error saving wishlist -> $e');
    }
  }

  // ---------------------------------------------------------------------------
  // API
  // ---------------------------------------------------------------------------

  bool isInWishlist(int productId) {
    return wishlistItems.any((p) => p.id == productId);
  }

  Future<void> addToWishlist(ProductModel product) async {
    if (isInWishlist(product.id)) return;
    wishlistItems.add(product);
    await _saveWishlistToStorage();
  }

  Future<void> removeFromWishlist(int productId) async {
    wishlistItems.removeWhere((p) => p.id == productId);
    await _saveWishlistToStorage();
  }

  Future<void> toggleWishlist(ProductModel product) async {
    if (isInWishlist(product.id)) {
      await removeFromWishlist(product.id);
    } else {
      await addToWishlist(product);
    }
  }

  Future<void> clearWishlist() async {
    wishlistItems.clear();
    await _saveWishlistToStorage();
  }
}
