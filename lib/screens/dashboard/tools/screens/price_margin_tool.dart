// lib/screens/dashboard/tools/price_margin_tool.dart

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/services/api_services.dart';
import 'package:kakiso_reseller_app/screens/dashboard/tools/tools.dart'; // for accentColor

class PriceMarginToolPage extends StatefulWidget {
  const PriceMarginToolPage({super.key});

  @override
  State<PriceMarginToolPage> createState() => _PriceMarginToolPageState();
}

class _PriceMarginToolPageState extends State<PriceMarginToolPage> {
  // Margin & rounding controllers
  final TextEditingController _markupController = TextEditingController(
    text: '20',
  );
  final TextEditingController _roundingController = TextEditingController(
    text: '9',
  );

  // Optional: user can type a custom selling price to see margin
  final TextEditingController _customSellingController =
      TextEditingController();

  ProductModel? _selectedProduct;

  double _marginSlider = 20;
  int _roundingDigit = 9;

  @override
  void initState() {
    super.initState();
    _marginSlider = double.tryParse(_markupController.text) ?? 20;
    _roundingDigit = int.tryParse(_roundingController.text) ?? 9;
  }

  // ---------------------------------------------------------------------------
  //  PRICE / MARGIN LOGIC
  // ---------------------------------------------------------------------------

  double? _parsePrice(String? priceStr) {
    if (priceStr == null) return null;
    return double.tryParse(priceStr);
  }

  /// Base = your buy price (what you pay to Kakiso)
  double? get _basePrice {
    if (_selectedProduct == null) return null;
    return _parsePrice(_selectedProduct!.price);
  }

  double? get _mrpPrice {
    if (_selectedProduct == null) return null;
    return _parsePrice(_selectedProduct!.regularPrice);
  }

  /// Core margin calculation with rounding.
  double? _calcSuggestedPrice(double base) {
    final markup = double.tryParse(_markupController.text) ?? _marginSlider;
    final roundingText = _roundingController.text.trim();
    final roundingDigit =
        int.tryParse(roundingText.isEmpty ? '0' : roundingText) ?? 0;

    var p = base * (1 + markup / 100);

    if (roundingDigit > 0) {
      // Example: want last digit 9 -> 349, 459, 999 etc.
      final baseRoundedTo10 = (p / 10).ceil() * 10; // 343 -> 350
      p = (baseRoundedTo10 - (10 - roundingDigit)).toDouble(); // 350 - 1 = 349
    }

    return p;
  }

  double? _profit(double? base, double? sell) {
    if (base == null || sell == null) return null;
    return sell - base;
  }

  double? _margin(double? base, double? sell) {
    if (base == null || sell == null || base == 0) return null;
    return (sell - base) / base * 100;
  }

  void _applyPresetMargin(double value) {
    _marginSlider = value;
    _markupController.text = value.toStringAsFixed(0);
    setState(() {});
  }

  void _updateRoundingDigit(int value) {
    _roundingDigit = value;
    _roundingController.text = value.toString();
    setState(() {});
  }

  // ---------------------------------------------------------------------------
  //  PRODUCT PICKER
  // ---------------------------------------------------------------------------

  Future<void> _pickProduct() async {
    final ProductModel? picked = await showModalBottomSheet<ProductModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _ProductPickerSheet(),
    );

