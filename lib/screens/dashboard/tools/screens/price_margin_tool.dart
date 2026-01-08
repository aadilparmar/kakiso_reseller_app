// lib/screens/dashboard/tools/price_margin_tool.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:share_plus/share_plus.dart';
import 'package:get_storage/get_storage.dart';
import 'package:get/get.dart';
import 'package:showcaseview/showcaseview.dart';

// INTERNAL IMPORTS
import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/services/api_services.dart';
import 'package:kakiso_reseller_app/controllers/catalouge_controller.dart';

// ─── THEME ───────────────────────────────────────────────────────────────────
const Color kAccentColor = Color(0xFF2563EB);
const Color kProfitColor = Color(0xFF10B981);
const Color kCostColor = Color(0xFF64748B);
const Color kFeeColor = Color(0xFFF59E0B);
const Color kBgColor = Color(0xFFF8FAFC);
const Color kSurface = Colors.white;

class PriceMarginToolPage extends StatelessWidget {
  const PriceMarginToolPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ShowCaseWidget(
      builder: (context) => const _PriceMarginToolContent(),
      autoPlay: false,
      blurValue: 1,
      enableAutoScroll: true,
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
  final List<ProductModel> _selectedProducts = [];
  final _localStorage = GetStorage();

  final GlobalKey _addKey = GlobalKey();
  final GlobalKey _calculatorKey = GlobalKey();
  final GlobalKey _strategyKey = GlobalKey();
  final GlobalKey _goalKey = GlobalKey();
  final GlobalKey _shareKey = GlobalKey();

  double _sellingPrice = 0.0;
  double _targetGoal = 5000.0;
  double _currentMarginPct = 20.0; // Default 20% margin

  final double _shippingCost = 100.0;
  bool _resellerAbsorbsShipping = false;
  bool _isSharing = false;

  static const double kPlatformFeePerItem = 5.0;
  static const double kConvenienceFeeConst = 10.0;

  final TextEditingController _priceCtrl = TextEditingController();
  final TextEditingController _profitCtrl = TextEditingController();
  final TextEditingController _marginCtrl = TextEditingController(text: "20.0");
  final TextEditingController _goalCtrl = TextEditingController(text: "5000");

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAndStartTour());
  }

  void _checkAndStartTour() {
    bool hasShown =
        _localStorage.read('has_shown_profit_tool_tour_v2') ?? false;
    if (!hasShown) {
      _startTour();
      _localStorage.write('has_shown_profit_tool_tour_v2', true);
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
      ],
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

  // ─── CALCULATION ENGINE 🧠 ───

  double get _baseProductCost => _selectedProducts.fold(
    0.0,
    (sum, p) => sum + (double.tryParse(p.price) ?? 0),
  );

  double get _platformFee => _selectedProducts.isEmpty
      ? 0
      : (_selectedProducts.length * kPlatformFeePerItem);
  double get _convenienceFee =>
      _selectedProducts.isEmpty ? 0 : kConvenienceFeeConst;
  double get _shippingVal => _resellerAbsorbsShipping ? _shippingCost : 0;

  double get _totalCost =>
      _baseProductCost + _platformFee + _convenienceFee + _shippingVal;
  double get _netProfit => _sellingPrice - _totalCost;

  int get _unitsToGoal {
    if (_netProfit <= 0) return 0;
    return (_targetGoal / _netProfit).ceil();
  }

  String get _weeklyGoalText {
    if (_unitsToGoal <= 0) return "Check profit settings";
    int weekly = (_unitsToGoal / 4).ceil();
    return "${weekly < 1 ? 1 : weekly} sales / week";
  }

  double get _marketValue => _baseProductCost * 2.2;

  // --- SYNC LOGIC ---

  void _onSellingPriceChanged(String val) {
    if (val.isEmpty) return;
    double price = double.tryParse(val.replaceAll(',', '')) ?? 0;
    setState(() {
      _sellingPrice = price;
      _currentMarginPct = _totalCost > 0
          ? ((_sellingPrice - _totalCost) / _totalCost) * 100
          : 0;
      _syncControllers(source: 'price');
    });
  }

  void _onProfitChanged(String val) {
    if (val.isEmpty) return;
    double targetProfit = double.tryParse(val.replaceAll(',', '')) ?? 0;
    setState(() {
      _sellingPrice = _totalCost + targetProfit;
      _currentMarginPct = _totalCost > 0 ? (_netProfit / _totalCost) * 100 : 0;
      _syncControllers(source: 'profit');
    });
  }

  void _onMarginChanged(String val) {
    if (val.isEmpty) return;
    double marginPct = double.tryParse(val) ?? 0;
    setState(() {
      _currentMarginPct = marginPct;
      _sellingPrice = _totalCost * (1 + (marginPct / 100));
      _syncControllers(source: 'margin');
    });
  }

  void _syncControllers({required String source}) {
    if (source != 'price') _priceCtrl.text = _sellingPrice.toStringAsFixed(0);
    if (source != 'profit') _profitCtrl.text = _netProfit.toStringAsFixed(0);
    if (source != 'margin')
      _marginCtrl.text = _currentMarginPct.toStringAsFixed(1);
  }

  void _applyAutoPrice(String type) {
    double price;
    if (type == 'quick') {
      price = _totalCost * 1.15; // 15% Margin
      price = (price / 10).ceil() * 10.0 - 1;
    } else {
      price = _totalCost * 1.40; // 40% Margin
      price = (price / 100).ceil() * 100.0 - 1;
    }
    setState(() {
      _sellingPrice = price;
      _currentMarginPct = ((_sellingPrice - _totalCost) / _totalCost) * 100;
      _syncControllers(source: 'all');
    });
  }

  Future<void> _broadcastDeal() async {
    if (_selectedProducts.isEmpty) return;
    setState(() => _isSharing = true);
    try {
      final buffer = StringBuffer();
      buffer.writeln("🔥 *STEAL DEAL ALERT!* 🔥\n");
      buffer.writeln(
        _selectedProducts.length > 1
            ? "📦 *${_selectedProducts.length} Item Combo Pack*"
            : "📦 *Premium Collection Pick*",
      );
      if (_sellingPrice < _marketValue)
        buffer.writeln("❌ Market Price: ~₹${_marketValue.toStringAsFixed(0)}~");
      buffer.writeln(
        "✅ *OFFER PRICE: ₹${_sellingPrice.toStringAsFixed(0)} Only!* 🤑\n",
      );
      buffer.writeln(
        _resellerAbsorbsShipping
            ? "🚚 *Free Home Delivery*"
            : "🚚 *Fast Delivery Available*",
      );

      List<XFile> files = [];
      for (var p in _selectedProducts) {
        if (p.image.isNotEmpty)
          files.add(await ApiService.downloadImageAsFile(p.image));
      }
      await Share.shareXFiles(files, text: buffer.toString());
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        title: const Text(
          "Profit Lab",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
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
          IconButton(
            icon: const Icon(Iconsax.info_circle, color: kAccentColor),
            onPressed: _startTour,
          ),
          IconButton(
            icon: const Icon(Iconsax.refresh, color: kAccentColor),
            onPressed: () => setState(() {
              _selectedProducts.clear();
              _sellingPrice = 0;
              _syncControllers(source: 'all');
            }),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Showcase(
              key: _addKey,
              title: "Add Catalogue Items",
              description:
                  "Select products from your catalogues to build a bundle.",
              child: _buildProductStack(),
            ),
            const SizedBox(height: 20),
            if (_selectedProducts.isNotEmpty) ...[
              Showcase(
                key: _calculatorKey,
                title: "Margin Calculator",
                description: "Adjust your percentage margin to see profit.",
                child: _buildMainDashboard(),
              ),
              const SizedBox(height: 16),
              _buildCostSummary(),
              const SizedBox(height: 20),
              Showcase(
                key: _strategyKey,
                title: "Pricing Strategy",
                description:
                    "Quickly set margins for fast sales or max profit.",
                child: _buildStrategyPad(),
              ),
              const SizedBox(height: 20),
              Showcase(
                key: _goalKey,
                title: "Earning Goal",
                description:
                    "Set a monthly target and see how many sales you need.",
                child: _buildEnhancedGoalTracker(),
              ),
              const SizedBox(height: 24),
              Showcase(
                key: _shareKey,
                title: "Broadcast",
                description: "Share images and price to WhatsApp.",
                child: _buildDealBroadcaster(),
              ),
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
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              Text(
                "Pull products from your catalogues",
                style: TextStyle(color: Colors.grey, fontSize: 11),
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
            ),
          ],
        ),
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
                    onTap: () => setState(() {
                      _selectedProducts.removeAt(i);
                      _onMarginChanged(_currentMarginPct.toString());
                    }),
                    child: Container(
                      margin: const EdgeInsets.all(4),
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
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "CUSTOMER PAYS",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
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
                  color: Colors.black26,
                ),
              ),
              IntrinsicWidth(
                child: TextField(
                  controller: _priceCtrl,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: "0",
                  ),
                  onChanged: _onSellingPriceChanged,
                ),
              ),
            ],
          ),
          const Divider(height: 30),
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
          _buildShippingToggle(),
        ],
      ),
    );
  }

  Widget _buildShippingToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: kBgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Iconsax.truck_fast, size: 18, color: Colors.purple),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              "Free Shipping (You will pay)",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          Switch(
            value: _resellerAbsorbsShipping,
            activeColor: Colors.purple,
            onChanged: (v) => setState(() {
              _resellerAbsorbsShipping = v;
              _onMarginChanged(_currentMarginPct.toString());
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCostSummary() => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: kSurface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Break-Even Cost",
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        Text(
          "₹${_totalCost.toStringAsFixed(0)}",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: kCostColor,
          ),
        ),
      ],
    ),
  );

  Widget _buildStrategyPad() => Row(
    children: [
      Expanded(
        child: _strategyBtn(
          "🚀 Quick Sell",
          "15% Margin",
          () => _applyAutoPrice('quick'),
          Colors.orange,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _strategyBtn(
          "💎 Max Profit",
          "40% Margin",
          () => _applyAutoPrice('max'),
          Colors.purple,
        ),
      ),
    ],
  );

  Widget _strategyBtn(
    String label,
    String sub,
    VoidCallback onTap,
    Color color,
  ) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
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
          Text(sub, style: TextStyle(fontSize: 10, color: color)),
        ],
      ),
    ),
  );

  Widget _buildEnhancedGoalTracker() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: kSurface,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      children: [
        Row(
          children: [
            const Icon(Iconsax.status_up, color: Colors.blueGrey),
            const SizedBox(width: 12),
            const Text(
              "Monthly Earning Goal",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Container(
              width: 80,
              decoration: BoxDecoration(
                color: kBgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _goalCtrl,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8),
                  prefixText: "₹",
                ),
                onChanged: (v) =>
                    setState(() => _targetGoal = double.tryParse(v) ?? 0),
              ),
            ),
          ],
        ),
        const Divider(height: 30),
        _netProfit <= 0
            ? const Text(
                "⚠️ Increase margin to calculate goal",
                style: TextStyle(color: Colors.red, fontSize: 12),
              )
            : Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "SALES NEEDED",
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                        Text(
                          "$_unitsToGoal Bundles",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "WEEKLY PACE",
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
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

  Widget _buildDealBroadcaster() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFF1E293B),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      children: [
        const Text(
          "READY TO SHARE?",
          style: TextStyle(
            color: Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _isSharing ? null : _broadcastDeal,
          icon: _isSharing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Iconsax.share, color: Colors.black),
          label: const Text(
            "Share Deal to WhatsApp",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    ),
  );

  Future<void> _pickProducts() async {
    final List<ProductModel>? picked = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _MultiProductPickerSheet(),
    );
    if (picked != null) {
      setState(() {
        _selectedProducts.addAll(picked);
        _onMarginChanged(_currentMarginPct.toString());
      });
    }
  }
}

