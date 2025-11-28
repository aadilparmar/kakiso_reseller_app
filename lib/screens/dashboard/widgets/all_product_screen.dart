import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

// CONTROLLERS
import 'package:kakiso_reseller_app/controllers/catalouge_controller.dart';

// MODELS
import 'package:kakiso_reseller_app/models/product.dart';

// WIDGETS
import 'package:kakiso_reseller_app/screens/dashboard/categories/categories_detail_page/widgets/vertical_product_card_categories.dart';
import 'package:kakiso_reseller_app/screens/dashboard/my_cart/my_cart.dart';

// SERVICES & UTILS
import 'package:kakiso_reseller_app/services/api_services.dart';
import 'package:kakiso_reseller_app/utils/constants.dart';

class AllProductsScreen extends StatefulWidget {
  final String title;
  // We pass initial sort settings to define the "type" of list (e.g., Newest, Trending)
  final String initialOrderBy;
  final String initialOrder;

  const AllProductsScreen({
    super.key,
    required this.title,
    this.initialOrderBy = 'date', // Default to Newest
    this.initialOrder = 'desc',
  });

  @override
  State<AllProductsScreen> createState() => _AllProductsScreenState();
}

class _AllProductsScreenState extends State<AllProductsScreen> {
  List<ProductModel> _products = [];
  bool _isLoading = true;

  // --- STATE VARIABLES ---
  late String _orderBy;
  late String _order;
  String _selectedSortLabel = 'Newest'; // Display text

  // Filter State
  RangeValues _currentPriceRange = const RangeValues(0, 20000);
  final double _maxFilterLimit = 20000;

  // Catalogue controller
  final CatalogueController catalogueController = Get.put(
    CatalogueController(),
    permanent: true,
  );

  @override
  void initState() {
    super.initState();
    // Initialize with constructor values
    _orderBy = widget.initialOrderBy;
    _order = widget.initialOrder;
    _determineLabel();

    _loadData();
  }

  void _determineLabel() {
    if (_orderBy == 'date') {
      _selectedSortLabel = 'Newest';
    } else if (_orderBy == 'popularity') {
      _selectedSortLabel = 'Popular';
    } else if (_orderBy == 'price' && _order == 'asc') {
      _selectedSortLabel = 'Price: Low to High';
    } else if (_orderBy == 'price' && _order == 'desc') {
      _selectedSortLabel = 'Price: High to Low';
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Use the Generic API with dynamic parameters
      final products = await ApiService.fetchProducts(
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
        Get.back();
        _loadData(); // Refresh
      },
    );
  }

  // --- 2. FILTER BOTTOM SHEET ---
  void _openFilterSheet() {
    RangeValues tempRange = _currentPriceRange;

    Get.bottomSheet(
      StatefulBuilder(
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
                        setModalState(() {
                          tempRange = const RangeValues(0, 20000);
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
                    setModalState(() => tempRange = values);
                  },
                ),

                const SizedBox(height: 24),

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
                      setState(() => _currentPriceRange = tempRange);
                      Get.back();
                      _loadData(); // Refresh
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
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.black,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.shopping_cart, color: Colors.black),
            onPressed: () => Get.to(() => const InventoryPage()),
          ),
        ],
      ),
      body: Column(
        children: [
          // --- SORT & FILTER BAR ---
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: [
                // Sort Button
                Expanded(
                  child: GestureDetector(
                    onTap: _openSortSheet,
                    child: Container(
                      color: Colors.transparent,
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
                            _selectedSortLabel,
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
                          if (_currentPriceRange.start > 0 ||
                              _currentPriceRange.end < _maxFilterLimit)
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
          const Divider(height: 1, color: Color(0xFFEEEEEE)),

          // --- PRODUCT GRID ---
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: accentColor),
                  )
                : _products.isEmpty
                ? const Center(child: Text("No products found."))
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _products.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.58,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                        ),
                    itemBuilder: (context, index) {
                      final product = _products[index];

                      return VerticalProductCard(
                        product: product,
                        availableCatalogues: catalogueController.catalogueNames,
                        onCatalogueSelected: (p, catalogueName, isNew) {
                          if (isNew) {
                            catalogueController.createCatalogueAndAddProduct(
                              catalogueName,
                              p,
                            );
                          } else {
                            catalogueController.addProductToExistingCatalogue(
                              catalogueName,
                              p,
                            );
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
