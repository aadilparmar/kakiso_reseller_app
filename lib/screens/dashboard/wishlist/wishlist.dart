// lib/screens/dashboard/wishlist/wishlist_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/controllers/wishlist_controller.dart';
import 'package:kakiso_reseller_app/controllers/cart_controller.dart';
import 'package:kakiso_reseller_app/utils/constants.dart';
import 'package:kakiso_reseller_app/screens/dashboard/my_cart/my_cart.dart';
import 'package:kakiso_reseller_app/screens/dashboard/product/product_details_page.dart';

class WishlistScreen extends StatelessWidget {
  WishlistScreen({super.key});

  // Make sure controllers are available & persistent
  final WishlistController wishlistController = Get.put(
    WishlistController(),
    permanent: true,
  );
  final CartController cartController = Get.put(
    CartController(),
    permanent: true,
  );

  // ---------------------------------------------------------------------------
  // CUSTOM "ADDED TO CART" SNACKBAR
  // ---------------------------------------------------------------------------
  void _showAddedToCartSnackbar(ProductModel product) {
    Get.snackbar(
      '',
      '',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.only(bottom: 20, left: 10, right: 10),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      borderRadius: 24,
      backgroundColor: Colors.white.withOpacity(0.95),
      barBlur: 20,
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
        child: Row(
          children: const [
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
    );
  }

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
  //  - Tap card → ProductDetailsPage
  //  - Inline "Add to Cart" CTA
  //  - Heart to remove from wishlist
  // ---------------------------------------------------------------------------
  Widget _buildWishlistTile(
    ProductModel product,
    WishlistController controller,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        // Navigate to product details
        Get.to(
          () => ProductDetailsPage(product: product),
          transition: Transition.fadeIn,
          duration: const Duration(milliseconds: 250),
        );
      },
      child: Container(
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

            // DETAILS + ACTIONS
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
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
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 6),

                    // SHORT DESCRIPTION (OPTIONAL)
                    if (product.shortDescription.isNotEmpty)
                      Text(
                        product.shortDescription,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[500],
                          fontFamily: 'Poppins',
                        ),
                      ),

                    const SizedBox(height: 8),

                    // PRICE + ADD TO CART BUTTON
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildPriceRow(product),
                        const SizedBox(width: 8),

                        // ADD TO CART INLINE BUTTON
                        TextButton.icon(
                          onPressed: () {
                            cartController.addToCart(product);
                            _showAddedToCartSnackbar(product);
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            backgroundColor: const Color(
                              0xFF4A317E,
                            ).withOpacity(0.06),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          icon: const Icon(
                            Iconsax.shopping_bag,
                            size: 16,
                            color: Color(0xFF4A317E),
                          ),
                          label: const Text(
                            'Add',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                              color: Color(0xFF4A317E),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // REMOVE FROM WISHLIST BUTTON
            IconButton(
              onPressed: () => controller.removeFromWishlist(product.id),
              icon: const Icon(
                Iconsax.heart5,
                color: Color(0xFFE91E63),
                size: 26,
              ),
              tooltip: 'Remove',
            ),
          ],
        ),
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SALE PRICE
            Text(
              '₹${product.price}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFFE91E63),
                fontFamily: 'Poppins',
              ),
            ),

            const SizedBox(width: 6),

            // REGULAR PRICE (STRIKETHROUGH)
            if (hasDiscount)
              Text(
                '₹${product.regularPrice}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                  decoration: TextDecoration.lineThrough,
                  fontFamily: 'Poppins',
                ),
              ),
          ],
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
                fontFamily: 'Poppins',
              ),
            ),
          ),
      ],
    );
  }
}
