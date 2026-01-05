import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kakiso_reseller_app/utils/constants.dart';

class PricingCalculator extends StatefulWidget {
  final double productCost;

  const PricingCalculator({super.key, required this.productCost});

  @override
  State<PricingCalculator> createState() => _PricingCalculatorState();
}

class _PricingCalculatorState extends State<PricingCalculator> {
  // Controllers
  final TextEditingController _marginController = TextEditingController();
  final TextEditingController _totalPriceController = TextEditingController();

  // Focus Nodes
  final FocusNode _marginFocus = FocusNode();
  final FocusNode _priceFocus = FocusNode();

  // State Variables
  double _margin = 0.0;
  double _totalPrice = 0.0;

  // Message Configuration Toggles
  bool _includePrice = true;
  bool _includeShipping = true;
  bool _includeReturns = true;

  @override
  void initState() {
    super.initState();
    _resetToDefault();

    _marginController.addListener(_onMarginChanged);
    _totalPriceController.addListener(_onPriceChanged);
  }

  void _resetToDefault() {
    // Default Strategy: Cost + 20%
    double initialMargin = (widget.productCost * 0.20);
    _updateValues(newMargin: initialMargin);
  }

  @override
  void dispose() {
    _marginController.dispose();
    _totalPriceController.dispose();
    _marginFocus.dispose();
    _priceFocus.dispose();
    super.dispose();
  }

  // --- CALCULATION LOGIC ---

  void _updateValues({required double newMargin}) {
    setState(() {
      _margin = newMargin;
      _totalPrice = widget.productCost + _margin;
    });

    if (!_marginFocus.hasFocus) {
      _marginController.text = _margin.toStringAsFixed(0);
    }
    if (!_priceFocus.hasFocus) {
      _totalPriceController.text = _totalPrice.toStringAsFixed(0);
    }
  }

  void _onMarginChanged() {
    if (!_marginFocus.hasFocus) return;
    String text = _marginController.text.replaceAll(RegExp(r'[^0-9.-]'), '');
    double val = double.tryParse(text) ?? 0.0;

    setState(() {
      _margin = val;
      _totalPrice = widget.productCost + _margin;
    });

    String newTotal = _totalPrice.toStringAsFixed(0);
    if (_totalPriceController.text != newTotal) {
      _totalPriceController.text = newTotal;
    }
  }

  void _onPriceChanged() {
    if (!_priceFocus.hasFocus) return;
    String text = _totalPriceController.text.replaceAll(
      RegExp(r'[^0-9.-]'),
      '',
    );
    double val = double.tryParse(text) ?? 0.0;

    setState(() {
      _totalPrice = val;
      _margin = _totalPrice - widget.productCost;
    });

    String newMargin = _margin.toStringAsFixed(0);
    if (_marginController.text != newMargin) {
      _marginController.text = newMargin;
    }
  }

  void _applyQuickMargin(double value, {bool isPercentage = false}) {
    HapticFeedback.selectionClick();
    FocusScope.of(context).unfocus();
    double calcMargin = isPercentage
        ? (widget.productCost * (value / 100))
        : value;
    _updateValues(newMargin: calcMargin);
  }

  void _applyPsychologicalPricing() {
    // Rounds to nearest 9 (e.g. 105 -> 109, 112 -> 119) or just subtract 1?
    // Let's do simple logic: If price is 500, make it 499.
    HapticFeedback.mediumImpact();
    FocusScope.of(context).unfocus();

    double current = _totalPrice;
    double target = (current / 100).ceil() * 100 - 1; // e.g. 450 -> 499

    if (target <= widget.productCost) {
      // Avoid loss, just add 99 to base
      target = widget.productCost + 99;
    }

    double newMargin = target - widget.productCost;
    _updateValues(newMargin: newMargin);
  }

  // --- MESSAGE GENERATION ---

  String _generateMessage() {
    final StringBuffer buffer = StringBuffer();
    buffer.writeln("🛍️ *Best Quality Product*");

    if (_includePrice) {
      buffer.writeln("💰 Price: *₹${_totalPrice.toStringAsFixed(0)}*");
    } else {
      buffer.writeln("💰 Price: *DM for Price*");
    }

    if (_includeShipping) buffer.writeln("🚚 *Free Express Shipping*");
    if (_includeReturns) buffer.writeln("↩️ *Easy 7-Day Returns*");

    buffer.writeln("✅ *Prepaid / Online Payment*");
    buffer.write("\n👇 *Reply to book order now!*");

    return buffer.toString();
  }

