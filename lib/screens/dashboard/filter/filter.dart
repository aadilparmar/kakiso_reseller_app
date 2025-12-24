import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';

// Filter Model
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

// Main Filter Bottom Sheet Class
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
      builder: (ctx) => _FilterBottomSheetContent(
        currentFilter: currentFilter,
        accentColor: accentColor,
      ),
    );
  }
}

// Internal Content Widget
class _FilterBottomSheetContent extends StatefulWidget {
  final FilterOptions currentFilter;
  final Color accentColor;

  const _FilterBottomSheetContent({
    required this.currentFilter,
    required this.accentColor,
  });

  @override
  State<_FilterBottomSheetContent> createState() =>
      _FilterBottomSheetContentState();
}

class _FilterBottomSheetContentState extends State<_FilterBottomSheetContent> {
  late FilterOptions _tempFilter;
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
    return min == null || max == null || min <= max;
  }

  void _handleApply() {
    if (!_validatePriceRange()) {
      HapticFeedback.heavyImpact();
      return;
    }

    _tempFilter.minPrice = double.tryParse(_minController.text);
    _tempFilter.maxPrice = double.tryParse(_maxController.text);

    HapticFeedback.mediumImpact();
    Navigator.pop(context, _tempFilter);
  }

  void _handleClear() {
    HapticFeedback.lightImpact();
    _tempFilter.reset();
    Navigator.pop(context, _tempFilter);
  }

  @override
  Widget build(BuildContext context) {
    final hasError = !_validatePriceRange();

    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: () {}, // Prevent closing when tapping inside
          child: Container(
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 20,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle Bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              widget.accentColor.withOpacity(0.15),
                              widget.accentColor.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Iconsax.filter,
                          color: widget.accentColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Filters & Sort',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _tempFilter.reset();
                            _minController.clear();
                            _maxController.clear();
                          });
                          HapticFeedback.lightImpact();
                        },
                        icon: Icon(
                          Iconsax.refresh,
                          color: Colors.grey.shade600,
                        ),
                        tooltip: 'Reset all',
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sort By Section
                        _buildSectionHeader('Sort By', Iconsax.sort),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _buildSortChip(
                              'Relevance',
                              SortType.relevance,
                              Iconsax.star,
                            ),
                            _buildSortChip(
                              'Price: Low → High',
                              SortType.priceLowToHigh,
                              Iconsax.arrow_up_3,
                            ),
                            _buildSortChip(
                              'Price: High → Low',
                              SortType.priceHighToLow,
                              Iconsax.arrow_down_2,
                            ),
                            _buildSortChip(
                              'Newest First',
                              SortType.newest,
                              Iconsax.clock,
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Price Range Section
                        _buildSectionHeader('Price Range', Iconsax.wallet_3),
                        const SizedBox(height: 16),
                        _buildPriceInputs(hasError),

                        if (hasError) ...[
                          const SizedBox(height: 12),
                          _buildErrorMessage(),
                        ],

                        const SizedBox(height: 24),

                        // Quick Filters
                        const Text(
                          'Quick Filters',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildQuickFilter('Under ₹500', () {
                                _minController.text = '0';
                                _maxController.text = '500';
                              }),
                              const SizedBox(width: 8),
                              _buildQuickFilter('₹500 - ₹1000', () {
                                _minController.text = '500';
                                _maxController.text = '1000';
                              }),
                              const SizedBox(width: 8),
                              _buildQuickFilter('₹1000 - ₹5000', () {
                                _minController.text = '1000';
                                _maxController.text = '5000';
                              }),
                              const SizedBox(width: 8),
                              _buildQuickFilter('Above ₹5000', () {
                                _minController.text = '5000';
                                _maxController.clear();
                              }),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Availability Toggle
                        _buildAvailabilityToggle(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // Action Buttons
                _buildActionButtons(hasError),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade700),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  Widget _buildSortChip(String label, SortType type, IconData icon) {
    final bool isSelected = _tempFilter.sortType == type;

    return InkWell(
      onTap: () {
        setState(() => _tempFilter.sortType = type);
        HapticFeedback.selectionClick();
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? widget.accentColor : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? widget.accentColor : Colors.grey.shade200,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: widget.accentColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceInputs(bool hasError) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasError ? Colors.red.shade300 : Colors.grey.shade200,
                width: 1.5,
              ),
            ),
            child: TextField(
              controller: _minController,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Min',
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 8),
                  child: Text(
                    '₹',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 0,
                  minHeight: 0,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Container(width: 24, height: 2, color: Colors.grey.shade300),
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasError ? Colors.red.shade300 : Colors.grey.shade200,
                width: 1.5,
              ),
            ),
            child: TextField(
              controller: _maxController,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Max',
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 8),
                  child: Text(
                    '₹',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 0,
                  minHeight: 0,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Iconsax.info_circle, color: Colors.red.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Min price cannot exceed max price',
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilter(String label, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        setState(() => onTap());
        HapticFeedback.lightImpact();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildAvailabilityToggle() {
    return Container(
      decoration: BoxDecoration(
        color: _tempFilter.inStockOnly
            ? widget.accentColor.withOpacity(0.08)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _tempFilter.inStockOnly
              ? widget.accentColor.withOpacity(0.3)
              : Colors.grey.shade200,
          width: 1.5,
        ),
      ),
      child: SwitchListTile(
        value: _tempFilter.inStockOnly,
        onChanged: (v) {
          setState(() => _tempFilter.inStockOnly = v);
          HapticFeedback.selectionClick();
        },
        activeColor: widget.accentColor,
        title: Row(
          children: [
            Icon(
              Iconsax.box_tick,
              size: 20,
              color: _tempFilter.inStockOnly
                  ? widget.accentColor
                  : Colors.grey.shade600,
            ),
            const SizedBox(width: 12),
            const Text(
              'In Stock Only',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(left: 32),
          child: Text(
            'Show only available products',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(bool hasError) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _handleClear,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Iconsax.close_circle,
                    size: 18,
                    color: Colors.grey.shade700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Clear',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: hasError ? null : _handleApply,
              style: ElevatedButton.styleFrom(
                backgroundColor: hasError
                    ? Colors.grey.shade300
                    : widget.accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.tick_circle, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Apply Filters',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
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
