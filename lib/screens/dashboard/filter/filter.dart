import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';

// 🔹 Imports
import 'package:kakiso_reseller_app/models/categories.dart';
import 'package:kakiso_reseller_app/services/api_services.dart';

// ─────────────────────────────────────────────────────────────
//  FILTER MODEL
// ─────────────────────────────────────────────────────────────
enum SortType { relevance, priceLowToHigh, priceHighToLow, newest }

class FilterOptions {
  SortType sortType;
  double? minPrice;
  double? maxPrice;
  bool inStockOnly;
  List<int> selectedCategoryIds;

  FilterOptions({
    this.sortType = SortType.relevance,
    this.minPrice,
    this.maxPrice,
    this.inStockOnly = false,
    this.selectedCategoryIds = const [],
  });

  void reset() {
    sortType = SortType.relevance;
    minPrice = null;
    maxPrice = null;
    inStockOnly = false;
    selectedCategoryIds = [];
  }

  bool get hasActiveFilters =>
      sortType != SortType.relevance ||
      minPrice != null ||
      maxPrice != null ||
      inStockOnly ||
      selectedCategoryIds.isNotEmpty;

  FilterOptions copyWith({
    SortType? sortType,
    double? minPrice,
    double? maxPrice,
    bool? inStockOnly,
    List<int>? selectedCategoryIds,
  }) {
    return FilterOptions(
      sortType: sortType ?? this.sortType,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      inStockOnly: inStockOnly ?? this.inStockOnly,
      selectedCategoryIds:
          selectedCategoryIds ?? List.from(this.selectedCategoryIds),
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
  // 🔹 Sidebar categories
  final List<String> _tabs = ['Category', 'Price', 'Availability'];
  final List<IconData> _tabIcons = [
    Iconsax.category,
    Iconsax.wallet_3,
    Iconsax.box_tick,
  ];

  int _selectedIndex = 0;
  late FilterOptions _tempFilter;

  // 🔹 Self-Fetching State
  List<CategoryModel> _allCategories = [];
  bool _isLoadingCategories = true;
  String _errorMessage = '';

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

    _fetchCategoriesInternal();
  }

  Future<void> _fetchCategoriesInternal() async {
    setState(() {
      _isLoadingCategories = true;
      _errorMessage = '';
    });

    try {
      final cats = await ApiService.fetchCategories();
      // 🔹 Build Hierarchy Tree
      final tree = CategoryModel.buildTree(cats);

      if (mounted) {
        setState(() {
          _allCategories = tree;
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
          _errorMessage = "Failed to load categories";
        });
      }
    }
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

  void _toggleCategorySelection(int categoryId, bool? isSelected) {
    setState(() {
      if (isSelected == true) {
        if (!_tempFilter.selectedCategoryIds.contains(categoryId)) {
          _tempFilter.selectedCategoryIds.add(categoryId);
        }
      } else {
        _tempFilter.selectedCategoryIds.remove(categoryId);
      }
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
          _buildHeader(),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LEFT SIDEBAR
                Container(
                  width: 100,
                  color: const Color(0xFFF9F9F9),
                  child: ListView.builder(
                    itemCount: _tabs.length,
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
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Iconsax.filter, color: widget.accentColor, size: 22),
              const SizedBox(width: 8),
              const Text(
                "Filter",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, color: Colors.grey),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 70,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFFF9F9F9),
          border: isSelected
              ? Border(left: BorderSide(width: 4, color: widget.accentColor))
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _tabIcons[index],
              size: 22,
              color: isSelected ? widget.accentColor : Colors.grey.shade500,
            ),
            const SizedBox(height: 6),
            Text(
              _tabs[index],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.black87 : Colors.grey.shade600,
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
        return _buildCategoryView();
      case 1:
        return _buildPriceView();
      case 2:
        return _buildAvailabilityView();
      default:
        return const SizedBox();
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  🎨 IMPROVED UI: HIERARCHICAL CATEGORY VIEW
  // ─────────────────────────────────────────────────────────────
  Widget _buildCategoryView() {
    if (_isLoadingCategories) {
      return Center(
        child: CircularProgressIndicator(
          color: widget.accentColor,
          strokeWidth: 2,
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(height: 8),
            Text(_errorMessage, style: const TextStyle(color: Colors.grey)),
            TextButton(
              onPressed: _fetchCategoriesInternal,
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    }

    if (_allCategories.isEmpty) {
      return const Center(
        child: Text(
          "No categories found",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      children: [
        Text(
          "Select Categories",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 12),
        // Render root categories
        ..._allCategories.map((category) => _buildCategoryTree(category)),
      ],
    );
  }

  Widget _buildCategoryTree(CategoryModel category, {int depth = 0}) {
    final bool isSelected = _tempFilter.selectedCategoryIds.contains(
      category.id,
    );
    final bool hasChildren = category.children.isNotEmpty;

    // Indentation calculation
    final double indent = depth * 16.0;

    // 🔹 CASE 1: PARENT NODE (Has Children)
    if (hasChildren) {
      return Padding(
        padding: EdgeInsets.only(left: indent, bottom: 8),
        child: Theme(
          // Remove default borders from ExpansionTile
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: Container(
            decoration: BoxDecoration(
              color: depth == 0 ? Colors.grey.shade50 : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: depth == 0
                  ? Border.all(color: Colors.grey.shade200)
                  : const Border(
                      left: BorderSide(color: Color(0xFFEEEEEE), width: 2),
                    ),
            ),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 8),
              childrenPadding: EdgeInsets.zero,
              // Custom Leading Checkbox
              leading: Transform.scale(
                scale: 1.1,
                child: Checkbox(
                  activeColor: widget.accentColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  value: isSelected,
                  onChanged: (val) =>
                      _toggleCategorySelection(category.id, val),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              title: Text(
                category.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? widget.accentColor : Colors.black87,
                ),
              ),
              // Recursively render children
              children: category.children.map((child) {
                return _buildCategoryTree(child, depth: depth + 1);
              }).toList(),
            ),
          ),
        ),
      );
    }

    // 🔹 CASE 2: LEAF NODE (No Children)
    return Padding(
      padding: EdgeInsets.only(left: indent, bottom: 4),
      child: InkWell(
        onTap: () => _toggleCategorySelection(category.id, !isSelected),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            // Visual Connector for nested items
            border: depth > 0
                ? const Border(
                    left: BorderSide(color: Color(0xFFEEEEEE), width: 2),
                  )
                : null,
          ),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Row(
            children: [
              if (depth > 0)
                const SizedBox(width: 8), // Extra spacing for connector
              Transform.scale(
                scale: 1.0,
                child: Checkbox(
                  activeColor: widget.accentColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  value: isSelected,
                  onChanged: (val) =>
                      _toggleCategorySelection(category.id, val),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  category.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected
                        ? FontWeight.w500
                        : FontWeight.normal,
                    color: isSelected ? Colors.black87 : Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  SORT VIEW
  // ─────────────────────────────────────────────────────────────

  // ─────────────────────────────────────────────────────────────
  //  PRICE VIEW
  // ─────────────────────────────────────────────────────────────
  Widget _buildPriceView() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          "Price Range",
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _buildPriceField("Min", _minController)),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Icon(Icons.arrow_right_alt, color: Colors.grey),
            ),
            Expanded(child: _buildPriceField("Max", _maxController)),
          ],
        ),
        const SizedBox(height: 30),
        const Text(
          "Quick Select",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hint.toUpperCase(),
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
        const SizedBox(height: 6),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            decoration: const InputDecoration(
              prefixText: "₹ ",
              border: InputBorder.none,
              isDense: true,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
      ],
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
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? widget.accentColor : Colors.white,
          border: Border.all(
            color: isActive ? widget.accentColor : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: widget.accentColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isActive ? Colors.white : Colors.black87,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  AVAILABILITY VIEW
  // ─────────────────────────────────────────────────────────────
  Widget _buildAvailabilityView() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          "Availability",
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: CheckboxListTile(
            value: _tempFilter.inStockOnly,
            activeColor: widget.accentColor,
            title: const Text("Include Out of Stock items"),
            subtitle: const Text(
              "Show items that are currently unavailable",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            onChanged: (v) => setState(() => _tempFilter.inStockOnly = v!),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  BOTTOM BAR
  // ─────────────────────────────────────────────────────────────
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            offset: const Offset(0, -4),
            blurRadius: 16,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: TextButton(
              onPressed: _handleClear,
              child: const Text(
                "Reset",
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _handleApply,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                shadowColor: widget.accentColor.withOpacity(0.4),
              ),
              child: const Text(
                "Apply Filters",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
