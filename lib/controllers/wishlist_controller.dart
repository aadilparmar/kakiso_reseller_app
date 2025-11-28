import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kakiso_reseller_app/models/product.dart';

class WishlistController extends GetxController {
  static WishlistController get instance => Get.find();

  // Observable list of ProductModel
  final RxList<ProductModel> wishlistItems = <ProductModel>[].obs;

  /// Toggle Add/Remove
  void toggleWishlist(ProductModel product) {
    if (isWhishlisted(product.id)) {
      removeFromWishlist(product.id);
    } else {
      addToWishlist(product);
    }
  }

  void addToWishlist(ProductModel product) {
    // Avoid duplicates
    if (!isWhishlisted(product.id)) {
      wishlistItems.add(product);
      Get.snackbar(
        'Added to Wishlist',
        '${product.name} has been saved.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 1),
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );
    }
  }

  void removeFromWishlist(int productId) {
    wishlistItems.removeWhere((item) => item.id == productId);
    Get.snackbar(
      'Removed',
      'Item removed from your wishlist.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.redAccent.withOpacity(0.9),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 1),
      icon: const Icon(Icons.delete_outline, color: Colors.white),
    );
  }

  /// Check if product is in wishlist using ID
  bool isWhishlisted(int productId) {
    return wishlistItems.any((item) => item.id == productId);
  }
}
