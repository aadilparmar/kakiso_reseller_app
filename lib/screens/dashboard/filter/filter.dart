import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';

// ─────────────────────────────────────────────────────────────
//  FILTER MODEL
// ─────────────────────────────────────────────────────────────
enum SortType { relevance, priceLowToHigh, priceHighToLow, newest }

class FilterOptions {
  SortType sortType;
  double? minPrice;
  double? maxPrice;
  bool inStockOnly;

  FilterOptions({
    this.sortType = SortType.relevance,
    this.minPrice,
    this.maxPrice,
    this.inStockOnly = false,
  });

  void reset() {
    sortType = SortType.relevance;
    minPrice = null;
    maxPrice = null;
    inStockOnly = false;
  }

  bool get hasActiveFilters =>
      sortType != SortType.relevance ||
      minPrice != null ||
      maxPrice != null ||
      inStockOnly;

  FilterOptions copyWith({
    SortType? sortType,
    double? minPrice,
    double? maxPrice,
    bool? inStockOnly,
  }) {
    return FilterOptions(
      sortType: sortType ?? this.sortType,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      inStockOnly: inStockOnly ?? this.inStockOnly,
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  MAIN BOTTOM SHEET ENTRY POINT
// ─────────────────────────────────────────────────────────────
class ModernFilterBottomSheet {
  static Future<FilterOptions?> show({
    required BuildContext context,
    required FilterOptions currentFilter,
    Color accentColor = const Color(0xFFFF6B35),
  }) {
    return showModalBottomSheet<FilterOptions>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // Use constrained height (e.g. 85% of screen) to look like a proper panel
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.6,
        maxChildSize: 0.95,
        builder: (_, controller) => _SplitFilterContent(
          currentFilter: currentFilter,
          accentColor: accentColor,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SPLIT VIEW CONTENT
// ─────────────────────────────────────────────────────────────
class _SplitFilterContent extends StatefulWidget {
  final FilterOptions currentFilter;
  final Color accentColor;

  const _SplitFilterContent({
    required this.currentFilter,
    required this.accentColor,
  });

  @override
  State<_SplitFilterContent> createState() => _SplitFilterContentState();
}

class _SplitFilterContentState extends State<_SplitFilterContent> {
  // Sidebar categories
  final List<String> _categories = ['Sort By', 'Price', 'Availability'];

  // Icons for sidebar
  final List<IconData> _categoryIcons = [
    Iconsax.sort,
    Iconsax.wallet_3,
    Iconsax.box_tick,
  ];

  int _selectedIndex = 0; // Which category is selected on left
  late FilterOptions _tempFilter;

  // Price controllers
  late TextEditingController _minController;
  late TextEditingController _maxController;

  @override
  void initState() {
    super.initState();
    _tempFilter = widget.currentFilter.copyWith();
    _minController = TextEditingController(
      text: _tempFilter.minPrice?.toStringAsFixed(0) ?? '',
    );
    _maxController = TextEditingController(
      text: _tempFilter.maxPrice?.toStringAsFixed(0) ?? '',
    );
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  bool _validatePriceRange() {
    final min = double.tryParse(_minController.text);
    final max = double.tryParse(_maxController.text);
    if (min != null && max != null && min > max) return false;
    return true;
  }

  void _handleApply() {
    if (!_validatePriceRange()) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Min price cannot be greater than Max price"),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    _tempFilter.minPrice = double.tryParse(_minController.text);
    _tempFilter.maxPrice = double.tryParse(_maxController.text);

    HapticFeedback.mediumImpact();
    Navigator.pop(context, _tempFilter);
  }

  void _handleClear() {
    HapticFeedback.lightImpact();
    setState(() {
      _tempFilter.reset();
      _minController.clear();
      _maxController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // 1. HEADER
          _buildHeader(),
          const Divider(height: 1),

          // 2. MIDDLE (SPLIT VIEW)
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LEFT SIDEBAR
                Container(
                  width: 110, // Fixed width sidebar
                  color: Colors.grey.shade100,
                  child: ListView.builder(
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final isSelected = _selectedIndex == index;
                      return _buildSidebarItem(index, isSelected);
                    },
                  ),
                ),

                // RIGHT CONTENT
                Expanded(
                  child: Container(
                    color: Colors.white,
                    child: _buildRightContent(),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // 3. BOTTOM ACTIONS
          _buildBottomBar(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // WIDGET BUILDERS
  // ---------------------------------------------------------------------------

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Iconsax.setting_4, color: widget.accentColor, size: 22),
              const SizedBox(width: 8),
              const Text(
                "Filters",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index, bool isSelected) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Container(
        height: 60, // Fixed height cells
        color: isSelected ? Colors.white : Colors.grey.shade100,
        child: Row(
          children: [
            // Selection Indicator Bar
            Container(
              width: 4,
              height: 60,
              color: isSelected ? widget.accentColor : Colors.transparent,
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _categoryIcons[index],
                    size: 20,
                    color: isSelected
                        ? widget.accentColor
                        : Colors.grey.shade600,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _categories[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected ? Colors.black87 : Colors.grey.shade600,
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

  Widget _buildRightContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildSortView();
      case 1:
        return _buildPriceView();
      case 2:
        return _buildAvailabilityView();
      default:
        return const SizedBox();
    }
  }

  // --- SORT VIEW (Radio List) ---
  Widget _buildSortView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          "Sort By",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildRadioOption("Relevance", SortType.relevance),
        _buildRadioOption("Price (Low to High)", SortType.priceLowToHigh),
        _buildRadioOption("Price (High to Low)", SortType.priceHighToLow),
        _buildRadioOption("Newest First", SortType.newest),
      ],
    );
  }

  Widget _buildRadioOption(String label, SortType value) {
    final isSelected = _tempFilter.sortType == value;
    return InkWell(
      onTap: () => setState(() => _tempFilter.sortType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? widget.accentColor : Colors.grey,
              size: 22,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- PRICE VIEW (Inputs + Chips) ---
  Widget _buildPriceView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          "Custom Price Range",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildPriceField("Min", _minController)),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text("to", style: TextStyle(color: Colors.grey)),
            ),
            Expanded(child: _buildPriceField("Max", _maxController)),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          "Quick Select",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildPriceChip('Under ₹500', '0', '500'),
            _buildPriceChip('₹500 - ₹1000', '500', '1000'),
            _buildPriceChip('₹1000 - ₹2000', '1000', '2000'),
            _buildPriceChip('Above ₹2000', '2000', ''),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceField(String hint, TextEditingController controller) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          prefixText: "₹ ",
          border: InputBorder.none,
          isDense: true,
        ),
        onChanged: (_) => setState(() {}), // Trigger validation UI updates
      ),
    );
  }

  Widget _buildPriceChip(String label, String min, String max) {
    bool isActive = _minController.text == min && _maxController.text == max;
    return InkWell(
      onTap: () {
        setState(() {
          _minController.text = min;
          _maxController.text = max;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? widget.accentColor.withValues(alpha: 0.1)
              : Colors.white,
          border: Border.all(
            color: isActive ? widget.accentColor : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? widget.accentColor : Colors.black87,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // --- AVAILABILITY VIEW (Checkbox) ---
  Widget _buildAvailabilityView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          "Availability",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () => setState(
            () => _tempFilter.inStockOnly = !_tempFilter.inStockOnly,
          ),
          child: Row(
            children: [
              Checkbox(
                value: _tempFilter.inStockOnly,
                activeColor: widget.accentColor,
                onChanged: (v) => setState(() => _tempFilter.inStockOnly = v!),
              ),
              const Expanded(child: Text("Include Out of Stock items")),
            ],
          ),
        ),
        // Normally e-commerce sites show "Exclude out of stock",
        // but here we toggle `inStockOnly`.
        // Let's make it clearer:
        InkWell(
          onTap: () => setState(
            () => _tempFilter.inStockOnly = !_tempFilter.inStockOnly,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(
                  _tempFilter.inStockOnly
                      ? Icons.check_box
                      : Icons.check_box_outline_blank,
                  color: _tempFilter.inStockOnly
                      ? widget.accentColor
                      : Colors.grey,
                ),
                const SizedBox(width: 12),
                const Text(
                  "Show In-Stock Only",
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- BOTTOM BAR ---
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: _handleClear,
              child: const Text(
                "Clear All",
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _handleApply,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                "Apply",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
