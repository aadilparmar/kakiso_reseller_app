// lib/screens/dashboard/tools/trending_products_dashboard.dart

import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

// INTERNAL IMPORTS
import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/services/api_services.dart';
import 'package:kakiso_reseller_app/controllers/cart_controller.dart';

// ─── OPTIMIZED THEME SYSTEM ──────────────────────────────────────────────────
const Color kSpaceBlack = Color(0xFF000000);
const Color kDepthBlack = Color(0xFF050505);
const Color kCardGlass = Color(0xFF121212);
const Color kNeonCyan = Color(0xFF00E5FF);
const Color kNeonLime = Color(0xFFC6FF00);
const Color kNeonPink = Color(0xFFFF2E63);
const Color kTextWhite = Colors.white;
const Color kTextGrey = Color(0xFF9CA3AF);
const Color kProfitGreen = Color(0xFF00C853);
const Color kHotOrange = Color(0xFFFF6D00);

enum MarketSignal { viral, arbitrage, breakout, fresh }

class TrendingProductsDashboardPage extends StatefulWidget {
  const TrendingProductsDashboardPage({super.key});

  @override
  State<TrendingProductsDashboardPage> createState() =>
      _TrendingProductsDashboardPageState();
}

class _TrendingProductsDashboardPageState
    extends State<TrendingProductsDashboardPage>
    with TickerProviderStateMixin {
  // --- STATE ---
  MarketSignal _signal = MarketSignal.viral;
  List<ProductModel> _products = [];
  bool _isLoading = true;
  bool _profitVision = true;

  late CartController _cartController;
  late AnimationController _radarController;

  @override
  void initState() {
    super.initState();
    _safeInitController();
    _loadMarketData(initial: true);

    // Low-cost animation for icon only
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  void _safeInitController() {
    try {
      _cartController = Get.find<CartController>();
    } catch (e) {
      _cartController = Get.put(CartController());
    }
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  Future<void> _loadMarketData({bool initial = false}) async {
    if (initial) setState(() => _isLoading = true);
    try {
      List<ProductModel> data;
      switch (_signal) {
        case MarketSignal.viral:
          data = await ApiService.fetchTrendingProducts();
          break;
        case MarketSignal.arbitrage:
          data = await ApiService.fetchTopRankingProducts();
          data.sort(
            (a, b) => (double.tryParse(a.price) ?? 0).compareTo(
              double.tryParse(b.price) ?? 0,
            ),
          );
          break;
        case MarketSignal.breakout:
          data = await ApiService.fetchHotRankingProducts();
          break;
        case MarketSignal.fresh:
          data = await ApiService.fetchNewestProducts();
          break;
      }
      if (mounted)
        setState(() {
          _products = data;
          _isLoading = false;
        });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openCommandCenter(ProductModel p) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      // Use SafeArea to handle notches/home bars
      builder: (context) =>
          _CommandCenterSheet(product: p, cartController: _cartController),
    );
  }

  // ─── UI BUILD ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Dynamic bottom padding for safe area + ticker
    final double bottomPadding = MediaQuery.of(context).padding.bottom + 60;

    return Scaffold(
      backgroundColor: kSpaceBlack,
      body: Stack(
        children: [
          // 1. OPTIMIZED BACKGROUND (Static Gradient = High FPS)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [kSpaceBlack, kDepthBlack, Color(0xFF0A0A0A)],
              ),
            ),
          ),

          // 2. MAIN SCROLL VIEW
          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              _buildTerminalHeader(),
              _buildSignalFilters(),
            ],
            body: _isLoading
                ? _buildRadarLoader()
                : _products.isEmpty
                ? _buildVoidState()
                : RefreshIndicator(
                    onRefresh: () => _loadMarketData(),
                    color: kNeonCyan,
                    backgroundColor: kDepthBlack,
                    child: MasonryGridView.count(
                      padding: EdgeInsets.fromLTRB(12, 0, 12, bottomPadding),
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      itemCount: _products.length,
                      // Improve scrolling performance
                      addAutomaticKeepAlives: false,
                      addRepaintBoundaries: true,
                      itemBuilder: (context, index) {
                        return _MarketAssetCard(
                          product: _products[index],
                          index: index,
                          profitVision: _profitVision,
                          onTap: () => _openCommandCenter(_products[index]),
                        );
                      },
                    ),
                  ),
          ),

          // 3. LIVE TICKER (Bottom Fixed)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _LiveMarketTicker(
              onVisionToggle: () {
                HapticFeedback.mediumImpact();
                setState(() => _profitVision = !_profitVision);
              },
              isProfitVision: _profitVision,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTerminalHeader() {
    return SliverAppBar(
      backgroundColor: kSpaceBlack.withOpacity(
        0.9,
      ), // High opacity for legibility
      floating: true,
      pinned: true,
      expandedHeight: 60,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new,
          color: Colors.white,
          size: 20,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      // Removed BackdropFilter here for performance on scrolling
      title: Row(
        children: [
          const Text(
            "VIRAL HUNTER",
            style: TextStyle(
              color: kTextWhite,
              fontWeight: FontWeight.w900,
              fontSize: 16,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(width: 8),
          RepaintBoundary(
            child: RotationTransition(
              turns: _radarController,
              child: const Icon(Iconsax.radar_2, color: kNeonCyan, size: 16),
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            children: const [
              Icon(Icons.circle, size: 8, color: kNeonLime),
              SizedBox(width: 6),
              Text(
                "LIVE",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSignalFilters() {
    return SliverToBoxAdapter(
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            _buildSignalChip("🔥 Viral Flow", MarketSignal.viral),
            _buildSignalChip("📉 Arbitrage", MarketSignal.arbitrage),
            _buildSignalChip("🚀 Breakout", MarketSignal.breakout),
            _buildSignalChip("✨ Fresh Mint", MarketSignal.fresh),
          ],
        ),
      ),
    );
  }

  Widget _buildSignalChip(String label, MarketSignal sig) {
    bool isSelected = _signal == sig;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _signal = sig);
        _loadMarketData();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? kNeonCyan : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: isSelected ? kNeonCyan : Colors.white24),
          boxShadow: isSelected
              ? [BoxShadow(color: kNeonCyan.withOpacity(0.2), blurRadius: 12)]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRadarLoader() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RepaintBoundary(
            child: RotationTransition(
              turns: _radarController,
              child: const Icon(Iconsax.radar5, size: 64, color: kNeonCyan),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Scanning Market...",
            style: TextStyle(
              color: Colors.white54,
              letterSpacing: 1.5,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoidState() => const Center(
    child: Text(
      "No signals detected.",
      style: TextStyle(color: Colors.white30),
    ),
  );
}

// ─── MARKET ASSET CARD (OPTIMIZED) ──────────────────────────────────────────

class _MarketAssetCard extends StatelessWidget {
  final ProductModel product;
  final int index;
  final bool profitVision;
  final VoidCallback onTap;

  const _MarketAssetCard({
    required this.product,
    required this.index,
    required this.profitVision,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    double cost = double.tryParse(product.price) ?? 0;
    double profit = cost * 0.40;
    double marketPrice = cost * 2.2;
    double arbitrageGap = marketPrice - cost;
    int dnaScore = 99 - (index * 3);
    if (dnaScore < 70) dnaScore = 70 + Random().nextInt(20);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: kCardGlass,
          borderRadius: BorderRadius.circular(
            16,
          ), // Reduced radius for cleaner look
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          // Removed heavy shadow for list performance
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. IMAGE AREA
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Image.network(
                    product.image,
                    fit: BoxFit.cover,
                    // 🚀 CRITICAL: Cache resizing for performance
                    cacheWidth: 400,
                    errorBuilder: (_, __, ___) => Container(
                      height: 150,
                      color: Colors.white10,
                      child: const Icon(Iconsax.image, color: Colors.white24),
                    ),
                  ),
                ),

                // DNA SCORE (No Blur here for performance)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: kNeonCyan.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Iconsax.flash_1, color: kNeonCyan, size: 10),
                        const SizedBox(width: 4),
                        Text(
                          "$dnaScore% MATCH",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // 2. DATA AREA
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Arbitrage Visualizer (Simple Container, no heavy widgets)
                  Row(
                    children: [
                      const Text(
                        "GAP",
                        style: TextStyle(
                          color: Colors.white30,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: 0.7,
                            child: Container(
                              decoration: BoxDecoration(
                                color:
                                    kProfitGreen, // Replaced gradient with solid color for perf
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "+₹${arbitrageGap.toStringAsFixed(0)}",
                        style: const TextStyle(
                          color: kNeonLime,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Hero Pricing
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profitVision ? "YOUR NET" : "BASE COST",
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            profitVision
                                ? "₹${profit.toStringAsFixed(0)}"
                                : "₹${cost.toStringAsFixed(0)}",
                            style: TextStyle(
                              color: profitVision ? kNeonCyan : Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Iconsax.arrow_right_3,
                          color: Colors.white,
                          size: 16,
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

// ─── LIVE MARKET TICKER ──────────────────────────────────────────────────────

class _LiveMarketTicker extends StatefulWidget {
  final VoidCallback onVisionToggle;
  final bool isProfitVision;

  const _LiveMarketTicker({
    required this.onVisionToggle,
    required this.isProfitVision,
  });

  @override
  State<_LiveMarketTicker> createState() => _LiveMarketTickerState();
}

class _LiveMarketTickerState extends State<_LiveMarketTicker> {
  final List<String> _events = [
    "🚀 Priya shared 'Saree Collection'",
    "💰 Rahul earned ₹450 on 'Smart Watch'",
    "🔥 'Floral Kurti' demand up 40%",
    "⚡ Amit stockpiled 10 units",
  ];
  int _index = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) setState(() => _index = (_index + 1) % _events.length);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Only use BackdropFilter for static overlays, not scrolling items usually.
    // Kept here as it's a fixed bottom bar.
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12, // Safe Area
      ),
      decoration: BoxDecoration(
        color: kDepthBlack.withOpacity(
          0.95,
        ), // High opacity to avoid heavy blur calc
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                const Icon(Iconsax.flash_1, color: kHotOrange, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.5),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: Text(
                      _events[_index],
                      key: ValueKey(_index),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: widget.onVisionToggle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: widget.isProfitVision
                    ? kNeonLime.withOpacity(0.2)
                    : Colors.white10,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.isProfitVision ? kNeonLime : Colors.white24,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.isProfitVision ? Iconsax.eye : Iconsax.eye_slash,
                    color: widget.isProfitVision ? kNeonLime : Colors.grey,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.isProfitVision ? "PROFIT" : "COST",
                    style: TextStyle(
                      color: widget.isProfitVision ? kNeonLime : Colors.grey,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── COMMAND CENTER SHEET (SCROLLABLE) ───────────────────────────────────────

class _CommandCenterSheet extends StatefulWidget {
  final ProductModel product;
  final CartController cartController;

  const _CommandCenterSheet({
    required this.product,
    required this.cartController,
  });

  @override
  State<_CommandCenterSheet> createState() => _CommandCenterSheetState();
}

class _CommandCenterSheetState extends State<_CommandCenterSheet> {
  double _margin = 150.0;
  bool _isProcessing = false;

  double get _baseCost => double.tryParse(widget.product.price) ?? 0;
  double get _sellingPrice => _baseCost + _margin;

  Future<void> _shareDeal() async {
    setState(() => _isProcessing = true);
    double displayPrice = (_sellingPrice / 100).ceil() * 100.0 - 1;
    double mrp = displayPrice * 1.5;

    String caption =
        """
🚀 *VIRAL DROP ALERT* 🚀
${widget.product.name}

📉 Market Price: ~₹${mrp.toStringAsFixed(0)}~
✅ *YOUR PRICE: ₹${displayPrice.toStringAsFixed(0)} Only*

📦 _Verified Quality_
🚚 _Free Express Delivery_

👇 *Reply 'MINE' to secure yours!*
""";

    try {
      final file = await ApiService.downloadImageAsFile(widget.product.image);
      await Share.shareXFiles([file], text: caption);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      // err
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _stockpile() {
    HapticFeedback.mediumImpact();
    widget.cartController.addToCart(widget.product);
    Navigator.pop(context);
    Get.snackbar(
      "Added to Cart",
      "Product added to cart",
      backgroundColor: kProfitGreen,
      colorText: Colors.black,
      margin: const EdgeInsets.all(16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Safe for static sheet
      child: Container(
        decoration: BoxDecoration(
          color: kDepthBlack.withOpacity(0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
          ),
        ),
        padding: const EdgeInsets.all(24),
        // 🛡️ SCROLLABLE SHEET: Protects against small screens / keyboard
        child: SingleChildScrollView(
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 24),

                // Product Preview
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        widget.product.image,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        cacheWidth: 150, // Cache for performance
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.product.name,
                            maxLines: 2,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Base Cost: ₹${_baseCost.toStringAsFixed(0)}",
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Profit DNA Bar
                Container(
                  height: 10,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: _baseCost.toInt(),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.horizontal(
                              left: Radius.circular(5),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: _margin.toInt(),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: kNeonCyan,
                            borderRadius: BorderRadius.horizontal(
                              right: Radius.circular(5),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "COST",
                      style: TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                    const Text(
                      "PROFIT",
                      style: TextStyle(color: kNeonCyan, fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "SET MARGIN",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    Text(
                      "+ ₹${_margin.toStringAsFixed(0)}",
                      style: const TextStyle(
                        color: kNeonCyan,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: kNeonCyan,
                    thumbColor: Colors.white,
                    inactiveTrackColor: Colors.white10,
                    trackHeight: 6,
                    overlayColor: kNeonCyan.withOpacity(0.2),
                  ),
                  child: Slider(
                    value: _margin,
                    min: 0,
                    max: 1000,
                    onChanged: (v) => setState(() => _margin = v),
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Customer Price:",
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      Text(
                        "₹${_sellingPrice.toStringAsFixed(0)}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildCyberButton(
                        icon: Iconsax.bag_tick,
                        label: "Add to Cart",
                        isPrimary: false,
                        onTap: _stockpile,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildCyberButton(
                        icon: Iconsax.flash_1,
                        label: _isProcessing ? "PROCESSING..." : "BLAST DEAL",
                        isPrimary: true,
                        onTap: _isProcessing ? () {} : _shareDeal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCyberButton({
    required IconData icon,
    required String label,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: isPrimary ? kNeonCyan : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kNeonCyan),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: kNeonCyan.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isPrimary ? Colors.black : kNeonCyan, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isPrimary ? Colors.black : kNeonCyan,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
