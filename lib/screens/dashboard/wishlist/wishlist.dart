// lib/screens/dashboard/wishlist/wishlist_screen.dart

import 'dart:ui'; // Required for BackdropFilter
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_auto_translate/flutter_auto_translate.dart';

import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/controllers/wishlist_controller.dart';
import 'package:kakiso_reseller_app/controllers/cart_controller.dart';
import 'package:kakiso_reseller_app/screens/dashboard/my_cart/my_cart.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  // --- CONTROLLERS ---
  final WishlistController wishlistController = Get.put(
    WishlistController(),
    permanent: true,
  );
  final CartController cartController = Get.put(
    CartController(),
    permanent: true,
  );

  // --- DESIGN CONSTANTS ---
  static const Color kPrimaryColor = Color(0xFF4A317E);
  static const Color kAccentColor = Color(0xFFEB2A7E);
  static const Color kBgColor = Color(0xFFF3F4F6);

  // --- SNACKBAR STATE ---
  OverlayEntry? _currentSnackbar;

  @override
  void dispose() {
    _removeSnackbar();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // PREMIUM "CONVERSION" SNACKBAR
  // ---------------------------------------------------------------------------
  void _removeSnackbar() {
    _currentSnackbar?.remove();
    _currentSnackbar = null;
  }

  void _showConversionSnackbar(ProductModel product) {
    _removeSnackbar();
    final overlay = Overlay.of(context);

    _currentSnackbar = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Dismiss on tap outside
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (_) => _removeSnackbar(),
            ),
          ),
          Positioned(
            bottom: 30,
            left: 16,
            right: 16,
            child: Material(
              color: Colors.transparent,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 40 * (1 - value)),
                    child: Opacity(
                      opacity: value.clamp(0.0, 1.0),
                      child: child,
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F2937).withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: kAccentColor.withValues(alpha: 0.3),
                            blurRadius: 25,
                            spreadRadius: -5,
                            offset: const Offset(0, 10),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Iconsax.bag_tick,
                              color: Colors.green,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  "Moved to Cart",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Poppins',
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "${product.name} is ready for checkout.",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 12,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              _removeSnackbar();
                              Get.to(() => const InventoryPage());
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 0,
                              ),
                              visualDensity: VisualDensity.compact,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              "View Cart",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    overlay.insert(_currentSnackbar!);
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) _removeSnackbar();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // --- APP BAR ---
          SliverAppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            floating: true,
            pinned: true,
            expandedHeight: 60,
            leading: IconButton(
              icon: const Icon(Iconsax.arrow_left, color: Colors.black),
              onPressed: () => Get.back(),
            ),
            centerTitle: true,
            title: const Text(
              "My Wishlist",
              style: TextStyle(
                color: Colors.black,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            actions: [_buildCartBadge(), const SizedBox(width: 12)],
          ),

          // --- RESPONSIVE GRID CONTENT ---
          Obx(() {
            if (wishlistController.wishlistItems.isEmpty) {
              return SliverFillRemaining(child: _buildEmptyState());
            }

            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              sliver: SliverLayoutBuilder(
                builder: (context, constraints) {
                  // ⚡ RESPONSIVE LOGIC:
                  // Calculate width of one card (assuming 2 columns with 16 spacing)
                  final double screenWidth = constraints.crossAxisExtent;
                  final double itemWidth = (screenWidth - 48) / 2;

                  // We need at least 135px for the details section (Name, Price, Button)
                  // The card is split 65% (Image) / 35% (Details).
                  // So TotalHeight * 0.35 must be >= 135px.
                  // TotalHeight >= 135 / 0.35 = 385px.

                  // However, we don't want it to look huge on tablets.
                  // So we clamp the ratio nicely.
                  final double requiredHeight = 385;
                  final double ratio = itemWidth / requiredHeight;

                  // Clamp ratio to avoid extreme stretching on weird screens
                  final double finalRatio = ratio.clamp(0.45, 0.65);

                  return SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: finalRatio,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                    ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final product = wishlistController.wishlistItems[index];

                      // PERFORMANCE: RepaintBoundary + Const Constructor
                      return RepaintBoundary(
                        child: _WishlistResellerCard(
                          key: ValueKey(product.id),
                          product: product,
                          onRemove: () {
                            HapticFeedback.lightImpact();
                            wishlistController.removeFromWishlist(product.id);
                          },
                          onAddToCart: () {
                            HapticFeedback.mediumImpact();
                            cartController.addToCart(product);
                            _showConversionSnackbar(product);
                          },
                        ),
                      );
                    }, childCount: wishlistController.wishlistItems.length),
                  );
                },
              ),
            );
          }),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildCartBadge() {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Iconsax.bag_2, size: 26),
          color: Colors.black,
          onPressed: () => Get.to(() => const InventoryPage()),
        ),
        Positioned(
          right: 6,
          top: 6,
          child: Obx(() {
            final count = cartController.itemCount;
            if (count == 0) return const SizedBox.shrink();
            return Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: kAccentColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              child: Center(
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: const Icon(
              Iconsax.heart_slash,
              size: 60,
              color: Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Your Wishlist is Empty',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Items you save will appear here.\nStart exploring our collections!",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
              fontFamily: 'Poppins',
              height: 1.5,
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () => Get.back(),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 8,
              shadowColor: kPrimaryColor.withValues(alpha: 0.4),
            ),
            child: const Text(
              "Explore Products",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// HELPER: PRICE CALCULATOR (Performance Optimization)
// -----------------------------------------------------------------------------
class _PriceInfo {
  final double price;
  final double regularPrice;
  final double resellPrice;
  final double? profit;
  final bool hasDiscount;

  _PriceInfo({
    required this.price,
    required this.regularPrice,
    required this.resellPrice,
    this.profit,
    required this.hasDiscount,
  });

  factory _PriceInfo.fromProduct(ProductModel product) {
    double parse(String v) =>
        double.tryParse(v.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;

    final double price = parse(product.price);
    final double regularPrice = product.regularPrice.isNotEmpty
        ? parse(product.regularPrice)
        : 0;

    final double resellPrice = price * 1.3;
    final double? profit = (resellPrice > price) ? (resellPrice - price) : null;
    final bool hasDiscount = regularPrice > price;

    return _PriceInfo(
      price: price,
      regularPrice: regularPrice,
      resellPrice: resellPrice,
      profit: profit,
      hasDiscount: hasDiscount,
    );
  }
}

// -----------------------------------------------------------------------------
// RICH RESELLER CARD (OPTIMIZED)
// -----------------------------------------------------------------------------
class _WishlistResellerCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onRemove;
  final VoidCallback onAddToCart;

  const _WishlistResellerCard({
    super.key,
    required this.product,
    required this.onRemove,
    required this.onAddToCart,
  });

  // CONSTANTS
  static const Color kPrimaryColor = Color(0xFF4A317E);
  static const Color kAccentColor = Color(0xFFEB2A7E);
  static const Color kGreen = Color(0xFF16A34A);
  static const Color kBlack = Color(0xFF1F2937);

  @override
  Widget build(BuildContext context) {
    // Calculate prices once per build (lightweight now)
    final prices = _PriceInfo.fromProduct(product);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. IMAGE SECTION (65%)
            Expanded(
              flex: 65,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // PERFORMANCE: Explicit Cache Width (Thumbnail size)
                  Image.network(
                    product.image,
                    fit: BoxFit.cover,
                    cacheWidth: 350, // Huge RAM saver
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade100,
                      child: const Icon(Iconsax.image, color: Colors.grey),
                    ),
                  ),

                  // Gradient Overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.1),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // DISCOUNT BADGE
                  if (product.discountPercentage != null &&
                      product.discountPercentage! > 0)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: kAccentColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "${product.discountPercentage}% OFF",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),

                  // REMOVE BUTTON (Top Right)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: onRemove,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 14,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. DETAILS SECTION (35%)
            Expanded(
              flex: 35,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // INFO
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: SizedBox(
                              width: constraints.maxWidth,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Name
                                  Text(
                                    product.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: kBlack,
                                    ),
                                  ),
                                  const SizedBox(height: 2),

                                  // Buy Price
                                  Row(
                                    children: [
                                      const AutoTranslate(
                                        child: Text(
                                          "Buy ",
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF6B7280),
                                          ),
                                        ),
                                      ),
                                      Text(
                                        "₹${prices.price.toStringAsFixed(0)}",
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: kPrimaryColor,
                                        ),
                                      ),
                                      if (prices.hasDiscount) ...[
                                        const SizedBox(width: 4),
                                        Text(
                                          "₹${prices.regularPrice.toStringAsFixed(0)}",
                                          style: TextStyle(
                                            fontSize: 12,
                                            decoration:
                                                TextDecoration.lineThrough,
                                            color: Colors.grey.shade400,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),

                                  // Resell & Profit
                                  Row(
                                    children: [
                                      const AutoTranslate(
                                        child: Text(
                                          "Resell ",
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF88878B),
                                          ),
                                        ),
                                      ),
                                      Text(
                                        "₹${prices.resellPrice.toStringAsFixed(0)}",
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF88878B),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (prices.profit != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFDCFCE7),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Iconsax.trend_up,
                                                size: 10,
                                                color: kGreen,
                                              ),
                                              const SizedBox(width: 2),
                                              Text(
                                                "+₹${prices.profit!.toStringAsFixed(0)}",
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: kGreen,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // BUTTON (ADD TO CART)
                    SizedBox(
                      width: double.infinity,
                      height: 32,
                      child: ElevatedButton(
                        onPressed: onAddToCart,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Iconsax.shopping_bag,
                              size: 14,
                              color: Colors.white,
                            ),
                            SizedBox(width: 6),
                            Text(
                              "Move to Cart",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
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
          ],
        ),
      ),
    );
  }
}
