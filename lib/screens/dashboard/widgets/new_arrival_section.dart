import 'dart:math' as math; // Added for max/min clamping
import 'dart:ui'; // Required for ImageFilter
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

// --- MODEL & CONTROLLER ---
import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/controllers/cart_controller.dart';
import 'package:kakiso_reseller_app/screens/dashboard/product/product_details_page.dart';
import 'package:kakiso_reseller_app/screens/dashboard/widgets/all_product_screen.dart';
import 'package:kakiso_reseller_app/services/api_services.dart';

// --- SCREENS ---
import 'package:kakiso_reseller_app/screens/dashboard/my_cart/my_cart.dart';

class NewArrivalSection extends StatefulWidget {
  final int? configProductCount;
  final int? configCategoryId;
  final String? configTitle;
  const NewArrivalSection({
    super.key,
    this.configProductCount,
    this.configCategoryId,
    this.configTitle,
  });

  @override
  State<NewArrivalSection> createState() => _NewArrivalSectionState();
}

class _NewArrivalSectionState extends State<NewArrivalSection> {
  final CartController cartController = Get.put(CartController());
  List<ProductModel> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNewestProducts();
  }

  Future<void> _fetchNewestProducts() async {
    try {
      final catId = widget.configCategoryId;
      final count = widget.configProductCount ?? 10;
      List<ProductModel> products;
      if (catId != null && catId > 0) {
        products = await ApiService().fetchProductsByCategory(
          catId,
          orderBy: 'date',
          order: 'desc',
        );
        if (products.length > count) products = products.sublist(0, count);
      } else {
        products = await ApiService().fetchProducts(
          perPage: count,
          orderBy: 'date',
          order: 'desc',
        );
      }
      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint("Error fetching newest products: $e");
    }
  }

  // --- HELPER: Show Premium Popup ---
  void _showPremiumPopup(ProductModel product) {
    Get.snackbar(
      '',
      '',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.only(bottom: 20, left: 10, right: 10),
      padding: const EdgeInsets.all(16),
      borderRadius: 24,
      backgroundColor: Colors.white.withValues(alpha: 0.95),
      barBlur: 20,
      colorText: Colors.black,
      boxShadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 20,
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
              image: DecorationImage(
                image: NetworkImage(product.image),
                fit: BoxFit.cover,
              ),
              border: Border.all(color: Colors.grey.shade200),
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
                Text(
                  product.name,
                  style: const TextStyle(fontSize: 12, fontFamily: 'Poppins'),
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
        child: const Row(
          children: [
            Text(
              "View",
              style: TextStyle(
                color: Color(0xFF4A317E),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 4),
            Icon(Iconsax.arrow_right_3, size: 16, color: Color(0xFF4A317E)),
          ],
        ),
      ),
      duration: const Duration(seconds: 3),
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- SCALING LOGIC ---
    // Calculate a scaler based on text size, capped at 1.4x to prevent breaking layout entirely
    final double textScale = MediaQuery.textScalerOf(context).scale(1);
    final double scaleFactor = math.max(1.0, math.min(textScale, 1.4));

    // Base heights that scale
    final double sectionHeight = 320.0 * scaleFactor;
    final double cardHeight = 300.0 * scaleFactor;
    // ---------------------

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- HEADER ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEB2A7E),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ShaderMask(
                        shaderCallback: (rect) {
                          return const LinearGradient(
                            colors: [
                              Color.fromARGB(255, 236, 80, 72),
                              Color.fromARGB(255, 246, 131, 92),
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ).createShader(rect);
                        },
                        child: Text(
                          '${widget.configTitle ?? 'Fresh Drops'} 🔥',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  // --- NAVIGATION LOGIC ---
                  Get.to(
                    () => AllProductsScreen(
                      title: widget.configTitle ?? "Fresh Drops",
                      initialOrderBy: 'date',
                      initialOrder: 'desc',
                    ),
                  );
                },
                child: const Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFEB2A7E),
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
        ),

        // --- LIST ---
        SizedBox(
          height: sectionHeight,
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFEB2A7E)),
                )
              : _products.isEmpty
              ? const Center(child: Text("No fresh drops yet."))
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: 16),
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    return EditorialProductCard(
                      product: product,
                      width:
                          200, // Width is generally fine fixed, but height needs to breathe
                      height: cardHeight,
                      scaleFactor: scaleFactor, // Pass scaler down
                      // 1. ADD TO CART
                      onAddToCart: () {
                        cartController.addToCart(product);
                        _showPremiumPopup(product);
                      },

                      // 2. NAVIGATION ACTION
                      onPressed: () {
                        Get.to(
                          () => ProductDetailsPage(product: product),
                          transition: Transition.fadeIn,
                          duration: const Duration(milliseconds: 300),
                        );
                      },
                    );
                  },
                ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// --- WORLD CLASS CARD WIDGET ---
class EditorialProductCard extends StatelessWidget {
  final ProductModel product;
  final double width;
  final double height;
  final double scaleFactor; // Received from parent
  final VoidCallback onAddToCart;
  final VoidCallback? onPressed;

  const EditorialProductCard({
    super.key,
    required this.product,
    required this.onAddToCart,
    this.width = 180.0,
    this.height = 280.0,
    this.scaleFactor = 1.0,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Dynamically scale the gradient height so it covers larger text
    final double gradientHeight = 140 * scaleFactor;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: width,
        height: height,
        margin: const EdgeInsets.only(right: 16, bottom: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // --- A. BACKGROUND IMAGE ---
              Positioned.fill(
                child: Image.network(
                  product.image,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => Container(
                    color: Colors.grey[100],
                    child: const Icon(
                      Icons.image_not_supported,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),

              // --- B. GRADIENT OVERLAY (Dynamic Height) ---
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: gradientHeight,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.6),
                        Colors.black.withValues(alpha: 0.9),
                      ],
                    ),
                  ),
                ),
              ),

              // --- C. "NEW DROP" BADGE ---
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C853),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00C853).withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Text(
                    "NEW DROP",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Poppins',
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

              // --- E. CONTENT ---
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Pack tightly
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "KAKISO EXCLUSIVE",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),

                    // Price Tag & Add Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Price Pill (Flexible to prevent overflow)
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    "BUY ₹${product.price}",
                                    maxLines: 1,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // --- ACTIVE ADD BUTTON (Separate Gesture) ---
                        GestureDetector(
                          onTap: onAddToCart, // Independent cart action
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Iconsax.add,
                              size: 20,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
