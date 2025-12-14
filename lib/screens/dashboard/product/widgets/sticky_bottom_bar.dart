// lib/screens/dashboard/product/widgets/sticky_bottom_bar.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import 'package:kakiso_reseller_app/controllers/product_details_controller.dart';
import 'package:kakiso_reseller_app/controllers/cart_controller.dart';
import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/screens/dashboard/my_cart/my_cart.dart';
import 'package:kakiso_reseller_app/utils/constants.dart';

class ProductStickyBottomBar extends StatelessWidget {
  final ProductDetailsController controller;
  final ProductModel product;

  ProductStickyBottomBar({
    super.key,
    required this.controller,
    required this.product,
  });

  final RxBool addedToCart = false.obs; // Track button state

  @override
  Widget build(BuildContext context) {
    // Ensure CartController is registered somewhere globally.
    // If needed, you can keep this find; you don't need it for addToCart now.
    Get.find<CartController>();

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // QUANTITY BOX
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, size: 18),
                          onPressed: () {
                            if (controller.quantity.value > 1) {
                              controller.quantity.value--;
                            }
                          },
                        ),
                        Obx(
                          () => Text(
                            "${controller.quantity.value}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, size: 18),
                          onPressed: () => controller.quantity.value++,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),

                  // BUTTON
                  Expanded(
                    child: Obx(() {
                      return ElevatedButton(
                        onPressed: () {
                          if (addedToCart.value == false) {
                            // ✅ ADD TO CART ACTION using controller logic
                            // This includes selectedAttributes and snackbar.
                            controller.addToCart(product);

                            addedToCart.value = true; // change button state
                          } else {
                            // GO TO CART ACTION
                            Get.to(() => const InventoryPage());
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 8,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              addedToCart.value
                                  ? Iconsax.shopping_bag
                                  : Iconsax.shopping_cart,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              addedToCart.value ? "Go to Cart" : "Add to Cart",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