    if (picked != null) {
      setState(() {
        _selectedProduct = picked;
      });
    }
  }

  // ---------------------------------------------------------------------------
  //  UI BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final base = _basePrice;
    final suggested = (base != null) ? _calcSuggestedPrice(base) : null;
    final profit = _profit(base, suggested);
    final margin = _margin(base, suggested);

    final customSell = double.tryParse(
      _customSellingController.text.trim().isEmpty
          ? '0'
          : _customSellingController.text.trim(),
    );
    final customMargin = _margin(base, customSell);
    final customProfit = _profit(base, customSell);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: accentColor,
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Iconsax.activity, color: accentColor),
            ),
            const SizedBox(width: 10),
            const Text(
              'Smart price & margin',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: Color(0xFF111827),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE0ECFF), Color(0xFFF3F4F6)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeroCard(),
                  const SizedBox(height: 14),
                  _buildProductCard(),
                  const SizedBox(height: 14),
                  if (_selectedProduct == null)
                    _buildEmptyStateCard()
                  else ...[
                    _buildBasePriceSummary(base, suggested),
                    const SizedBox(height: 14),
                    _buildMarginControls(),
                    const SizedBox(height: 14),
                    _buildSuggestionCard(
                      base: base,
                      suggested: suggested,
                      profit: profit,
                      margin: margin,
                    ),
                    const SizedBox(height: 14),
                    _buildCustomPriceCard(
                      base: base,
                      customSell: customSell,
                      customMargin: customMargin,
                      customProfit: customProfit,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  //  TOP HERO
  // ---------------------------------------------------------------------------

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                colors: [
                  accentColor.withOpacity(0.9),
                  accentColor.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(
              Iconsax.dollar_circle,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Set a profitable selling price',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: Color(0xFF111827),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Pick a product, choose your margin and get instant suggested prices with profit & margin insights.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF6B7280),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  //  PRODUCT CARD
  // ---------------------------------------------------------------------------

  Widget _buildProductCard() {
    final p = _selectedProduct;
    final hasProduct = p != null;
    final base = _basePrice;

    return GestureDetector(
      onTap: _pickProduct,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xFFF3F4F6),
              ),
              child: hasProduct && (p.image.isNotEmpty)
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        p.image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Iconsax.image, color: Colors.grey),
                      ),
                    )
                  : const Icon(
                      Iconsax.bag_happy,
                      color: Color(0xFF9CA3AF),
                      size: 28,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: hasProduct
                    ? Column(
                        key: const ValueKey('product'),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (base != null)
                            Text(
                              'Your buy price: ₹${base.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: Color(0xFF059669),
                              ),
                            ),
                          if (p.brandName != null &&
                              p.brandName!.trim().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                p.brandName!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF9CA3AF),
                                ),
                              ),
                            ),
                        ],
                      )
                    : Column(
                        key: const ValueKey('empty'),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Step 1 · Select a product',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Color(0xFF111827),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Tap here to choose a product. We will use its buy price to calculate smart selling prices.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  Icon(
                    hasProduct ? Iconsax.refresh : Iconsax.add_circle,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    hasProduct ? 'Change' : 'Choose',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  //  EMPTY STATE (AFTER PRODUCT CARD)
  // ---------------------------------------------------------------------------

  Widget _buildEmptyStateCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        children: const [
          Icon(Iconsax.info_circle, color: Color(0xFF047857)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Select a product to see recommended selling price, profit per unit and margin insights.',
              style: TextStyle(
                fontSize: 12.5,
                color: Color(0xFF047857),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  //  BASE PRICE SUMMARY
  // ---------------------------------------------------------------------------

  Widget _buildBasePriceSummary(double? base, double? suggested) {
    final mrp = _mrpPrice;
    final hasMrp = mrp != null && mrp > 0 && base != null;
    final discount = hasMrp
        ? ((mrp - base) / mrp * 100).clamp(0, 100).toDouble()
        : null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: const [
              Icon(Iconsax.chart_square, size: 18, color: Color(0xFF4B5563)),
              SizedBox(width: 8),
              Text(
                'Price overview',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _smallMetric(
                label: 'Your buy price',
                value: base == null ? '--' : '₹${base.toStringAsFixed(0)}',
                chipColor: const Color(0xFFDBEAFE),
                valueColor: const Color(0xFF1D4ED8),
              ),
              const SizedBox(width: 10),
              _smallMetric(
                label: 'Recommended',
                value: suggested == null
                    ? '--'
                    : '₹${suggested.toStringAsFixed(0)}',
                chipColor: const Color(0xFFDCFCE7),
                valueColor: const Color(0xFF16A34A),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (hasMrp && discount != null)
            Row(
              children: [
                _smallMetric(
                  label: 'MRP',
                  value: '₹${mrp.toStringAsFixed(0)}',
                  chipColor: const Color(0xFFFEE2E2),
                  valueColor: const Color(0xFFB91C1C),
                ),
                const SizedBox(width: 10),
                _smallMetric(
                  label: 'You get off MRP',
                  value: '${discount.toStringAsFixed(1)}%',
                  chipColor: const Color(0xFFF5F3FF),
                  valueColor: const Color(0xFF7C3AED),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _smallMetric({
    required String label,
    required String value,
    required Color chipColor,
    required Color valueColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: chipColor.withOpacity(0.25),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: chipColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: valueColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  //  MARGIN CONTROLS
  // ---------------------------------------------------------------------------

  Widget _buildMarginControls() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: const [
              Icon(
                Iconsax.slider_horizontal,
                size: 18,
                color: Color(0xFF4B5563),
              ),
              SizedBox(width: 8),
              Text(
                'Margin settings',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Margin slider
          Row(
            children: [
              const Text(
                'Target margin',
                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
              const Spacer(),
              SizedBox(
                width: 70,
                child: TextField(
                  controller: _markupController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    suffixText: '%',
                    border: OutlineInputBorder(),
                  ),
                  style: const TextStyle(fontSize: 12),
                  onChanged: (v) {
                    final val = double.tryParse(v) ?? _marginSlider;
                    _marginSlider = val.clamp(0, 200);
                    setState(() {});
                  },
                ),
              ),
            ],
          ),
          Slider(
            value: _marginSlider.clamp(0, 200),
            min: 0,
            max: 100,
            divisions: 20,
            label: '${_marginSlider.toStringAsFixed(0)}%',
            activeColor: accentColor,
            onChanged: (v) {
              setState(() {
                _marginSlider = v;
                _markupController.text = v.toStringAsFixed(0);
              });
            },
          ),

          // Preset chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _marginChip(10),
              _marginChip(20),
              _marginChip(30),
              _marginChip(40),
              _marginChip(50),
            ],
          ),

          const SizedBox(height: 12),

          // Rounding row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Rounding',
                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
              const SizedBox(width: 6),
              const Text(
                '(last digit)',
                style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
              ),
              const Spacer(),
              SizedBox(
                width: 65,
                child: TextField(
                  controller: _roundingController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    border: OutlineInputBorder(),
                  ),
                  style: const TextStyle(fontSize: 12),
                  onChanged: (v) {
                    final val = int.tryParse(v) ?? _roundingDigit;
                    _roundingDigit = val.clamp(0, 9);
                    setState(() {});
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [_roundingChip(9), _roundingChip(5), _roundingChip(0)],
          ),
        ],
      ),
    );
  }

  Widget _marginChip(double value) {
    final selected =
        _marginSlider.toStringAsFixed(0) == value.toStringAsFixed(0);
    return ChoiceChip(
      selected: selected,
      label: Text('${value.toStringAsFixed(0)}%'),
      selectedColor: accentColor.withOpacity(0.12),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(
          color: selected
              ? accentColor.withOpacity(0.7)
              : const Color(0xFFE5E7EB),
        ),
      ),
      labelStyle: TextStyle(
        color: selected ? accentColor : const Color(0xFF4B5563),
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        fontSize: 12,
      ),
      onSelected: (_) => _applyPresetMargin(value),
    );
  }

  Widget _roundingChip(int digit) {
    final selected = _roundingDigit == digit;
    return ChoiceChip(
      selected: selected,
      label: Text(digit.toString()),
      selectedColor: const Color(0xFFF97316).withOpacity(0.12),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(
          color: selected ? const Color(0xFFF97316) : const Color(0xFFE5E7EB),
        ),
      ),
      labelStyle: TextStyle(
        color: selected ? const Color(0xFFF97316) : const Color(0xFF4B5563),
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        fontSize: 12,
      ),
      onSelected: (_) => _updateRoundingDigit(digit),
    );
  }

  // ---------------------------------------------------------------------------
  //  SUGGESTION CARD
  // ---------------------------------------------------------------------------

  Widget _buildSuggestionCard({
    required double? base,
    required double? suggested,
    required double? profit,
    required double? margin,
  }) {
    final hasData = base != null && suggested != null && profit != null;

    final safePrice = base != null
        ? _calcSuggestedPrice(base * 0.0 + base * 1.15)
        : null; // ~15% margin
    final goodPrice = base != null
        ? _calcSuggestedPrice(base * 0.0 + base * 1.25)
        : null; // ~25%
    final premiumPrice = base != null
        ? _calcSuggestedPrice(base * 0.0 + base * 1.35)
        : null; // ~35%

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Iconsax.money, color: Color(0xFF4B5563), size: 18),
              const SizedBox(width: 8),
              const Text(
                'Recommended selling price',
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
              const Spacer(),
              if (margin != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${margin.toStringAsFixed(1)}% margin',
                    style: const TextStyle(
                      color: Color(0xFF166534),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (!hasData)
            const Text(
              'Adjust margin above to see profit suggestions.',
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 12.5),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main price line
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${suggested.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '+₹${profit.toStringAsFixed(0)} / unit',
                        style: const TextStyle(
                          color: Color(0xFF166534),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'This is the selling price you can charge to earn a healthy profit while staying competitive.',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(color: Color(0xFFE5E7EB), height: 18),
                const SizedBox(height: 6),
                const Text(
                  'Quick scenarios',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _scenarioPill(
                      label: 'Safe',
                      subtitle: '~15% margin',
                      price: safePrice,
                      base: base,
                    ),
                    const SizedBox(width: 8),
                    _scenarioPill(
                      label: 'Balanced',
                      subtitle: '~25% margin',
                      price: goodPrice,
                      base: base,
                    ),
                    const SizedBox(width: 8),
                    _scenarioPill(
                      label: 'Premium',
                      subtitle: '~35% margin',
                      price: premiumPrice,
                      base: base,
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _scenarioPill({
    required String label,
    required String subtitle,
    required double? price,
    required double base,
  }) {
    if (price == null) {
      return Expanded(
        child: Opacity(
          opacity: 0.3,
          child: _scenarioBox(
            label: label,
            subtitle: subtitle,
            priceText: '--',
            profitText: '',
          ),
        ),
      );
    }

    final profit = price - base;
    final margin = (profit / base * 100);
    return Expanded(
      child: _scenarioBox(
        label: label,
        subtitle: subtitle,
        priceText: '₹${price.toStringAsFixed(0)}',
        profitText:
            '+₹${profit.toStringAsFixed(0)} • ${margin.toStringAsFixed(0)}%',
      ),
    );
  }

  Widget _scenarioBox({
    required String label,
    required String subtitle,
    required String priceText,
    required String profitText,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontWeight: FontWeight.w600,
              fontSize: 11.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 10.5),
          ),
          const SizedBox(height: 4),
          Text(
            priceText,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (profitText.isNotEmpty)
            Text(
              profitText,
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 10),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  //  CUSTOM PRICE CARD
  // ---------------------------------------------------------------------------

  Widget _buildCustomPriceCard({
    required double? base,
    required double? customSell,
    required double? customMargin,
    required double? customProfit,
  }) {
    final hasBase = base != null;
    final hasCustom = hasBase && (customSell != null && customSell > 0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: const [
              Icon(Iconsax.calculator, size: 18, color: Color(0xFF4B5563)),
              SizedBox(width: 8),
              Text(
                'Try your own price',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customSellingController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Your selling price',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                tooltip: 'Clear',
                onPressed: () {
                  _customSellingController.clear();
                  setState(() {});
                },
                icon: const Icon(Iconsax.close_circle),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (!hasBase)
            const Text(
              'We need a base (buy) price from the product to calculate margin.',
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            )
          else if (!hasCustom)
            const Text(
              'Enter any selling price to see how much profit and margin you will make.',
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            )
          else
            Row(
              children: [
                _smallMetric(
                  label: 'Profit per unit',
                  value: customProfit == null
                      ? '--'
                      : '₹${customProfit.toStringAsFixed(0)}',
                  chipColor: const Color(0xFFDCFCE7),
                  valueColor: const Color(0xFF16A34A),
                ),
                const SizedBox(width: 10),
                _smallMetric(
                  label: 'Margin',
                  value: customMargin == null
                      ? '--'
                      : '${customMargin.toStringAsFixed(1)}%',
                  chipColor: const Color(0xFFE0F2FE),
                  valueColor: const Color(0xFF0284C7),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ============================================================================
//  PRODUCT PICKER SHEET
// ============================================================================

class _ProductPickerSheet extends StatefulWidget {
  const _ProductPickerSheet({Key? key}) : super(key: key);

  @override
  State<_ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends State<_ProductPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ProductModel> _products = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadInitial();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadInitial() async {
    setState(() {
      _isLoading = true;
      _hasMore = true;
      _page = 1;
      _products.clear();
    });

    try {
      final items = _query.isEmpty
          ? await ApiService.fetchProducts(page: _page, perPage: 20)
          : await ApiService.searchProducts(_query);

      setState(() {
        _products = items;
        _isLoading = false;
        _hasMore = _query.isEmpty && items.length == 20;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load products: $e')));
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || _query.isNotEmpty) return;

    setState(() => _isLoadingMore = true);
    try {
      final nextPage = _page + 1;
      final items = await ApiService.fetchProducts(page: nextPage, perPage: 20);
      setState(() {
        _page = nextPage;
        _products.addAll(items);
        _hasMore = items.length == 20;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() => _isLoadingMore = false);
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels > pos.maxScrollExtent * 0.7) {
      _loadMore();
    }
  }

  void _onSearchChanged(String value) {
    _query = value.trim();
    _loadInitial();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: const [
                  Icon(Iconsax.bag_2),
                  SizedBox(width: 8),
                  Text(
                    'Pick a product',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Color(0xFF111827),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: const Icon(Iconsax.search_normal),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
                onChanged: _onSearchChanged,
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _products.isEmpty
                  ? Center(
                      child: Text(
                        'No products found',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: _products.length + (_isLoadingMore ? 1 : 0),
                      itemBuilder: (ctx, idx) {
                        if (idx >= _products.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        }
                        final p = _products[idx];
                        return _ProductTile(
                          product: p,
                          onTap: () => Navigator.pop(context, p),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;

  const _ProductTile({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasDiscount =
        product.discountPercentage != null && product.discountPercentage! > 0;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  color: Colors.grey.shade200,
                  width: 64,
                  height: 64,
                  child: product.image.isNotEmpty
                      ? Image.network(
                          product.image,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Iconsax.image),
                        )
                      : const Icon(Iconsax.image),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '₹${product.price}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (hasDiscount)
                          Text(
                            '₹${product.regularPrice}',
                            style: TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey.shade500,
                              fontSize: 11,
                            ),
                          ),
                        if (hasDiscount) const SizedBox(width: 4),
                        if (hasDiscount)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '-${product.discountPercentage}%',
                              style: TextStyle(
                                color: Colors.red.shade600,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (product.brandName != null &&
                        product.brandName!.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          product.brandName!,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Iconsax.arrow_right_3, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
