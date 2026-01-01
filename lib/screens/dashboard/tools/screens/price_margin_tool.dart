// lib/screens/dashboard/tools/price_margin_tool.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:share_plus/share_plus.dart';
import 'package:get_storage/get_storage.dart';
import 'package:showcaseview/showcaseview.dart';

import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/services/api_services.dart';

// ─── THEME ───────────────────────────────────────────────────────────────────
const Color kAccentColor = Color(0xFF2563EB); // Royal Blue
const Color kProfitColor = Color(0xFF10B981); // Emerald Green
const Color kCostColor = Color(0xFF64748B); // Slate
const Color kFeeColor = Color(0xFFF59E0B); // Amber
const Color kBgColor = Color(0xFFF8FAFC);
const Color kSurface = Colors.white;

// 1. WRAPPER FOR TOUR
class PriceMarginToolPage extends StatelessWidget {
  const PriceMarginToolPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ShowCaseWidget(
      builder: (context) => const _PriceMarginToolContent(),
      autoPlay: false,
      blurValue: 1,
      enableAutoScroll: true, // 🌟 Ensures scrolling works
      scrollDuration: const Duration(milliseconds: 400),
    );
  }
}

class _PriceMarginToolContent extends StatefulWidget {
  const _PriceMarginToolContent();

  @override
  State<_PriceMarginToolContent> createState() =>
      _PriceMarginToolContentState();
}

class _PriceMarginToolContentState extends State<_PriceMarginToolContent> {
  // --- STATE ---
  final List<ProductModel> _selectedProducts = [];
  final _localStorage = GetStorage();

  // 2. SHOWCASE KEYS
  final GlobalKey _addKey = GlobalKey();
  final GlobalKey _calculatorKey = GlobalKey();
  final GlobalKey _strategyKey = GlobalKey();
  final GlobalKey _goalKey = GlobalKey();
  final GlobalKey _shareKey = GlobalKey();

  // The Core Variables
  double _sellingPrice = 0.0;
  double _targetGoal = 5000.0; // Default goal: Earn 5k

  // Fees Configuration
  final double _shippingCost = 100.0;
  bool _resellerAbsorbsShipping = false;
  bool _isSharing = false;

  // Constants
  static const double kPlatformFeePerItem = 5.0;
  static const double kConvenienceFeeConst = 10.0;

  // Text Controllers
  final TextEditingController _priceCtrl = TextEditingController();
  final TextEditingController _profitCtrl = TextEditingController();
  final TextEditingController _marginCtrl = TextEditingController();
  final TextEditingController _goalCtrl = TextEditingController(text: "5000");

