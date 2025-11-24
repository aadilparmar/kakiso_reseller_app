import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/screens/dashboard/categories/categories_detail_page/widgets/vertical_product_card_categories.dart';
import 'package:kakiso_reseller_app/services/api_services.dart';
import 'package:kakiso_reseller_app/utils/constants.dart';

class CategoryDetailsPage extends StatefulWidget {
  final int categoryId;
  final String categoryName;

  const CategoryDetailsPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<CategoryDetailsPage> createState() => _CategoryDetailsPageState();
}

class _CategoryDetailsPageState extends State<CategoryDetailsPage> {
  List<ProductModel> _products = [];
  bool _isLoading = true;

  // --- FILTER & SORT STATE ---
  String _selectedSortLabel = 'Popular'; // For Display
  String _orderBy = 'popularity'; // For API
  String _order = 'desc'; // For API

  // Price Filter Range (Default 0 to 10,000)
  RangeValues _currentPriceRange = const RangeValues(0, 10000);
  final double _maxFilterLimit = 20000;

  @override
  void initState() {
    super.initState();
    _fetchCategoryProducts();
  }

  Future<void> _fetchCategoryProducts() async {
    setState(() => _isLoading = true);
    try {
      // Pass the state variables to the API
      final products = await ApiService.fetchProductsByCategory(
        widget.categoryId,
        orderBy: _orderBy,
        order: _order,
        minPrice: _currentPriceRange.start == 0
            ? null
            : _currentPriceRange.start,
        maxPrice: _currentPriceRange.end == _maxFilterLimit
            ? null
            : _currentPriceRange.end,
      );

      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint("Error loading products: $e");
    }
  }

  // --- 1. SORT BOTTOM SHEET ---
  void _openSortSheet() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Sort By",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 16),
            _buildSortOption("Popular", "popularity", "desc"),
            _buildSortOption("Newest First", "date", "desc"),
            _buildSortOption("Price: Low to High", "price", "asc"),
            _buildSortOption("Price: High to Low", "price", "desc"),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String label, String apiOrderBy, String apiOrder) {
    final bool isSelected = _orderBy == apiOrderBy && _order == apiOrder;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? accentColor : Colors.black87,
        ),
      ),
      trailing: isSelected ? const Icon(Icons.check, color: accentColor) : null,
      onTap: () {
        setState(() {
          _selectedSortLabel = label;
          _orderBy = apiOrderBy;
          _order = apiOrder;
        });
        Get.back(); // Close sheet
        _fetchCategoryProducts(); // Reload API
      },
    );
  }

  // --- 2. FILTER BOTTOM SHEET ---
  void _openFilterSheet() {
    // Temp variable to hold change before applying
    RangeValues tempRange = _currentPriceRange;

    Get.bottomSheet(
      StatefulBuilder(
        // Needed to update slider inside bottom sheet
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Filter",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // Reset Logic
                        setModalState(() {
                          tempRange = const RangeValues(0, 10000);
                        });
                      },
                      child: const Text(
                        "Reset",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                const Text(
                  "Price Range",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 10),

                // Price Labels
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "₹${tempRange.start.toInt()}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "₹${tempRange.end.toInt()}+",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),

                // Slider
                RangeSlider(
                  values: tempRange,
                  min: 0,
                  max: _maxFilterLimit,
                  divisions: 20,
                  activeColor: accentColor,
                  inactiveColor: accentColor.withOpacity(0.2),
                  labels: RangeLabels(
                    "₹${tempRange.start.toInt()}",
                    "₹${tempRange.end.toInt()}",
                  ),
                  onChanged: (values) {
                    setModalState(() {
                      tempRange = values;
                    });
                  },
                ),

                const SizedBox(height: 24),

                // Apply Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _currentPriceRange = tempRange;
                      });
                      Get.back();
                      _fetchCategoryProducts();
                    },
                    child: const Text(
                      "Apply Filter",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // Light grey background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: Text(
          widget.categoryName,
          style: const TextStyle(
            color: Colors.black,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        // Removed Actions (Search/Cart) as requested
      ),
      body: Column(
        children: [
          // --- 1. SORT & FILTER BAR ---
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: [
                // Sort Dropdown
                Expanded(
                  child: GestureDetector(
                    onTap: _openSortSheet,
                    child: Container(
                      color: Colors.transparent, // Hit test area
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Iconsax.sort,
                            size: 18,
                            color: Colors.black87,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _selectedSortLabel, // Dynamic Label
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.keyboard_arrow_down,
                            size: 16,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Divider
                Container(height: 20, width: 1, color: Colors.grey.shade300),

                // Filter Button
                Expanded(
                  child: GestureDetector(
                    onTap: _openFilterSheet,
                    child: Container(
                      color: Colors.transparent,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Iconsax.filter,
                            size: 18,
                            color: Colors.black87,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "Filter",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                              color: Colors.black87,
                            ),
                          ),
                          // Show dot if filter is active
                          if (_currentPriceRange.start > 0 ||
                              _currentPriceRange.end < 20000)
                            Container(
                              margin: const EdgeInsets.only(left: 6),
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: accentColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)), // Clean separator
          // --- 2. PRODUCT GRID ---
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: accentColor),
                  )
                : _products.isEmpty
                ? _buildEmptyState()
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _products.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.58, // Tweaked for vertical card
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                        ),
                    itemBuilder: (context, index) {
                      final product = _products[index];
                      return VerticalProductCard(product: product);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.box_remove, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            "No products found.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              // Reset filters logic
              setState(() {
                _currentPriceRange = const RangeValues(0, 20000);
                _orderBy = 'popularity';
                _selectedSortLabel = 'Popular';
              });
              _fetchCategoryProducts();
            },
            child: const Text(
              "Clear Filters",
              style: TextStyle(color: accentColor),
            ),
          ),
        ],
      ),
    );
  }
}
