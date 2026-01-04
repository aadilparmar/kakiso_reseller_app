// lib/screens/dashboard/wishlist/wishlist_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_auto_translate/flutter_auto_translate.dart';

import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/controllers/wishlist_controller.dart';
import 'package:kakiso_reseller_app/controllers/cart_controller.dart';
import 'package:kakiso_reseller_app/controllers/shared_products_controller.dart'; // NEW
import 'package:kakiso_reseller_app/screens/dashboard/my_cart/my_cart.dart';

// -----------------------------------------------------------------------------
// RECENTLY VIEWED CONTROLLER
// -----------------------------------------------------------------------------
class RecentlyViewedController extends GetxController {
  static RecentlyViewedController get instance => Get.find();
  final _storage = GetStorage();
  var recentlyViewed = <ProductModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadFromStorage();
  }

  void addToRecentlyViewed(ProductModel product) {
    recentlyViewed.removeWhere((item) => item.id == product.id);
    recentlyViewed.insert(0, product);
    if (recentlyViewed.length > 20) recentlyViewed.removeLast();
    _saveToStorage();
  }

  void _saveToStorage() {
    final List<dynamic> data = recentlyViewed.map((e) => e.toJson()).toList();
    _storage.write('recently_viewed_history', data);
  }

  void _loadFromStorage() {
    final List<dynamic>? data = _storage.read('recently_viewed_history');
    if (data != null) {
      recentlyViewed.assignAll(
        data.map((e) => ProductModel.fromJson(e)).toList(),
      );
    }
  }
}

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen>
    with SingleTickerProviderStateMixin {
  // --- CONTROLLERS ---
  final WishlistController wishlistController = Get.put(
    WishlistController(),
    permanent: true,
  );
  final CartController cartController = Get.put(
    CartController(),
    permanent: true,
  );
  final RecentlyViewedController recentlyViewedController = Get.put(
    RecentlyViewedController(),
  );
  final SharedProductsController sharedProductsController = Get.put(
    SharedProductsController(),
  );

  // --- TAB CONTROLLER ---
  late TabController _tabController;

  static const Color kPrimaryColor = Color(0xFF4A317E);
  static const Color kAccentColor = Color(0xFFEB2A7E);
  static const Color kBgColor = Color(0xFFF3F4F6);

  OverlayEntry? _currentSnackbar;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
    ); // Length updated to 3
  }

  @override
  void dispose() {
    _removeSnackbar();
    _tabController.dispose();
    super.dispose();
  }

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
                builder: (context, value, child) => Transform.translate(
                  offset: Offset(0, 40 * (1 - value)),
                  child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F2937).withOpacity(0.95),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
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
                            child: Text(
                              "Moved to Cart",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              _removeSnackbar();
                              Get.to(() => const InventoryPage());
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                            ),
                            child: const Text("View"),
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        centerTitle: true,
        title: const Text(
          "Wishlist",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 20,
            fontFamily: 'Poppins',
          ),
        ),
        actions: [_buildCartBadge(), const SizedBox(width: 12)],
        bottom: TabBar(
          controller: _tabController,
          labelColor: kPrimaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: kPrimaryColor,
          indicatorWeight: 3,
          isScrollable: true, // Recommended for 3 tabs to avoid cramped text
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
          ),
          tabs: const [
            Tab(text: "My Wishlist"),
            Tab(text: "Recently Viewed"),
            Tab(text: "Shared Items"), // NEW TAB
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: WISHLIST
          _buildProductGrid(
            wishlistController.wishlistItems,
            "Your wishlist is empty",
          ),

          // TAB 2: RECENTLY VIEWED
          _buildProductGrid(
            recentlyViewedController.recentlyViewed,
            "No recent history",
          ),

          // TAB 3: SHARED ITEMS
          _buildProductGrid(
            sharedProductsController.sharedItems,
            "No shared products yet",
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid(RxList<ProductModel> items, String emptyMsg) {
    return Obx(() {
      if (items.isEmpty) return _buildEmptyState(emptyMsg);
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.55,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final product = items[index];
          return RepaintBoundary(
            child: _WishlistResellerCard(
              key: ValueKey("grid_${_tabController.index}_${product.id}"),
              product: product,
              onRemove: () {
                HapticFeedback.lightImpact();
                // Logic handles all three tabs
                if (_tabController.index == 0) {
                  wishlistController.removeFromWishlist(product.id);
                } else if (_tabController.index == 1) {
                  recentlyViewedController.recentlyViewed.removeAt(index);
                } else {
                  sharedProductsController.sharedItems.removeAt(index);
                }
              },
              onAddToCart: () {
                HapticFeedback.mediumImpact();
                cartController.addToCart(product);
                _showConversionSnackbar(product);
              },
            ),
          );
        },
      );
    });
  }

  Widget _buildCartBadge() {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Iconsax.bag_2, size: 26, color: Colors.black),
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
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Iconsax.heart_slash, size: 60, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: Colors.grey, fontFamily: 'Poppins'),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// INITIAL PRICE CALCULATOR (RESTORED - EXACTLY AS PROVIDED)
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
    return _PriceInfo(
      price: price,
      regularPrice: regularPrice,
      resellPrice: resellPrice,
      profit: (resellPrice > price) ? (resellPrice - price) : null,
      hasDiscount: regularPrice > price,
    );
  }
}

// -----------------------------------------------------------------------------
// THE INITIAL PRODUCT CARD (RESTORED EXACTLY - NO CHANGES TO LAYOUT)
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

  static const Color kPrimaryColor = Color(0xFF4A317E);
  static const Color kAccentColor = Color(0xFFEB2A7E);
  static const Color kGreen = Color(0xFF16A34A);
  static const Color kBlack = Color(0xFF1F2937);

  @override
  Widget build(BuildContext context) {
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
            Expanded(
              flex: 65,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    product.image,
                    fit: BoxFit.cover,
                    cacheWidth: 350,
                  ),
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
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: onRemove,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
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
            Expanded(
              flex: 35,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) => FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                            width: constraints.maxWidth,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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
                                        child: Text(
                                          "+₹${prices.profit!.toStringAsFixed(0)}",
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: kGreen,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      height: 32,
                      child: ElevatedButton(
                        onPressed: onAddToCart,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Iconsax.shopping_bag, size: 14),
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
