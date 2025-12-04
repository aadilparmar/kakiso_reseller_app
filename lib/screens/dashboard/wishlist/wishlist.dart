import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/controllers/wishlist_controller.dart';
import 'package:kakiso_reseller_app/controllers/cart_controller.dart';
import 'package:kakiso_reseller_app/utils/constants.dart';
import 'package:kakiso_reseller_app/screens/dashboard/my_cart/my_cart.dart';

class WishlistScreen extends StatelessWidget {
  WishlistScreen({super.key});

  // Make sure controllers are available
  final WishlistController wishlistController = Get.put(WishlistController());
  final CartController cartController = Get.put(CartController());
  // if you ever need it later

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      // --- APP BAR (MATCHING HOME WITH CART BADGE) ---
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: true,
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 8),
            const Text(
              'My Wishlist',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
                color: Colors.black,
              ),
            ),
            const Spacer(),

            // --- CART ICON WITH BADGE ---
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Iconsax.shopping_cart),
                  color: accentColor,
                  iconSize: 30,
                  onPressed: () => Get.to(() => const InventoryPage()),
                ),
                Positioned(
                  right: 5,
                  top: 5,
                  child: Obx(() {
                    final count = cartController.itemCount;
                    if (count == 0) return const SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 22,
                        minHeight: 22,
                      ),
                      child: Center(
                        child: Text(
                          count > 99 ? '99+' : '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),

            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Iconsax.profile_circle),
              color: accentColor,
              iconSize: 30,
              onPressed: () {},
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),

      body: Obx(() {
        if (wishlistController.wishlistItems.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: wishlistController.wishlistItems.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final product = wishlistController.wishlistItems[index];
            return _buildWishlistTile(product, wishlistController);
          },
        );
      }),
    );
  }

  // ---------------------------------------------------------------------------
  // EMPTY STATE
  // ---------------------------------------------------------------------------
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.heart_slash, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Your Wishlist is Empty',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Explore products and add them here!',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // WISHLIST TILE
  // ---------------------------------------------------------------------------
  Widget _buildWishlistTile(
    ProductModel product,
    WishlistController controller,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.12),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // IMAGE
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              bottomLeft: Radius.circular(16),
            ),
            child: product.image.isNotEmpty
                ? Image.network(
                    product.image,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 100,
                    height: 100,
                    color: Colors.grey[100],
                    child: const Icon(Iconsax.image, color: Colors.grey),
                  ),
          ),

          // DETAILS
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // NAME
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // SHORT DESCRIPTION (OPTIONAL)
                  if (product.shortDescription.isNotEmpty)
                    Text(
                      product.shortDescription,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),

                  const SizedBox(height: 8),

                  // PRICE + DISCOUNT
                  _buildPriceRow(product),
                ],
              ),
            ),
          ),

          // REMOVE BUTTON
          IconButton(
            onPressed: () => controller.removeFromWishlist(product.id),
            icon: const Icon(
              Iconsax.heart5,
              color: Color(0xFFE91E63),
              size: 26,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PRICE ROW WITH DISCOUNT
  // ---------------------------------------------------------------------------
  Widget _buildPriceRow(ProductModel product) {
    final hasDiscount =
        product.discountPercentage != null &&
        product.discountPercentage != 0 &&
        product.regularPrice.isNotEmpty &&
        product.regularPrice != product.price;

    return Row(
      children: [
        // SALE PRICE
        Text(
          '₹${product.price}',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFFE91E63),
          ),
        ),

        const SizedBox(width: 8),

        // REGULAR PRICE (STRIKETHROUGH)
        if (hasDiscount)
          Text(
            '₹${product.regularPrice}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
              decoration: TextDecoration.lineThrough,
            ),
          ),

        const SizedBox(width: 6),

        // DISCOUNT BADGE
        if (hasDiscount)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '-${product.discountPercentage}%',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
          ),
      ],
    );
  }
}
