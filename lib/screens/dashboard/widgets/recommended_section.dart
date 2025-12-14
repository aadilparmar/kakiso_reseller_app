import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/controllers/cart_controller.dart';
import 'package:kakiso_reseller_app/screens/dashboard/product/product_details_page.dart';
import 'package:kakiso_reseller_app/screens/dashboard/widgets/all_product_screen.dart';
import 'package:kakiso_reseller_app/screens/dashboard/widgets/horizontal_product_card.dart';
import 'package:kakiso_reseller_app/screens/dashboard/my_cart/my_cart.dart';
import 'package:kakiso_reseller_app/services/api_services.dart';

const Color _kPrimary = Color(0xFF4A317E);

class RecommendedSection extends StatefulWidget {
  const RecommendedSection({super.key});

  @override
  State<RecommendedSection> createState() => _RecommendedSectionState();
}

class _RecommendedSectionState extends State<RecommendedSection>
    with SingleTickerProviderStateMixin {
  final CartController cartController = Get.put(CartController());
  List<ProductModel> _products = [];
  bool _isLoading = true;

  late final AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    )..repeat();
    _fetchProducts();
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    try {
      final products = await ApiService.fetchProducts(
        perPage: 15,
        orderBy: 'popularity',
        order: 'desc',
      );
      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
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
                    color: _kPrimary,
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
              style: TextStyle(color: _kPrimary, fontWeight: FontWeight.bold),
            ),
            SizedBox(width: 4),
            Icon(Iconsax.arrow_right_3, size: 16, color: _kPrimary),
          ],
        ),
      ),
      duration: const Duration(seconds: 3),
    );
  }

  // --- HELPER: Parse and Calculate RSP (Price + 30%) ---
  String _calculateRsp(String priceString) {
    try {
      final cleaned = priceString.replaceAll(RegExp(r'[^0-9.]'), '');
      if (cleaned.isEmpty) return '₹0';

      final double price = double.parse(cleaned);
      final double rspValue = price * 1.30;
      return '₹${rspValue.round()}';
    } catch (_) {
      return priceString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- HEADER ---
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  // Soft holo accent bar
                  Container(
                    width: 4,
                    height: 26,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFa855f7), Color(0xFF22d3ee)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Featured',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                      fontFamily: 'Poppins',
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 6),
                  ShaderMask(
                    shaderCallback: (rect) {
                      return const LinearGradient(
                        colors: [Color(0xFFa855f7), Color(0xFF22d3ee)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(rect);
                    },
                    child: const Text(
                      'Products',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        fontFamily: 'Poppins',
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF22d3ee), Color(0xFFa855f7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF22d3ee,
                          ).withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Iconsax.heart5,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  Get.to(
                    () => const AllProductsScreen(
                      title: "Featured Products",
                      initialOrderBy: 'popularity',
                      initialOrder: 'desc',
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.purpleAccent.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: const [
                      Text(
                        'View All',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4B5563),
                          fontFamily: 'Poppins',
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Iconsax.arrow_right_3,
                        size: 14,
                        color: Color(0xFF4B5563),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // --- AURORA / HOLOGRAPHIC BACKGROUND + HORIZONTAL LIST ---
        SizedBox(
          height: 190,
          child: AnimatedBuilder(
            animation: _bgController,
            builder: (context, _) {
              final progress = _bgController.value;
              return Stack(
                children: [
                  // Aurora animated background
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _AuroraWavePainter(progress: progress),
                      ),
                    ),
                  ),

                  // Content
                  if (_isLoading)
                    const Center(
                      child: CircularProgressIndicator(color: _kPrimary),
                    )
                  else if (_products.isEmpty)
                    const Center(
                      child: Text(
                        "No recommendations found.",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(left: 16, right: 12),
                      itemCount: _products.length,
                      itemBuilder: (context, index) {
                        final product = _products[index];
                        final String calculatedRsp = _calculateRsp(
                          product.price,
                        );

                        return Padding(
                          padding: const EdgeInsets.only(right: 10.0),
                          child: HorizontalProductCard(
                            imageUrl: product.image,
                            title: product.name,
                            companyName: "Kakiso",
                            price: '₹${product.price}',
                            rsp: calculatedRsp,
                            originalPrice: product.regularPrice.isNotEmpty
                                ? '₹${product.regularPrice}'
                                : '',
                            discountPercentage: product.discountPercentage,
                            onAddToCartPressed: () {
                              cartController.addToCart(product);
                              _showPremiumPopup(product);
                            },
                            onPressed: () {
                              Get.to(
                                () => ProductDetailsPage(product: product),
                                transition: Transition.fadeIn,
                                duration: const Duration(milliseconds: 300),
                              );
                            },
                          ),
                        );
                      },
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

/// ---------------------------------------------------------------------------
/// AURORA / HOLOGRAPHIC WAVE BACKGROUND PAINTER
/// ---------------------------------------------------------------------------
class _AuroraWavePainter extends CustomPainter {
  final double progress; // 0 → 1 loop

  _AuroraWavePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint();

    // ---------- 1. BASE BACKGROUND GRADIENT ----------
    final Rect bgRect = Rect.fromLTWH(0, 0, size.width, size.height);
    paint.shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF020617), // dark navy
        Color(0xFF111827),
        Color(0xFF1f2937),
      ],
    ).createShader(bgRect);
    canvas.drawRect(bgRect, paint);

    // ---------- 2. AURORA WAVE RIBBONS ----------
    // We'll draw 3 layered waves, each with slightly different color & phase.

    _drawWave(
      canvas,
      size,
      color: const Color(0xFF22d3ee).withValues(alpha: 0.55),
      baseHeightFactor: 0.55,
      amplitude: 24,
      phaseShift: progress * 2 * math.pi,
    );

    _drawWave(
      canvas,
      size,
      color: const Color(0xFFa855f7).withValues(alpha: 0.40),
      baseHeightFactor: 0.68,
      amplitude: 30,
      phaseShift: progress * 2 * math.pi + math.pi / 2,
    );

    _drawWave(
      canvas,
      size,
      color: const Color(0xFFf97316).withValues(alpha: 0.28),
      baseHeightFactor: 0.80,
      amplitude: 18,
      phaseShift: progress * 2 * math.pi + math.pi,
    );

    // ---------- 3. FLOATING PARTICLES ----------
    final Paint dotPaint = Paint();
    final int dots = 24;

    for (int i = 0; i < dots; i++) {
      final t = i / dots;
      final double x = size.width * t;
      final double yBase = size.height * (0.25 + 0.5 * t);
      final double yOffset = math.sin(progress * 4 * math.pi + i * 0.7) * 10;
      final double y = yBase + yOffset;

      final double alphaFactor =
          0.4 + 0.6 * (0.5 + 0.5 * math.sin(progress * 6 * math.pi + i));

      dotPaint.color = Colors.white.withValues(alpha: 0.09 * alphaFactor);
      canvas.drawCircle(Offset(x, y), 1.6, dotPaint);
    }

    // ---------- 4. TOP SOFT GLOW ----------
    final Paint glowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.0, -0.9),
        radius: 1.1,
        colors: [
          const Color(0xFF22d3ee).withValues(alpha: 0.35),
          Colors.transparent,
        ],
      ).createShader(bgRect);
    canvas.drawRect(bgRect, glowPaint);
  }

  void _drawWave(
    Canvas canvas,
    Size size, {
    required Color color,
    required double baseHeightFactor,
    required double amplitude,
    required double phaseShift,
  }) {
    final Path path = Path();
    final double baseY = size.height * baseHeightFactor;

    path.moveTo(0, baseY);

    const int segments = 40;
    for (int i = 0; i <= segments; i++) {
      final double t = i / segments;
      final double x = size.width * t;

      // nice smooth sine-based wave
      final double wave = math.sin((t * 3 * math.pi) + phaseShift) * amplitude;
      final double y = baseY + wave;

      path.lineTo(x, y);
    }

    // Close wave to bottom
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    final Paint p = Paint()
      ..shader =
          LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color, color.withValues(alpha: 0.02)],
          ).createShader(
            Rect.fromLTWH(0, baseY - amplitude * 2, size.width, amplitude * 3),
          );

    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant _AuroraWavePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
