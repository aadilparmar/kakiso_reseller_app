import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/screens/dashboard/my_cart/my_cart.dart';

class CartItem {
  final ProductModel product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get totalPrice => double.tryParse(product.price) != null
      ? double.parse(product.price) * quantity
      : 0.0;
}

class CartController extends GetxController {
  // Observable list of cart items
  var cartItems = <CartItem>[].obs;

  // Add item to cart
  void addToCart(ProductModel product) {
    // Check if item already exists
    var existingItem = cartItems.firstWhereOrNull(
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
    var item = cartItems.firstWhere((item) => item.product.id == productId);
    item.quantity++;
    cartItems.refresh();
  }

  // Decrease Quantity
  void decrementQuantity(int productId) {
    var item = cartItems.firstWhere((item) => item.product.id == productId);
    if (item.quantity > 1) {
      item.quantity--;
      cartItems.refresh();
    } else {
      removeFromCart(productId);
    }
  }

  void showCustomCartSnackbar(ProductModel product) {
    Get.snackbar(
      '',
      '',
      // --- 1. POSITION CHANGED TO BOTTOM ---
      snackPosition: SnackPosition.BOTTOM,

      // Add margin specifically to the bottom to make it "float"
      margin: const EdgeInsets.only(bottom: 20, left: 10, right: 10),

      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      borderRadius: 24,
      maxWidth: 400,

      // --- 2. STYLING ---
      backgroundColor: Colors.white.withOpacity(
        0.95,
      ), // Slightly more opaque for bottom visibility
      barBlur: 20,
      overlayBlur: 0.0,
      colorText: Colors.black,

      // Shadows
      boxShadows: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 20,
          spreadRadius: 5,
          offset: const Offset(0, 4), // Shadow
        ),
      ],

      // --- 3. CUSTOM CONTENT ---
      titleText: Row(
        children: [
          // PRODUCT IMAGE THUMBNAIL
          Container(
            width: 45, // Slightly larger for better visibility
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

      // --- 4. ACTION BUTTON ---
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

      // --- 5. ANIMATION ---
      duration: const Duration(seconds: 4), // Gives user time to react
      animationDuration: const Duration(milliseconds: 600),
      isDismissible: true,
      // Pop up from bottom
      forwardAnimationCurve: Curves.easeOutBack,
    );
  }

  // Get Total Price
  double get totalPrice =>
      cartItems.fold(0, (sum, item) => sum + item.totalPrice);

  // Get Item Count
  int get itemCount => cartItems.fold(0, (sum, item) => sum + item.quantity);
}
