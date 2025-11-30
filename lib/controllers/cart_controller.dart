// lib/controllers/cart_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:iconsax/iconsax.dart';

import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/screens/dashboard/my_cart/my_cart.dart';

class CartItem {
  final ProductModel product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get totalPrice {
    final price = double.tryParse(product.price) ?? 0.0;
    return price * quantity;
  }

  // ---------- Persistence helpers ----------

  Map<String, dynamic> toJson() => {
    'product': product.toJson(), // ⚠️ ProductModel must have toJson()
    'quantity': quantity,
  };

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      product: ProductModel.fromJson(json['product'] as Map<String, dynamic>),
      quantity: (json['quantity'] ?? 1) as int,
    );
  }
}

class CartController extends GetxController {
  static const String _storageKey = 'cart_items';

  final GetStorage _box = GetStorage();

  // Observable list of cart items
  final RxList<CartItem> cartItems = <CartItem>[].obs;

  // ---------- Lifecycle ----------

  @override
  void onInit() {
    super.onInit();
    _loadCartFromStorage();

    // Whenever cartItems changes → save to storage
    ever<List<CartItem>>(cartItems, (_) => _saveCartToStorage());
  }

  // ---------- Public API ----------

  // Add item to cart
  void addToCart(ProductModel product) {
    // Check if item already exists
    final existingItem = cartItems.firstWhereOrNull(
      (item) => item.product.id == product.id,
    );

    if (existingItem != null) {
      existingItem.quantity++;
      cartItems.refresh(); // Notify listeners
    } else {
      cartItems.add(CartItem(product: product));
    }
  }

  // Remove item
  void removeFromCart(int productId) {
    cartItems.removeWhere((item) => item.product.id == productId);
  }

  // Increase Quantity
  void incrementQuantity(int productId) {
    final item = cartItems.firstWhere((item) => item.product.id == productId);
    item.quantity++;
    cartItems.refresh();
  }

  // Decrease Quantity
  void decrementQuantity(int productId) {
    final item = cartItems.firstWhere((item) => item.product.id == productId);
    if (item.quantity > 1) {
      item.quantity--;
      cartItems.refresh();
    } else {
      removeFromCart(productId);
    }
  }

  // Clear cart completely (use on manual logout if you want)
  void clearCart() {
    cartItems.clear();
  }

  // Get Total Price
  double get totalPrice =>
      cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);

  // Get Item Count
  int get itemCount => cartItems.fold(0, (sum, item) => sum + item.quantity);

  // ---------- Snackbar UI ----------

  void showCustomCartSnackbar(ProductModel product) {
    Get.snackbar(
      '',
      '',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.only(bottom: 20, left: 10, right: 10),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      borderRadius: 24,
      maxWidth: 400,
      backgroundColor: Colors.white.withOpacity(0.95),
      barBlur: 20,
      overlayBlur: 0.0,
      colorText: Colors.black,
      boxShadows: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 20,
          spreadRadius: 5,
          offset: const Offset(0, 4),
        ),
      ],
      titleText: Row(
        children: [
          // PRODUCT IMAGE THUMBNAIL
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              image: DecorationImage(
                image: NetworkImage(product.image),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // TEXT CONTENT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Added to Cart",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                    color: Color(0xFF4A317E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  product.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                    color: Colors.grey.shade700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      messageText: const SizedBox(height: 0),
      mainButton: TextButton(
        onPressed: () => Get.to(() => const InventoryPage()),
        style: TextButton.styleFrom(
          backgroundColor: const Color(0xFF4A317E).withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
        child: const Row(
          children: [
            Text(
              "View",
              style: TextStyle(
                color: Color(0xFF4A317E),
                fontWeight: FontWeight.w700,
                fontSize: 12,
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(width: 6),
            Icon(Iconsax.arrow_right_3, size: 16, color: Color(0xFF4A317E)),
          ],
        ),
      ),
      duration: const Duration(seconds: 4),
      animationDuration: const Duration(milliseconds: 600),
      isDismissible: true,
      forwardAnimationCurve: Curves.easeOutBack,
    );
  }

  // ---------- Persistence ----------

  void _loadCartFromStorage() {
    final stored = _box.read<List<dynamic>>(_storageKey);
    if (stored == null) return;

    try {
      final items = stored
          .map((e) => CartItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      cartItems.assignAll(items);
    } catch (_) {
      cartItems.clear(); // if corrupted, reset
    }
  }

  void _saveCartToStorage() {
    final data = cartItems.map((item) => item.toJson()).toList();
    _box.write(_storageKey, data);
  }
}
