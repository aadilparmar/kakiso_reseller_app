import 'package:get/get.dart';
import 'package:kakiso_reseller_app/models/product.dart';

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

    Get.snackbar('Success', '${product.name} added to cart');
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

  // Get Total Price
  double get totalPrice =>
      cartItems.fold(0, (sum, item) => sum + item.totalPrice);

  // Get Item Count
  int get itemCount => cartItems.fold(0, (sum, item) => sum + item.quantity);
}
