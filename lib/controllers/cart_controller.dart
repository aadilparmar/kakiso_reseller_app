// lib/controllers/cart_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:iconsax/iconsax.dart';

import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/screens/dashboard/my_cart/my_cart.dart';

class CartItem {
  final ProductModel product;

  /// 🔹 Selected variation attributes for this cart line
  /// e.g. {"Size": "L", "Color": "Red"}
  final Map<String, String> selectedAttributes;

  int quantity;

  CartItem({
    required this.product,
    this.selectedAttributes = const {},
    this.quantity = 1,
  });

  double get totalPrice {
    final price = double.tryParse(product.price) ?? 0.0;
    return price * quantity;
  }

  // ---------- Persistence helpers ----------

  Map<String, dynamic> toJson() => {
    'product': product.toJson(), // ProductModel must have toJson()
    'quantity': quantity,
    'selectedAttributes': selectedAttributes,
  };

  factory CartItem.fromJson(Map<String, dynamic> json) {
    // Safely parse selectedAttributes (might not exist in old data)
    Map<String, String> parsedAttrs = {};
    final rawAttrs = json['selectedAttributes'];
    if (rawAttrs is Map) {
      rawAttrs.forEach((key, value) {
        if (key != null && value != null) {
          parsedAttrs[key.toString()] = value.toString();
        }
      });
    }

    return CartItem(
      product: ProductModel.fromJson(json['product'] as Map<String, dynamic>),
      quantity: (json['quantity'] ?? 1) as int,
      selectedAttributes: parsedAttrs,
    );
  }
}

class CartController extends GetxController {
  static const String _storageKey = 'cart_items';
  static const String _storageSellingKey = 'cart_selling_prices';

  final GetStorage _box = GetStorage();

  // Observable list of cart items
  final RxList<CartItem> cartItems = <CartItem>[].obs;

  /// ✅ Per-product selling price (what reseller charges customer per unit)
  /// key = productId, value = selling price per unit
  final RxMap<int, double> sellingPrices = <int, double>{}.obs;

  // ---------- Lifecycle ----------

  @override
  void onInit() {
    super.onInit();
    _loadCartFromStorage();
    _loadSellingPricesFromStorage();

    // Whenever cartItems changes → save to storage
    ever<List<CartItem>>(cartItems, (_) => _saveCartToStorage());

    // Whenever sellingPrices changes → save to storage
    ever<Map<int, double>>(sellingPrices, (_) => _saveSellingPricesToStorage());
  }

  // ---------- Helpers ----------

  bool _areAttributesEqual(Map<String, String> a, Map<String, String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }

  // ---------- Public API ----------

  /// Add item to cart with optional selected variation.
  ///
  /// Existing calls `addToCart(product)` will still work (variation = {}).
  /// Items are grouped by (productId + selectedAttributes).
  void addToCart(
    ProductModel product, {
    Map<String, String>? selectedAttributes,
  }) {
    final Map<String, String> attrs = selectedAttributes ?? const {};

    final existingItem = cartItems.firstWhereOrNull(
      (item) =>
          item.product.id == product.id &&
          _areAttributesEqual(item.selectedAttributes, attrs),
    );

    if (existingItem != null) {
      existingItem.quantity++;
      cartItems.refresh(); // Notify listeners
    } else {
      cartItems.add(CartItem(product: product, selectedAttributes: attrs));
    }
  }

  // Remove item
  void removeFromCart(int productId) {
    cartItems.removeWhere((item) => item.product.id == productId);
    // Also remove any stored selling price for this product
    sellingPrices.remove(productId);
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
    sellingPrices.clear();
    _box.remove(_storageKey);
    _box.remove(_storageSellingKey);
  }

  // Get Total Price (base cost to reseller)
  double get totalPrice =>
      cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);

  // Get Item Count
  int get itemCount => cartItems.fold(0, (sum, item) => sum + item.quantity);

  /// ✅ Set selling price per unit for a product (used from InventoryPage)
  void setSellingPrice(int productId, double price) {
    sellingPrices[productId] = price;
  }

  /// ✅ Get selling price per unit for a product (null if not set)
  double? getSellingPrice(int productId) {
    return sellingPrices[productId];
  }

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
      backgroundColor: Colors.white.withValues(alpha: 0.95),
      barBlur: 20,
      overlayBlur: 0.0,
      colorText: Colors.black,
      boxShadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
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
          backgroundColor: const Color(0xFF4A317E).withValues(alpha: 0.1),
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

  // ---------- Persistence (cart items) ----------

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

  // ---------- Persistence (selling prices) ----------

  void _loadSellingPricesFromStorage() {
    final stored = _box.read<Map<String, dynamic>>(_storageSellingKey);

    if (stored == null) return;

    final Map<int, double> parsed = {};
    stored.forEach((key, value) {
      final int? id = int.tryParse(key);
      final double? price = (value is num)
          ? value.toDouble()
          : double.tryParse(value.toString());
      if (id != null && price != null) {
        parsed[id] = price;
      }
    });

    sellingPrices.assignAll(parsed);
  }

  void _saveSellingPricesToStorage() {
    final Map<String, double> data = {};
    sellingPrices.forEach((key, value) {
      data[key.toString()] = value;
    });
    _box.write(_storageSellingKey, data);
  }
}