  void _copyToClipboard() {
    HapticFeedback.mediumImpact();
    Clipboard.setData(ClipboardData(text: _generateMessage()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Iconsax.copy_success, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Text("Details copied to clipboard!"),
          ],
        ),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isLoss = _margin < 0;
    // Reseller Green/Red
    final Color profitColor = isLoss
        ? const Color(0xFFD32F2F)
        : const Color(0xFF2E7D32);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 16 : 0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- 1. HEADER (Product Cost) ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,

                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  const Icon(Iconsax.tag, size: 18, color: Colors.black54),
                  const SizedBox(width: 10),
                  Text(
                    "Product Cost:",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    "₹${widget.productCost.toStringAsFixed(0)}",
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- 2. INPUTS (Bi-Directional) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  // MARGIN
                  Expanded(
                    child: _buildInputBox(
                      controller: _marginController,
                      node: _marginFocus,
                      label: "Your Margin",
                      color: profitColor,
                      isMargin: true,
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(
                      Icons.add,
                      color: Colors.grey.shade300,
                      size: 24,
                    ),
                  ),

                  // TOTAL PRICE
                  Expanded(
                    child: _buildInputBox(
                      controller: _totalPriceController,
                      node: _priceFocus,
                      label: "Final Price",
                      color: Colors.black87,
                      isMargin: false,
                    ),
                  ),
                ],
              ),
            ),

            // PROFIT TEXT
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 20),
              child: Text(
                isLoss
                    ? "⚠️ Selling at Loss of ₹${_margin.abs().toStringAsFixed(0)}"
                    : "🎉 You earn ₹${_margin.toStringAsFixed(0)} on this order",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: profitColor,
                  fontFamily: 'Poppins',
                ),
              ),
            ),

            const Divider(height: 1, color: Color(0xFFEEEEEE)),

            // --- 3. QUICK ACTIONS ---
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                children: [
                  _buildChip("15%", 15, true),
                  _buildChip("25%", 25, true),
                  _buildChip("₹100", 100, false),
                  _buildChip("₹200", 200, false),
                  // PSYCHOLOGICAL PRICING BUTTON
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: ActionChip(
                      label: const Text("Make it ₹99"),
                      labelStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      backgroundColor: accentColor,
                      padding: EdgeInsets.zero,
                      onPressed: _applyPsychologicalPricing,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: Color(0xFFEEEEEE)),

            // --- 4. LIVE MESSAGE PREVIEW ---
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Message Preview",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // CHAT BUBBLE
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCF8C6), // WhatsApp Greenish
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      _generateMessage(),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- 5. TOGGLES & ACTIONS ---
            Container(
              color: const Color(0xFFF9FAFB),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildToggle(
                        "Price",
                        _includePrice,
                        (v) => setState(() => _includePrice = v),
                      ),
                      _buildToggle(
                        "Free Ship",
                        _includeShipping,
                        (v) => setState(() => _includeShipping = v),
                      ),
                      _buildToggle(
                        "Returns",
                        _includeReturns,
                        (v) => setState(() => _includeReturns = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // COPY BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _copyToClipboard,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(
                          221,
                          222,
                          19,
                          178,
                        ),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Iconsax.copy, size: 20),
                      label: const Text(
                        "Copy to Clipboard",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
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

  // --- WIDGET BUILDERS ---

  Widget _buildInputBox({
    required TextEditingController controller,
    required FocusNode node,
    required String label,
    required Color color,
    required bool isMargin,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: node.hasFocus ? color : Colors.grey.shade300,
              width: node.hasFocus ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 12, right: 4),
                child: Text(
                  "₹",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade400,
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: node,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                    color: color,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChip(String label, double val, bool isPercent) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => _applyQuickMargin(val, isPercentage: isPercent),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            isPercent ? "+$label" : "+ $label",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggle(String label, bool value, Function(bool) onChanged) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onChanged(!value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: value ? accentColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: value ? accentColor : Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              value ? Icons.check_circle : Icons.circle_outlined,
              size: 14,
              color: value ? accentColor : Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: value ? accentColor : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
