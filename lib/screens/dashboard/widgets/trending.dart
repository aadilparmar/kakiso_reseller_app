import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/screens/dashboard/product/product_details_page.dart';
import 'package:kakiso_reseller_app/screens/dashboard/widgets/all_product_screen.dart';
import 'package:kakiso_reseller_app/services/api_services.dart';
import 'package:kakiso_reseller_app/controllers/cart_controller.dart';

// --- IMPORT NAVIGATION PAGES ---
import 'package:kakiso_reseller_app/screens/dashboard/my_cart/my_cart.dart';

class TrendingCard extends StatelessWidget {
  final ProductModel product;
  final int index;
  final double scaleFactor; // Added for dynamic scaling

  const TrendingCard({
    super.key,
    required this.product,
    required this.index,
    this.scaleFactor = 1.0,
  });

  void _showPremiumPopup(ProductModel product) {
    Get.snackbar(
      '',
      '',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.only(bottom: 20, left: 10, right: 10),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      borderRadius: 24,
      backgroundColor: Colors.white.withValues(alpha: 0.95),
      barBlur: 20,
      colorText: Colors.black,
      duration: const Duration(seconds: 3),
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
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'Poppins',
                    color: Colors.black87,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final CartController cartController = Get.put(CartController());

    // Calculate dynamic dimensions
    final double cardWidth = 160 * scaleFactor;
    final double imageHeight = 160 * scaleFactor;

    return GestureDetector(
      onTap: () {
        Get.to(
          () => ProductDetailsPage(product: product),
          transition: Transition.fadeIn,
          duration: const Duration(milliseconds: 300),
        );
      },
      child: Container(
        width: cardWidth,
        margin: const EdgeInsets.only(right: 16, bottom: 12, top: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4A317E).withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Pack tightly
          children: [
            Stack(
              children: [
                Container(
                  height: imageHeight,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    color: Colors.grey[50],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: Image.network(
                      product.image,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) =>
                          const Icon(Icons.image, color: Colors.grey),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 10,
                  child: Text(
                    "${index + 1}".padLeft(2, '0'),
                    style: TextStyle(
                      fontSize: 40 * scaleFactor, // Scale the rank number too
                      fontWeight: FontWeight.w900,
                      color: Colors.white.withValues(alpha: 0.8),
                      fontFamily: 'Poppins',
                      shadows: const [
                        Shadow(
                          blurRadius: 4,
                          color: Colors.black26,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // --- DETAILS ---
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                      fontFamily: 'Poppins',
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Price & Action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Flexible wrapper prevents price from pushing button off-screen
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Buy ₹${product.price}",
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF4A317E),
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // --- ADD BUTTON ---
                      Material(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            cartController.addToCart(product);
                            _showPremiumPopup(product);
                          },
                          child: Container(
                            width:
                                28 *
                                scaleFactor, // Slightly larger button touch area
                            height: 28 * scaleFactor,
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 18 * scaleFactor,
                            ),
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
    );
  }
}

// --- 2. MAIN SECTION ---
class TrendingProducts extends StatefulWidget {
  const TrendingProducts({super.key});

  @override
  State<TrendingProducts> createState() => _TrendingProductsState();
}

class _TrendingProductsState extends State<TrendingProducts>
    with SingleTickerProviderStateMixin {
  late final ScrollController _scrollController;
  List<ProductModel> _products = [];
  bool _isLoading = true;

  late final AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _fetchTrendingProducts();
  }

  Future<void> _fetchTrendingProducts() async {
    try {
      final products = await ApiService().fetchTrendingProducts();
      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint("Error fetching trending products: $e");
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // --- SCALING LOGIC ---
    // Calculate scaler, capped at 1.4x for safety
    final double textScale = MediaQuery.textScalerOf(context).scale(1);
    final double scaleFactor = math.max(1.0, math.min(textScale, 1.4));

    // Base height (was 270) scaled up
    final double sectionHeight = 280.0 * scaleFactor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- HEADER ---
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Use Flexible to prevent overlap with "View All"
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
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
                    const Flexible(
                      child: Text(
                        'Trending on',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    ShaderMask(
                      shaderCallback: (rect) {
                        return const LinearGradient(
                          colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ).createShader(rect);
                      },
                      child: const Text(
                        'KaKiSo',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEDD5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Iconsax.trend_up,
                        color: Color(0xFFFB923C),
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
              // --- VIEW ALL BUTTON ---
              GestureDetector(
                onTap: () {
                  Get.to(
                    () => const AllProductsScreen(
                      title: "Trending Now",
                      initialOrderBy: 'popularity',
                      initialOrder: 'desc',
                    ),
                  );
                },
                child: Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
        ),

        // --- HORIZONTAL LIST + ANIMATED BLOB BACKGROUND ---
        SizedBox(
          height: sectionHeight, // Dynamic height
          child: AnimatedBuilder(
            animation: _bgController,
            builder: (context, _) {
              final progress = _bgController.value;

              return Stack(
                children: [
                  // Background
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _BlobBackgroundPainter(progress: progress),
                      ),
                    ),
                  ),

                  // Foreground content
                  if (_isLoading)
                    const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFEB2A7E),
                      ),
                    )
                  else if (_products.isEmpty)
                    const Center(
                      child: Text(
                        "No trending items.",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(left: 16),
                      itemCount: _products.length,
                      itemBuilder: (context, index) {
                        final product = _products[index];
                        return TrendingCard(
                          product: product,
                          index: index,
                          scaleFactor: scaleFactor, // Pass scaler to card
                        );
                      },
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// ------------------------------------------------------------
/// Soft Blurry Color Blobs Background
/// ------------------------------------------------------------
class _BlobBackgroundPainter extends CustomPainter {
  final double progress; // 0 → 1 loop

  _BlobBackgroundPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint();

    // 1. Base subtle gradient background
    final Rect bgRect = Rect.fromLTWH(0, 0, size.width, size.height);
    paint.shader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFF9FAFB), Color(0xFFFDF2FF)],
    ).createShader(bgRect);
    canvas.drawRect(bgRect, paint);

    // 2. Soft color blobs
    _drawBlob(
      canvas,
      size,
      center: Offset(
        size.width * (0.15 + 0.05 * math.sin(progress * 2 * math.pi)),
        size.height * 0.3,
      ),
      radius: size.width * 0.32,
      color: const Color(0xFFEC4899).withValues(alpha: 0.24),
    );

    _drawBlob(
      canvas,
      size,
      center: Offset(
        size.width * (0.55 + 0.06 * math.cos(progress * 2 * math.pi)),
        size.height * 0.15,
      ),
      radius: size.width * 0.30,
      color: const Color(0xFF8B5CF6).withValues(alpha: 0.26),
    );

    _drawBlob(
      canvas,
      size,
      center: Offset(
        size.width * (0.85 + 0.04 * math.sin(progress * 2 * math.pi + 1.4)),
        size.height * 0.45,
      ),
      radius: size.width * 0.28,
      color: const Color(0xFF22C7D5).withValues(alpha: 0.22),
    );

    // 3. Tiny floating dots
    final int dots = 26;
    final Paint dotPaint = Paint();
    for (int i = 0; i < dots; i++) {
      final double t = i / dots;
      final double baseX = size.width * t;
      final double baseY = size.height * (0.2 + 0.5 * t);

      final double yOffset = math.sin(progress * 4 * math.pi + i * 0.7) * 6.0;
      final double xOffset = math.cos(progress * 3 * math.pi + i * 0.9) * 4.0;

      final double x = baseX + xOffset;
      final double y = baseY + yOffset;

      final double alphaFactor =
          0.35 + 0.65 * (0.5 + 0.5 * math.sin(progress * 6 * math.pi + i));

      dotPaint.color = Colors.white.withValues(alpha: 0.10 * alphaFactor);

      canvas.drawCircle(Offset(x, y), 1.5, dotPaint);
    }

    // 4. Soft glow strip at bottom
    final Paint glowPaint = Paint()
      ..shader =
          LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              const Color(0xFFEC4899).withValues(alpha: 0.14),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromLTWH(
              0,
              size.height * 0.55,
              size.width,
              size.height * 0.45,
            ),
          );
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.55, size.width, size.height * 0.45),
      glowPaint,
    );
  }

  void _drawBlob(
    Canvas canvas,
    Size size, {
    required Offset center,
    required double radius,
    required Color color,
  }) {
    final Rect rect = Rect.fromCircle(center: center, radius: radius);
    final Paint p = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.9,
        colors: [color, color.withValues(alpha: 0.0)],
      ).createShader(rect);
    canvas.drawCircle(center, radius, p);
  }

  @override
  bool shouldRepaint(covariant _BlobBackgroundPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