// ─── CATALOGUE PRODUCT PICKER ───
class _MultiProductPickerSheet extends StatefulWidget {
  const _MultiProductPickerSheet();
  @override
  State<_MultiProductPickerSheet> createState() =>
      _MultiProductPickerSheetState();
}

class _MultiProductPickerSheetState extends State<_MultiProductPickerSheet> {
  final CatalogueController catalogueController =
      Get.find<CatalogueController>();
  List<ProductModel> _allProducts = [];
  List<ProductModel> _filtered = [];
  final Set<ProductModel> _selected = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    // Merge all products from all user catalogues
    final products = catalogueController.myCatalogues
        .expand((c) => c.products)
        .toSet()
        .toList();
    setState(() {
      _allProducts = products;
      _filtered = products;
      _isLoading = false;
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
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Catalogue Items",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (_selected.isNotEmpty)
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, _selected.toList()),
                    child: const Text("Add Selected"),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search in catalogues...',
                prefixIcon: const Icon(Iconsax.search_normal),
                filled: true,
                fillColor: kBgColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(
                () => _filtered = _allProducts
                    .where(
                      (p) => p.name.toLowerCase().contains(v.toLowerCase()),
                    )
                    .toList(),
              ),
            ),
          ),
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
                    itemCount: _filtered.length,
                    itemBuilder: (ctx, i) {
                      final p = _filtered[i];
                      final isSel = _selected.contains(p);
                      return GestureDetector(
                        onTap: () => setState(
                          () => isSel ? _selected.remove(p) : _selected.add(p),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSel
                                  ? kAccentColor
                                  : Colors.grey.shade200,
                              width: isSel ? 3 : 1,
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
