import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/services/api_services.dart';
import 'package:kakiso_reseller_app/screens/dashboard/product/product_details_page.dart';

const Color _kPrimary = Color(0xFF4A317E);
const Color _kAccent = Color(0xFFEB2A7E);

class TopRankingSection extends StatefulWidget {
  const TopRankingSection({super.key});

  @override
  State<TopRankingSection> createState() => _TopRankingSectionState();
}

class _TopRankingSectionState extends State<TopRankingSection>
    with SingleTickerProviderStateMixin {
  List<ProductModel> _products = [];
  bool _isLoading = true;
  String _selectedTab = 'Top'; // "Top" or "Hot"
  int _currentIndex = 0;

  final PageController _pageController = PageController(
    viewportFraction: 0.80,
    keepPage: true,
  );

  late final AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();

    _fetchProductsForTab(_selectedTab);
    _pageController.addListener(_onPageScroll);
  }

  void _onPageScroll() {
    final page = _pageController.page ?? 0.0;
    final index = page.round();
    if (index != _currentIndex && index >= 0 && index < _products.length) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  Future<void> _fetchProductsForTab(String tabName) async {
    setState(() {
      _isLoading = true;
      _selectedTab = tabName;
      _currentIndex = 0;
    });

    try {
      List<ProductModel> products;
      if (tabName == 'Top') {
        products = await ApiService.fetchTopRankingProducts();
      } else {
        products = await ApiService.fetchHotRankingProducts();
      }

      if (!mounted) return;

      setState(() {
        _products = products;
        _isLoading = false;
      });

      // Reset page position
      if (_products.isNotEmpty) {
        _pageController.jumpToPage(0);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _products = [];
        _isLoading = false;
      });
      debugPrint('TopRankingSection error: $e');
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageScroll);
    _pageController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  double? _parsePrice(String value) {
    try {
      final cleaned = value.replaceAll(RegExp(r'[^0-9.]'), '');
      if (cleaned.isEmpty) return null;
      return double.parse(cleaned);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- SCALING LOGIC FOR ACCESSIBILITY ---
    // Calculate a scaler based on text size, capped at 1.4x to prevent breaking layout entirely
    final double textScale = MediaQuery.textScalerOf(context).scale(1);
    final double scaleFactor = math.max(1.0, math.min(textScale, 1.4));

    // Base heights that scale
    final double totalHeight = 420 * scaleFactor;
    final double carouselHeight = 260 * scaleFactor;
    // ---------------------------------------

    final ProductModel? focusedProduct =
        (_products.isNotEmpty && _currentIndex < _products.length)
        ? _products[_currentIndex]
        : null;

    final double? basePrice = focusedProduct != null
        ? _parsePrice(focusedProduct.price)
        : null;
    final double? resellPrice = basePrice != null
        ? basePrice * 1.3
        : null; // +30%

    return SizedBox(
      height: totalHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(0),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFF4B5563).withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Stack(
              children: [
                // === SCI-FI ANIMATED BACKGROUND ===
                Positioned.fill(
                  child: _SciFiBackground(controller: _bgController),
                ),

                // Slight dark overlay so content is readable
                Positioned.fill(
                  child: Container(color: Colors.black.withValues(alpha: 0.40)),
                ),

                // === FOREGROUND CONTENT ===
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(context),
                        const SizedBox(height: 8),

                        // SMALL STATS + CURRENT PRODUCT SNAPSHOT
                        if (focusedProduct != null)
                          _CurrentProductStrip(
                            product: focusedProduct,
                            basePrice: basePrice,
                            resellPrice: resellPrice,
                            rank: _currentIndex + 1,
                            isHotTab: _selectedTab == 'Hot',
                          ),

                        const SizedBox(height: 6),

                        // MAIN 3D FEEL CAROUSEL
                        SizedBox(
                          height: carouselHeight,
                          child: _isLoading
                              ? _buildLoading()
                              : _products.isEmpty
                              ? _buildEmpty()
                              : _buildCarousel(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------- HEADER (TITLE + TABS) ----------

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Row(
        children: [
          // Glow icon + title block
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF22D3EE), Color(0xFF818CF8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF22D3EE).withValues(alpha: 0.5),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Iconsax.cup, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          // Wrapped in Expanded so text doesn't push tabs off screen
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Galaxy Leaderboard",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  "Top Ranking Resell Picks",
                  maxLines: 2,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Segment Control
          // Wrapped in FittedBox to shrink slightly if header text is massive
          FittedBox(
            child: _SegmentedTabs(
              selected: _selectedTab,
              onChanged: (tab) => _fetchProductsForTab(tab),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- LOADING / EMPTY / CAROUSEL ----------

  Widget _buildLoading() {
    return PageView.builder(
      itemCount: 3,
      controller: _pageController,
      itemBuilder: (_, __) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              color: Colors.white.withValues(alpha: 0.04),
            ),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                ),
                Container(
                  height: 70,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(28),
                    ),
                    color: Colors.white.withValues(alpha: 0.03),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.40),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Iconsax.box, size: 28, color: Color(0xFF9CA3AF)),
            SizedBox(height: 10),
            Text(
              "No ranking products configured yet.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 4),
            Text(
              "Ask admin to assign products into Top / Hot ranking categories in WooCommerce.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarousel() {
    return PageView.builder(
      controller: _pageController,
      itemCount: _products.length,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        final product = _products[index];

        return AnimatedBuilder(
          animation: _pageController,
          builder: (_, child) {
            double value = 0.0;
            if (_pageController.position.haveDimensions) {
              value = _pageController.page! - index;
            } else {
              value = (_currentIndex - index).toDouble();
            }

            value = (value).clamp(-1.0, 1.0);
            final double scale = 1 - (value.abs() * 0.10);
            final double translateY = 14 * value.abs();

            return Transform.translate(
              offset: Offset(0, translateY),
              child: Transform.scale(scale: scale, child: child),
            );
          },
          child: _LeaderboardCard(
            product: product,
            rank: index + 1,
            isFocused: index == _currentIndex,
            isHotTab: _selectedTab == 'Hot',
          ),
        );
      },
    );
  }
}

// ----------------------------------------------------------
// SCI-FI BACKGROUND
// ----------------------------------------------------------

class _SciFiBackground extends StatelessWidget {
  final AnimationController controller;

  const _SciFiBackground({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        return CustomPaint(painter: _SciFiPainter(progress: controller.value));
      },
    );
  }
}

class _SciFiPainter extends CustomPainter {
  final double progress;

  _SciFiPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint();

    // --- 1. Base gradient background ---
    final Rect rect = Offset.zero & size;
    final Gradient gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: const [Color(0xFF020617), Color(0xFF020617), Color(0xFF111827)],
      stops: const [0.0, 0.4, 1.0],
    );
    paint.shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);

    // --- 2. Neon diagonal glow streak ---
    final double streakY =
        size.height * (0.2 + 0.2 * math.sin(progress * 2 * math.pi));
    final Rect streakRect = Rect.fromLTWH(
      -size.width * 0.2,
      streakY,
      size.width * 1.4,
      80,
    );

    final Gradient streakGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Colors.transparent,
        _kAccent.withValues(alpha: 0.35),
        _kPrimary.withValues(alpha: 0.2),
        Colors.transparent,
      ],
      stops: const [0.0, 0.35, 0.65, 1.0],
    );
    paint.shader = streakGradient.createShader(streakRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(streakRect, const Radius.circular(40)),
      paint,
    );

    // --- 3. Parallax grid lines (bottom half) ---
    final double gridTop = size.height * 0.45;
    final double gridHeight = size.height * 0.55;

    final Paint gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 0.7;

    // Horizontal grid lines
    const int hLines = 6;
    for (int i = 0; i <= hLines; i++) {
      final double t = i / hLines;
      final double y = gridTop + t * gridHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Vertical perspective grid lines
    const int vLines = 6;
    for (int i = -1; i <= vLines + 1; i++) {
      final double t = i / vLines;
      final double xMid = size.width * 0.5;
      final double offsetX = (t - 0.5) * size.width * 0.9;

      final Offset start = Offset(xMid + offsetX * 0.1, gridTop);
      final Offset end = Offset(xMid + offsetX, size.height);
      canvas.drawLine(start, end, gridPaint);
    }

    // --- 4. Floating orbs (parallax) ---
    final List<_OrbConfig> orbs = [
      _OrbConfig(
        base: Offset(size.width * 0.15, size.height * 0.18),
        radius: 16,
        color: const Color(0xFF38BDF8),
        speed: 1.0,
      ),
      _OrbConfig(
        base: Offset(size.width * 0.85, size.height * 0.25),
        radius: 22,
        color: const Color(0xFFA855F7),
        speed: 1.4,
      ),
      _OrbConfig(
        base: Offset(size.width * 0.25, size.height * 0.60),
        radius: 14,
        color: const Color(0xFF22C55E),
        speed: 0.8,
      ),
    ];

    for (final orb in orbs) {
      final double angle = progress * 2 * math.pi * orb.speed;
      final double dx = math.sin(angle) * 10;
      final double dy = math.cos(angle) * 8;

      final Offset center = orb.base.translate(dx, dy);

      final Rect orbRect = Rect.fromCircle(center: center, radius: orb.radius);
      final Gradient orbGradient = RadialGradient(
        colors: [
          orb.color.withValues(alpha: 0.9),
          orb.color.withValues(alpha: 0.0),
        ],
      );
      final Paint orbPaint = Paint()
        ..shader = orbGradient.createShader(orbRect);
      canvas.drawCircle(center, orb.radius * 1.5, orbPaint);
    }

    // --- 5. Star particles ---
    final Paint starPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    const int starCount = 40;
    for (int i = 0; i < starCount; i++) {
      final double seed = i / starCount;
      final double px =
          (seed * size.width * 3 + progress * size.width * 60) % size.width;
      final double py =
          size.height *
          (0.1 +
              0.6 *
                  ((seed * 37.0 +
                          math.sin(progress * 2 * math.pi * (0.3 + seed))) %
                      1.0));

      final double r = 0.8 + 0.7 * math.sin(progress * 2 * math.pi + i);
      canvas.drawCircle(Offset(px, py), r, starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SciFiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _OrbConfig {
  final Offset base;
  final double radius;
  final Color color;
  final double speed;

  _OrbConfig({
    required this.base,
    required this.radius,
    required this.color,
    required this.speed,
  });
}

// ----------------------------------------------------------
// HEADER TAB WIDGET
// ----------------------------------------------------------

class _SegmentedTabs extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _SegmentedTabs({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min, // shrink to fit
        children: [
          _buildTab('Top', Iconsax.crown),
          _buildTab('Hot', Iconsax.flash_15),
        ],
      ),
    );
  }

  Widget _buildTab(String label, IconData icon) {
    final bool isActive = label == selected;

    return GestureDetector(
      onTap: () => onChanged(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: isActive
              ? const LinearGradient(
                  colors: [_kPrimary, _kAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? Colors.white : const Color(0xFF9CA3AF),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? Colors.white : const Color(0xFFE5E7EB),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------
// CURRENT PRODUCT SMALL STRIP
// ----------------------------------------------------------

class _CurrentProductStrip extends StatelessWidget {
  final ProductModel product;
  final double? basePrice;
  final double? resellPrice;
  final int rank;
  final bool isHotTab;

  const _CurrentProductStrip({
    required this.product,
    required this.basePrice,
    required this.resellPrice,
    required this.rank,
    required this.isHotTab,
  });

  @override
  Widget build(BuildContext context) {
    final profit = (basePrice != null && resellPrice != null)
        ? (resellPrice! - basePrice!)
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.black.withValues(alpha: 0.60),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Row(
          children: [
            // Rank orb
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: rank == 1
                      ? const [Color(0xFFFFD700), Color(0xFFF97316)]
                      : rank == 2
                      ? const [Color(0xFFE5E7EB), Color(0xFF9CA3AF)]
                      : rank == 3
                      ? const [Color(0xFFF97316), Color(0xFFB45309)]
                      : const [_kPrimary, _kAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  "#$rank",
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Product name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Changed from Row to Wrap to handle large text sizes prevents overflow
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    children: [
                      if (resellPrice != null)
                        Text(
                          "Resell ₹${resellPrice!.toStringAsFixed(0)}",
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _kAccent,
                          ),
                        ),
                      if (basePrice != null)
                        Text(
                          "Buy ₹${basePrice!.toStringAsFixed(0)}",
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            color: Color(0xFFCBD5F5),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            if (profit != null)
              FittedBox(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: const Color(0xFF064E3B),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Iconsax.trend_up,
                        size: 12,
                        color: Color(0xFF22C55E),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "+₹${profit.toStringAsFixed(0)}",
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFBBF7D0),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              FittedBox(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: isHotTab
                        ? const Color(0xFF7C2D12)
                        : const Color(0xFF1D3557),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isHotTab ? Iconsax.flash_1 : Iconsax.star1,
                        size: 12,
                        color: isHotTab
                            ? const Color(0xFFF97316)
                            : const Color(0xFFFACC15),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isHotTab ? "Hot pick" : "Top pick",
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
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

// ----------------------------------------------------------
// LEADERBOARD CARD (3D FEEL)
// ----------------------------------------------------------

class _LeaderboardCard extends StatelessWidget {
  final ProductModel product;
  final int rank;
  final bool isFocused;
  final bool isHotTab;

  const _LeaderboardCard({
    required this.product,
    required this.rank,
    required this.isFocused,
    required this.isHotTab,
  });

  double? _parsePrice(String value) {
    try {
      final cleaned = value.replaceAll(RegExp(r'[^0-9.]'), '');
      if (cleaned.isEmpty) return null;
      return double.parse(cleaned);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double? basePrice = _parsePrice(product.price);
    final double? resellPrice = basePrice != null
        ? basePrice * 1.3
        : null; // +30%
    final double? profit = (basePrice != null && resellPrice != null)
        ? resellPrice - basePrice
        : null;

    return GestureDetector(
      onTap: () {
        Get.to(
          () => ProductDetailsPage(product: product),
          transition: Transition.fadeIn,
          duration: const Duration(milliseconds: 250),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            colors: [Color(0xFF020617), Color(0xFF020617)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 20,
              offset: const Offset(0, 14),
            ),
          ],
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          children: [
            // IMAGE + OVERLAYS
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Image layer
                    Container(
                      color: Colors.black,
                      child: Image.network(
                        product.image,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => Container(
                          color: Colors.black,
                          child: Icon(
                            Iconsax.image,
                            color: Colors.grey.shade500,
                            size: 38,
                          ),
                        ),
                      ),
                    ),

                    // Slight radial vignette
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: const Alignment(0, -0.2),
                            radius: 1.0,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.6),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Rank orb
                    Positioned(top: 14, left: 14, child: _RankOrb(rank: rank)),

                    // Top-right badge
                    Positioned(
                      top: 14,
                      right: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: Colors.black.withValues(alpha: 0.5),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.20),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isHotTab ? Iconsax.flash_1 : Iconsax.star1,
                              size: 12,
                              color: isHotTab
                                  ? const Color(0xFFF97316)
                                  : const Color(0xFFFACC15),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isHotTab ? "Hot" : "Top",
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
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

            // GLASSY BOTTOM INFO
            // REMOVED FIXED HEIGHT HERE to prevent crumbling
            Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(28),
                ),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.06),
                    Colors.white.withValues(alpha: 0.02),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    // Profit / info column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (profit != null)
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                const Icon(
                                  Iconsax.trend_up,
                                  size: 14,
                                  color: Color(0xFF22C55E),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "+₹${profit.toStringAsFixed(0)} profit",
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF4ADE80),
                                  ),
                                ),
                              ],
                            )
                          else
                            const Text(
                              "High-margin resell pick",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            "Perfect to share with your audience today.",
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              color: Colors.white.withValues(alpha: 0.70),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // CTA pill
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: () {
                          Get.to(
                            () => ProductDetailsPage(product: product),
                            transition: Transition.fadeIn,
                            duration: const Duration(milliseconds: 220),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            gradient: const LinearGradient(
                              colors: [_kPrimary, _kAccent],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _kAccent.withValues(alpha: 0.55),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                "View",
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 6),
                              Icon(
                                Iconsax.arrow_right_3,
                                size: 14,
                                color: Colors.white,
                              ),
                            ],
                          ),
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

// ----------------------------------------------------------
// RANK ORB
// ----------------------------------------------------------

class _RankOrb extends StatelessWidget {
  final int rank;

  const _RankOrb({required this.rank});

  @override
  Widget build(BuildContext context) {
    List<Color> colors;
    if (rank == 1) {
      colors = const [Color(0xFFFFD700), Color(0xFFF97316)];
    } else if (rank == 2) {
      colors = const [Color(0xFFE5E7EB), Color(0xFF9CA3AF)];
    } else if (rank == 3) {
      colors = const [Color(0xFFF97316), Color(0xFFB45309)];
    } else {
      colors = const [_kPrimary, _kAccent];
    }

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Text(
          "#$rank",
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
