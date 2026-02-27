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
  final int? configProductCount;
  final String? configOrderBy;
  final int? configCategoryId;
  final String? configTitle;
  const RecommendedSection({
    super.key,
    this.configProductCount,
    this.configOrderBy,
    this.configCategoryId,
    this.configTitle,
  });

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
      duration: const Duration(seconds: 26), // visible, smooth
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
      final count = widget.configProductCount ?? 15;
      final orderBy = widget.configOrderBy ?? 'popularity';
      final catId = widget.configCategoryId;
      List<ProductModel> products;
      if (catId != null && catId > 0) {
        products = await ApiService().fetchProductsByCategory(
          catId,
          orderBy: orderBy,
          order: orderBy == 'price' ? 'asc' : 'desc',
        );
        if (products.length > count) products = products.sublist(0, count);
      } else {
        products = await ApiService().fetchProducts(
          perPage: count,
          orderBy: orderBy,
          order: orderBy == 'price' ? 'asc' : 'desc',
        );
      }
      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showPremiumPopup(ProductModel product) {
    Get.snackbar(
      '',
      '',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.only(bottom: 20, left: 12, right: 12),
      padding: const EdgeInsets.all(16),
      borderRadius: 24,
      backgroundColor: Colors.white.withValues(alpha: 0.96),
      barBlur: 20,
      boxShadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ],
      titleText: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: NetworkImage(product.image),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Added to Cart",
                  textScaleFactor: 1.0, // Lock font scaling
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                    color: _kPrimary,
                  ),
                ),
                Text(
                  product.name,
                  textScaleFactor: 1.0, // Lock font scaling
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      messageText: const SizedBox.shrink(),
      mainButton: TextButton(
        onPressed: () => Get.to(() => const InventoryPage()),
        child: const Text(
          "View",
          textScaleFactor: 1.0, // Lock font scaling
          style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w700),
        ),
      ),
      duration: const Duration(seconds: 3),
    );
  }

  String _calculateRsp(String priceString) {
    try {
      final cleaned = priceString.replaceAll(RegExp(r'[^0-9.]'), '');
      final double price = double.parse(cleaned);
      return '₹${(price * 1.30).round()}';
    } catch (_) {
      return priceString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // HEADER
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 26,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFc7d2fe), Color(0xFFa5f3fc)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ShaderMask(
                  shaderCallback: (rect) {
                    return const LinearGradient(
                      colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ).createShader(rect);
                  },
                  child: Text(
                    widget.configTitle ?? 'Featured Products',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  Get.to(
                    () => AllProductsScreen(
                      title: widget.configTitle ?? "Featured Products",
                      initialOrderBy: 'popularity',
                      initialOrder: 'desc',
                    ),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'View all',
                      textScaleFactor: 1.0, // Lock font scaling
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Iconsax.arrow_right_3, size: 14),
                  ],
                ),
              ),
            ],
          ),
        ),

        // AURORA FLOW BACKGROUND + LIST
        SizedBox(
          height: 190,
          child: AnimatedBuilder(
            animation: _bgController,
            builder: (_, __) {
              return Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: LightAuroraFlowPainter(_bgController.value),
                    ),
                  ),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(left: 16),
                      itemCount: _products.length,
                      itemBuilder: (_, index) {
                        final product = _products[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: HorizontalProductCard(
                            imageUrl: product.image,
                            title: product.name,
                            price: '₹${product.price}',
                            rsp: _calculateRsp(product.price),
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
                                duration: const Duration(milliseconds: 280),
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
        const SizedBox(height: 10),
      ],
    );
  }
}

/// ---------------------------------------------------------------------------
/// OPTION B — LIGHT AURORA FLOW (VISIBLE, SMOOTH, NON-DARK)
/// ---------------------------------------------------------------------------
class LightAuroraFlowPainter extends CustomPainter {
  final double t;
  LightAuroraFlowPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    // Base light surface
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFF8FAFC),
    );

    _auroraWave(
      canvas,
      size,
      color: const Color(0xFFc7d2fe),
      heightFactor: 0.55,
      phase: 0,
    );

    _auroraWave(
      canvas,
      size,
      color: const Color(0xFFa5f3fc),
      heightFactor: 0.72,
      phase: math.pi / 2,
    );

    _auroraWave(
      canvas,
      size,
      color: const Color(0xFFfde68a),
      heightFactor: 0.85,
      phase: math.pi,
    );
  }

  void _auroraWave(
    Canvas canvas,
    Size size, {
    required Color color,
    required double heightFactor,
    required double phase,
  }) {
    final path = Path();
    final baseY = size.height * heightFactor;

    path.moveTo(0, baseY);

    const int segments = 48;
    for (int i = 0; i <= segments; i++) {
      final tX = i / segments;
      final x = size.width * tX;

      final y =
          baseY + math.sin((t * 2 * math.pi) + tX * math.pi * 2 + phase) * 22;

      path.lineTo(x, y);
    }

    path
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.30));
  }

  @override
  bool shouldRepaint(covariant LightAuroraFlowPainter oldDelegate) {
    return oldDelegate.t != t;
  }
}
