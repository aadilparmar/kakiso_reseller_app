import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kakiso_reseller_app/utils/constants.dart'; // For accentColor

class PricingCalculator extends StatefulWidget {
  final double productCost; // Base cost from API

  const PricingCalculator({super.key, required this.productCost});

  @override
  State<PricingCalculator> createState() => _PricingCalculatorState();
}

class _PricingCalculatorState extends State<PricingCalculator> {
  // Controller for the Editable Field
  final _sellingPriceController = TextEditingController();

  // State Variables
  double _costPrice = 0.0;
  double _sellingPrice = 0.0;

  // Derived Values
  double _profit = 0.0;
  double _markupPercentage = 10.0; // Starts at 10% minimum

  @override
  void initState() {
    super.initState();
    _costPrice = widget.productCost;

    // Initial State: Cost + 10% Markup
    _updateSellingPriceFromMarkup(10.0);
  }

  @override
  void dispose() {
    _sellingPriceController.dispose();
    super.dispose();
  }

  // 1. Logic: User Types Manual Price
  void _calculateFromInput(String val) {
    // Remove non-numeric except decimal
    String cleanVal = val.replaceAll(RegExp(r'[^0-9.]'), '');
    double sell = double.tryParse(cleanVal) ?? 0.0;

    setState(() {
      _sellingPrice = sell;
      _profit = _sellingPrice - _costPrice;

      if (_costPrice > 0) {
        // Markup Formula
        _markupPercentage = ((_sellingPrice - _costPrice) / _costPrice) * 100;
      } else {
        _markupPercentage = 0.0;
      }
    });
  }

  // 2. Logic: User Slides or Clicks Chip
  void _updateSellingPriceFromMarkup(double percentage) {
    setState(() {
      _markupPercentage = percentage;
      // Price Formula: Cost * (1 + Markup/100)
      _sellingPrice = _costPrice * (1 + (_markupPercentage / 100));
      _profit = _sellingPrice - _costPrice;

      // Update text field without triggering infinite loop
      _sellingPriceController.text = _sellingPrice.toStringAsFixed(0);
    });
  }

  // 3. Logic: Copy Quote for Customer
  void _copyQuoteToClipboard() {
    final String quote =
        "Price: ₹${_sellingPrice.toStringAsFixed(0)}\nFree Shipping Available!\nDM to order.";
    Clipboard.setData(ClipboardData(text: quote));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text("Price quote copied!"),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isProfitable = _profit >= 0;
    final Color statusColor = isProfitable ? Colors.green : Colors.red;

    // Calculate Flex ratio for the visual bar
    double total = _costPrice + (_profit > 0 ? _profit : 0);
    int costFlex = total > 0 ? ((_costPrice / total) * 100).toInt() : 1;
    int profitFlex = total > 0 ? ((_profit / total) * 100).toInt() : 0;
    if (profitFlex < 0) profitFlex = 0; // Safety

    return Container(
      padding: const EdgeInsets.all(20), // Reduced padding slightly for safety
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- HEADER (FIXED OVERFLOW) ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left Side (Title)
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Iconsax.calculator,
                        color: accentColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Flexible(
                      child: Text(
                        "Profit Calculator",
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Right Side (Badge)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isProfitable ? Icons.trending_up : Icons.trending_down,
                      size: 14,
                      color: statusColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "₹${_profit.toStringAsFixed(0)} PROFIT",
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // --- VISUAL BAR (Cost vs Profit) ---
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  Expanded(
                    flex: costFlex,
                    child: Container(color: Colors.grey.shade300),
                  ),
                  Expanded(
                    flex: profitFlex,
                    child: Container(color: accentColor),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Cost: ₹${_costPrice.toStringAsFixed(0)}",
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  "Your Margin: ${_markupPercentage.toStringAsFixed(0)}%",
                  style: const TextStyle(
                    fontSize: 10,
                    color: accentColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // --- INPUTS ---
          Row(
            children: [
              // Input Field
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Selling Price",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _sellingPriceController,
                      keyboardType: TextInputType.number,
                      onChanged: _calculateFromInput,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                      decoration: InputDecoration(
                        prefixText: "₹ ",
                        prefixStyle: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 16,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: accentColor,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Copy Button
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("", style: TextStyle(fontSize: 12)), // Spacer
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 50, // Match input height
                      child: ElevatedButton(
                        onPressed: _copyQuoteToClipboard,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.copy, size: 16, color: Colors.white),
                            SizedBox(width: 6),
                            Text(
                              "Copy",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // --- SLIDER SECTION ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Quick Markup",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              Text(
                "${_markupPercentage.toStringAsFixed(0)}%",
                style: const TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: accentColor,
              inactiveTrackColor: accentColor.withOpacity(0.1),
              thumbColor: Colors.white,
              overlayColor: accentColor.withOpacity(0.1),
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 10,
                elevation: 4,
              ),
            ),
            child: Slider(
              value: _markupPercentage.clamp(10.0, 300.0),
              min: 10.0,
              max: 300.0,
              divisions: 29,
              label: "${_markupPercentage.toStringAsFixed(0)}%",
              onChanged: (value) => _updateSellingPriceFromMarkup(value),
            ),
          ),

          // --- QUICK CHIPS (FIXED OVERFLOW) ---
          // Wrapped in SingleChildScrollView for safety on small screens
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickChip("10%", 10.0),
                const SizedBox(width: 8),
                _buildQuickChip("20%", 20.0),
                const SizedBox(width: 8),
                _buildQuickChip("50%", 50.0),
                const SizedBox(width: 8),
                _buildQuickChip("100%", 100.0),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip(String label, double value) {
    final bool isActive = (_markupPercentage - value).abs() < 1;
    return GestureDetector(
      onTap: () => _updateSellingPriceFromMarkup(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? accentColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? accentColor : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}
