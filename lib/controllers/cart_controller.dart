// lib/controllers/cart_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/screens/dashboard/my_cart/my_cart.dart';

class CartItem {
  final ProductModel product;
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

  Map<String, dynamic> toJson() => {
    'product': product.toJson(),
    'quantity': quantity,
    'selectedAttributes': selectedAttributes,
  };

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      product: ProductModel.fromJson(
        Map<String, dynamic>.from(json['product']),
      ),
      quantity: json['quantity'] ?? 1,
      selectedAttributes: Map<String, String>.from(
        json['selectedAttributes'] ?? {},
      ),
    );
  }
}

class CartController extends GetxController {
  static const _cartKey = 'cart_items';
  static const _sellingKey = 'cart_selling_prices';

  final GetStorage _box = GetStorage();

  final RxList<CartItem> cartItems = <CartItem>[].obs;
  final RxMap<int, double> sellingPrices = <int, double>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _loadCart();
    _loadSellingPrices();

    ever(cartItems, (_) => _saveCart());
    ever(sellingPrices, (_) => _saveSellingPrices());
  }

  // ---------------- CART LOGIC ----------------

  void addToCart(
    ProductModel product, {
    Map<String, String>? selectedAttributes,
  }) {
    final attrs = selectedAttributes ?? {};

    final existing = cartItems.firstWhereOrNull(
      (i) =>
          i.product.id == product.id && _mapEquals(i.selectedAttributes, attrs),
    );

    if (existing != null) {
      existing.quantity++;
      cartItems.refresh();
    } else {
      cartItems.add(CartItem(product: product, selectedAttributes: attrs));
    }
  }

  void removeFromCart(int productId) {
    cartItems.removeWhere((i) => i.product.id == productId);
    sellingPrices.remove(productId);
  }

  void incrementQuantity(int productId) {
    final item = cartItems.firstWhere((i) => i.product.id == productId);
    item.quantity++;
    cartItems.refresh();
  }

  void decrementQuantity(int productId) {
    final item = cartItems.firstWhere((i) => i.product.id == productId);
    if (item.quantity > 1) {
      item.quantity--;
      cartItems.refresh();
    } else {
      removeFromCart(productId);
    }
  }

  void clearCart() {
    cartItems.clear();
    sellingPrices.clear();
    _box.remove(_cartKey);
    _box.remove(_sellingKey);
  }

  double get totalPrice => cartItems.fold(0, (sum, i) => sum + i.totalPrice);

  int get itemCount => cartItems.fold(0, (sum, i) => sum + i.quantity);

  void setSellingPrice(int productId, double price) {
    sellingPrices[productId] = price;
  }

  double? getSellingPrice(int productId) {
    return sellingPrices[productId];
  }

  // ---------------- STORAGE ----------------

  void _saveCart() {
    _box.write(_cartKey, cartItems.map((e) => e.toJson()).toList());
  }

  void _loadCart() {
    final stored = _box.read<List<dynamic>>(_cartKey);
    if (stored == null) return;

    try {
      cartItems.assignAll(
        stored.map((e) => CartItem.fromJson(Map<String, dynamic>.from(e))),
      );
    } catch (_) {
      cartItems.clear();
    }
  }

  void _saveSellingPrices() {
    final map = <String, double>{};
    sellingPrices.forEach((k, v) => map[k.toString()] = v);
    _box.write(_sellingKey, map);
  }

  void _loadSellingPrices() {
    final stored = _box.read<Map<String, dynamic>>(_sellingKey);
    if (stored == null) return;

    sellingPrices.assignAll(
      stored.map((k, v) => MapEntry(int.parse(k), (v as num).toDouble())),
    );
  }

  bool _mapEquals(Map a, Map b) {
    if (a.length != b.length) return false;
    for (final k in a.keys) {
      if (a[k] != b[k]) return false;
    }
    return true;
  }

  // ---------------- UI SNACKBAR ----------------

  void showCustomCartSnackbar(ProductModel product) {
    Get.snackbar(
      '',
      '',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.white,
      borderRadius: 20,
      margin: const EdgeInsets.all(12),
      titleText: Row(
        children: [
          Image.network(product.image, width: 40, height: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              product.name,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      mainButton: TextButton(
        onPressed: () => Get.to(() => const InventoryPage()),
        child: const Text('VIEW'),
      ),
      duration: const Duration(seconds: 3),
    );
  }
}