  @override
  void initState() {
    super.initState();
    // 3. TRIGGER TOUR
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAndStartTour());
  }

  void _checkAndStartTour() {
    bool hasShown = _localStorage.read('has_shown_profit_tool_tour') ?? false;
    if (!hasShown) {
      _startTour();
      _localStorage.write('has_shown_profit_tool_tour', true);
    }
  }

  void _startTour() {
    ShowCaseWidget.of(context).startShowCase([
      _addKey,
      if (_selectedProducts.isNotEmpty) ...[
        _calculatorKey,
        _strategyKey,
        _goalKey,
        _shareKey,
      ] else
        _addKey, // If empty, only show add button
    ]);
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _profitCtrl.dispose();
    _marginCtrl.dispose();
    _goalCtrl.dispose();
    super.dispose();
  }

  // ─── CALCULATION ENGINE 🧠 ────────────────────────────────────────────────

  double get _baseProductCost => _selectedProducts.fold(
    0.0,
    (sum, p) => sum + (double.tryParse(p.price) ?? 0),
  );

  // Fees
  double get _platformFee => _selectedProducts.isEmpty
      ? 0
      : (_selectedProducts.length * kPlatformFeePerItem);
  double get _convenienceFee =>
      _selectedProducts.isEmpty ? 0 : kConvenienceFeeConst;
  double get _shippingVal => _resellerAbsorbsShipping ? _shippingCost : 0;

  // Break Even & Profit
  double get _totalCost =>
      _baseProductCost + _platformFee + _convenienceFee + _shippingVal;
  double get _netProfit => _sellingPrice - _totalCost;
  double get _marginPercent =>
      _totalCost > 0 ? ((_sellingPrice - _totalCost) / _totalCost) * 100 : 0;

  // Goal Math
  int get _unitsToGoal {
    if (_netProfit <= 0) return 0;
    return (_targetGoal / _netProfit).ceil();
  }

  // Breakdown for Monthly Goal
  String get _weeklyGoalText {
    if (_unitsToGoal <= 0) return "Check profit settings";
    int weekly = (_unitsToGoal / 4).ceil();
    if (weekly < 1) weekly = 1;
    return "$weekly bundles / week";
  }

  // Market Estimate (Heuristic)
  double get _marketValue => _baseProductCost * 2.2;

  // --- SYNC LOGIC ---

  void _onSellingPriceChanged(String val) {
    if (val.isEmpty) return;
    double price = double.tryParse(val.replaceAll(',', '')) ?? 0;
    setState(() {
      _sellingPrice = price;
      _syncControllers(source: 'price');
    });
  }

  void _onProfitChanged(String val) {
    if (val.isEmpty) return;
    double targetProfit = double.tryParse(val.replaceAll(',', '')) ?? 0;
    double newPrice = _totalCost + targetProfit;
    setState(() {
      _sellingPrice = newPrice;
      _syncControllers(source: 'profit');
    });
  }

  void _onMarginChanged(String val) {
    if (val.isEmpty) return;
    double marginPct = double.tryParse(val) ?? 0;
    double newPrice = _totalCost * (1 + (marginPct / 100));
    setState(() {
      _sellingPrice = newPrice;
      _syncControllers(source: 'margin');
    });
  }

  void _onGoalChanged(String val) {
    if (val.isEmpty) return;
    setState(() {
      _targetGoal = double.tryParse(val.replaceAll(',', '')) ?? 5000;
    });
  }

  void _syncControllers({required String source}) {
    if (source != 'price') _priceCtrl.text = _sellingPrice.toStringAsFixed(0);
    if (source != 'profit') _profitCtrl.text = _netProfit.toStringAsFixed(0);
    if (source != 'margin')
      _marginCtrl.text = _marginPercent.toStringAsFixed(1);
  }

  // --- AUTOMATION BUTTONS ---

  void _applyAutoPrice(String type) {
    double price = _sellingPrice;
    if (type == 'quick') {
      price = _totalCost * 1.15; // 15% Margin
      price = (price / 10).ceil() * 10.0 - 1; // Round to 9
    } else if (type == 'max') {
      price = _totalCost * 1.40; // 40% Margin
      double next100 = (price / 100).ceil() * 100.0;
      if (next100 == price) next100 += 100;
      price = next100 - 1; // Round to 99
    }
    setState(() {
      _sellingPrice = price;
      _syncControllers(source: 'all');
    });
  }

  // --- DEAL BROADCASTER (SHARE) ---
  Future<void> _broadcastDeal() async {
    if (_selectedProducts.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Select products first")));
      return;
    }

    setState(() => _isSharing = true);

    try {
      final buffer = StringBuffer();
      buffer.writeln("🔥 *STEAL DEAL ALERT!* 🔥");
      if (_selectedProducts.length > 1) {
        buffer.writeln("📦 *${_selectedProducts.length} Item Combo Pack*");
      } else {
        buffer.writeln("📦 *Premium Quality Pick*");
      }
      buffer.writeln("");

      if (_sellingPrice < _marketValue) {
        buffer.writeln("❌ Market Price: ~₹${_marketValue.toStringAsFixed(0)}~");
      }
      buffer.writeln(
        "✅ *OFFER PRICE: ₹${_sellingPrice.toStringAsFixed(0)} Only!* 🤑",
      );
      buffer.writeln("");

      if (_resellerAbsorbsShipping) {
        buffer.writeln("🚚 *Free Home Delivery Included*");
      } else {
        buffer.writeln("🚚 *Fast Delivery Available*");
      }

      if (_selectedProducts.length > 1) {
        buffer.writeln("\n🎁 _Includes:_");
        for (var p in _selectedProducts) {
          buffer.writeln("• ${p.name}");
        }
      }

      buffer.writeln("\n👇 *Reply 'BOOK' to grab this deal!*");

      List<XFile> filesToShare = [];
      for (var product in _selectedProducts) {
        if (product.image.isNotEmpty) {
          final file = await ApiService.downloadImageAsFile(product.image);
          filesToShare.add(file);
        }
      }

      await Share.shareXFiles(filesToShare, text: buffer.toString());
    } catch (e) {
      debugPrint("Share error: $e");
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  // ─── UI COMPONENTS ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        title: const Text(
          "Profit Lab",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        backgroundColor: kSurface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF1E293B),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // RESTART TOUR BUTTON
          IconButton(
            tooltip: "Guide",
            icon: const Icon(Iconsax.info_circle, color: kAccentColor),
            onPressed: _startTour,
          ),
          IconButton(
            icon: const Icon(Iconsax.refresh, color: kAccentColor),
            onPressed: () {
              setState(() {
                _selectedProducts.clear();
                _sellingPrice = 0;
                _syncControllers(source: 'all');
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 4. WRAP WIDGETS IN SHOWCASE

            // Step 1: Add Products
            Showcase(
              key: _addKey,
              title: "Step 1: Add Products",
              description: "Tap here to select items you want to sell.",
              overlayColor: Colors.black.withOpacity(0.7),
              titleTextStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                color: kAccentColor,
                fontSize: 16,
              ),
              descTextStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.black,
                fontSize: 12,
              ),
              targetBorderRadius: BorderRadius.circular(20),
              child: _buildProductStack(),
            ),
            const SizedBox(height: 20),

            if (_selectedProducts.isNotEmpty) ...[
              // Step 2: Calculator
              Showcase(
                key: _calculatorKey,
                title: "Profit Calculator",
                description:
                    "Adjust the selling price to see your real-time profit and margin.",
                overlayColor: Colors.black.withOpacity(0.7),
                titleTextStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: kAccentColor,
                  fontSize: 16,
                ),
                descTextStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                  fontSize: 12,
                ),
                targetBorderRadius: BorderRadius.circular(24),
                child: _buildMainDashboard(),
              ),
              const SizedBox(height: 16),

              // Cost Summary (No tour needed)
              _buildCostSummary(),
              const SizedBox(height: 20),

              // Step 3: Strategy
              Showcase(
                key: _strategyKey,
                title: "Smart Pricing",
                description:
                    "Use 'Quick Sell' for volume or 'Max Profit' for premium earnings.",
                overlayColor: Colors.black.withOpacity(0.7),
                titleTextStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: kAccentColor,
                  fontSize: 16,
                ),
                descTextStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                  fontSize: 12,
                ),
                targetBorderRadius: BorderRadius.circular(12),
                child: _buildStrategyPad(),
              ),
              const SizedBox(height: 20),

              // Step 4: Goal
              Showcase(
                key: _goalKey,
                title: "Goal Tracker",
                description:
                    "Set a monthly earning goal. We'll tell you how many items to sell per week.",
                overlayColor: Colors.black.withOpacity(0.7),
                titleTextStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: kAccentColor,
                  fontSize: 16,
                ),
                descTextStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                  fontSize: 12,
                ),
                targetBorderRadius: BorderRadius.circular(20),
                child: _buildEnhancedGoalTracker(),
              ),
              const SizedBox(height: 24),

              // Step 5: Share
              Showcase(
                key: _shareKey,
                title: "Broadcast Deal",
                description:
                    "Instantly share this deal with images and price calculated for you.",
                overlayColor: Colors.black.withOpacity(0.7),
                titleTextStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: kAccentColor,
                  fontSize: 16,
                ),
                descTextStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                  fontSize: 12,
                ),
                targetBorderRadius: BorderRadius.circular(20),
                child: _buildDealBroadcaster(),
              ),

              // Padding for scrolling
              const SizedBox(height: 100),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProductStack() {
    if (_selectedProducts.isEmpty) {
      return GestureDetector(
        onTap: _pickProducts,
        child: Container(
          width: double.infinity,
          height: 130,
          decoration: BoxDecoration(
            color: kSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade300, width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Iconsax.bag_2, size: 32, color: Colors.grey),
              SizedBox(height: 10),
              Text(
                "Build Your Deal",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
              Text(
                "Add products to calculate margins",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Your Bundle (${_selectedProducts.length})",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            TextButton.icon(
              onPressed: _pickProducts,
              icon: const Icon(Iconsax.add_circle, size: 16),
              label: const Text("Add"),
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _selectedProducts.length,
            itemBuilder: (ctx, i) {
              final p = _selectedProducts[i];
              return Container(
                width: 70,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                  image: DecorationImage(
                    image: NetworkImage(p.image),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedProducts.removeAt(i);
                        if (_selectedProducts.isEmpty) {
                          _sellingPrice = 0;
                        } else {
                          _sellingPrice = _totalCost * 1.2;
                        }
                        _syncControllers(source: 'all');
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 12,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMainDashboard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "CUSTOMER PAYS",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.grey,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text(
                "₹",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black38,
                ),
              ),
              const SizedBox(width: 4),
              IntrinsicWidth(
                child: TextField(
                  controller: _priceCtrl,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                    height: 1.0,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: "0",
                  ),
                  onChanged: _onSellingPriceChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const Text(
                      "Net Profit",
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    TextField(
                      controller: _profitCtrl,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: kProfitColor,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        prefixText: "₹",
                      ),
                      onChanged: _onProfitChanged,
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 40, color: Colors.grey.shade200),
              Expanded(
                child: Column(
                  children: [
                    const Text(
                      "Margin",
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    TextField(
                      controller: _marginCtrl,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: kAccentColor,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        suffixText: "%",
                      ),
                      onChanged: _onMarginChanged,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: kBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  _resellerAbsorbsShipping ? Iconsax.truck_fast : Iconsax.box,
                  size: 18,
                  color: Colors.purple,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _resellerAbsorbsShipping
                        ? "Free Shipping (You pay)"
                        : "Customer Pays Shipping",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Switch(
                  value: _resellerAbsorbsShipping,
                  activeColor: Colors.purple,
                  onChanged: (v) {
                    setState(() {
                      _resellerAbsorbsShipping = v;
                      _syncControllers(source: 'all');
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostSummary() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Base Cost + Fees",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Row(
            children: [
              Text(
                "Break Even: ",
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              Text(
                "₹${_totalCost.toStringAsFixed(0)}",
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: kCostColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStrategyPad() {
    return Row(
      children: [
        Expanded(
          child: _strategyBtn(
            "🚀 Quick Sell",
            "Low Margin",
            () => _applyAutoPrice('quick'),
            Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _strategyBtn(
            "💎 Max Profit",
            "Premium",
            () => _applyAutoPrice('max'),
            Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _strategyBtn(
    String label,
    String sub,
    VoidCallback onTap,
    Color color,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sub,
              style: TextStyle(
                fontSize: 10,
                color: color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedGoalTracker() {
    bool isLoss = _netProfit <= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Iconsax.triangle,
                  size: 20,
                  color: Colors.blueGrey,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Monthly Target",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Plan your earnings",
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                width: 90,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: kBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: _goalCtrl,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    prefixText: "₹",
                  ),
                  onChanged: _onGoalChanged,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          if (isLoss)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "⚠️ Increase margin to see goal progress",
                  style: TextStyle(fontSize: 12, color: Colors.red),
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "TOTAL SALES NEEDED",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "$_unitsToGoal Bundles",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 40, color: Colors.grey.shade200),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "SPEED REQUIRED",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _weeklyGoalText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: kAccentColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDealBroadcaster() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kAccentColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Iconsax.flash_1, color: Colors.yellow, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "READY TO SELL?",
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Broadcast Deal: ₹${_sellingPrice.toStringAsFixed(0)}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isSharing ? null : _broadcastDeal,
              icon: _isSharing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Iconsax.share, color: Colors.black),
              label: Text(
                _isSharing ? "Generating..." : "Share Deal with Photos",
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickProducts() async {
    final List<ProductModel>? picked = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _MultiProductPickerSheet(),
    );

    if (picked != null && picked.isNotEmpty) {
      setState(() {
        _selectedProducts.addAll(picked);
        _sellingPrice = _totalCost * 1.20;
        _syncControllers(source: 'all');
      });
      // 🌟 Re-check tour to show next steps if needed
      // Delay to let UI rebuild
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_localStorage.read('has_shown_profit_tool_tour') == true) {
          // Optionally prompt to continue tour here if needed
        }
      });
    }
  }
}

// ─── HELPER: MULTI PICKER SHEET ──────────────────────────────────────────────
class _MultiProductPickerSheet extends StatefulWidget {
  const _MultiProductPickerSheet();
  @override
  State<_MultiProductPickerSheet> createState() =>
      _MultiProductPickerSheetState();
}

class _MultiProductPickerSheetState extends State<_MultiProductPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<ProductModel> _products = [];
  final Set<ProductModel> _selected = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch({String query = ''}) async {
    setState(() => _isLoading = true);
    try {
      final items = query.isEmpty
          ? await ApiService.fetchProducts(page: 1, perPage: 30)
          : await ApiService.searchProducts(query);
      if (mounted) {
        setState(() {
          _products = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggle(ProductModel p) {
    setState(() {
      if (_selected.contains(p)) {
        _selected.remove(p);
      } else {
        _selected.add(p);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Select Products",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "${_selected.length} selected",
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                if (_selected.isNotEmpty)
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, _selected.toList()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kAccentColor,
                    ),
                    child: const Text(
                      "Done",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Iconsax.search_normal),
                filled: true,
                fillColor: kBgColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => _fetch(query: v),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                    itemCount: _products.length,
                    itemBuilder: (ctx, i) {
                      final p = _products[i];
                      final isSelected = _selected.contains(p);
                      return GestureDetector(
                        onTap: () => _toggle(p),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? kAccentColor
                                  : Colors.grey.shade200,
                              width: isSelected ? 3 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(9),
                                  ),
                                  child: Image.network(
                                    p.image,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(4),
                                child: Text(
                                  "₹${p.price}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
