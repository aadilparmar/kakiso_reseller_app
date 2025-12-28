import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kakiso_reseller_app/controllers/product_details_controller.dart';
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

  final RxBool addedToCart = false.obs;

  @override
  Widget build(BuildContext context) {
    // We removed Positioned. This widget should now be placed in the
    // 'bottomNavigationBar' property of your Scaffold.
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // 1. ADD TO CART (Secondary Button Style)
              Expanded(
                child: Obx(() {
                  return OutlinedButton(
                    onPressed: () {
                      if (addedToCart.value) {
                        Get.to(() => const InventoryPage());
                      } else {
                        controller.addToCart(product);
                        addedToCart.value = true;
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.black),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          addedToCart.value
                              ? Iconsax.bag_tick
                              : Iconsax.shopping_cart,
                          color: Colors.black,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          addedToCart.value ? "GO TO CART" : "ADD TO CART",
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),

              const SizedBox(width: 12),

              // 2. BUY NOW (Primary Button Style)
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (!addedToCart.value) controller.addToCart(product);
                    Get.to(() => const InventoryPage());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Iconsax.flash_1, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        "BUY NOW",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
