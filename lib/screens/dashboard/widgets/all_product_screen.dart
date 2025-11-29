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
  final String initialOrderBy;
  final String initialOrder;

  const AllProductsScreen({
    super.key,
    required this.title,
    this.initialOrderBy = 'date',
    this.initialOrder = 'desc',
  });

  @override
  State<AllProductsScreen> createState() => _AllProductsScreenState();
}

class _AllProductsScreenState extends State<AllProductsScreen> {
  List<ProductModel> _products = [];
  bool _isLoading = true;

  // --- SORT STATE ---
  late String _orderBy;
  late String _order;
  String _selectedSortLabel = 'Newest';

  // --- FILTER RANGE ---
  RangeValues _currentPriceRange = const RangeValues(0, 20000);
  final double _maxFilterLimit = 20000;

  // Catalogue controller
  final CatalogueController catalogueController = Get.put(
    CatalogueController(),
    permanent: true,
  );

  // NEW: required for updated VerticalProductCard
  final Set<int> _selectedProductIds = {};

  @override
  void initState() {
    super.initState();
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

      if (!mounted) return;

      setState(() {
        _products = products;
        _isLoading = false;

        // Remove selections of items that are not in this list anymore
        _selectedProductIds.removeWhere(
          (id) => !_products.any((p) => p.id == id),
        );
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- SORT SHEET ---
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
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String label, String by, String order) {
    final isSelected = _orderBy == by && _order == order;

    return ListTile(
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          fontFamily: 'Poppins',
          color: isSelected ? accentColor : Colors.black87,
        ),
      ),
      trailing: isSelected ? const Icon(Icons.check, color: accentColor) : null,
      onTap: () {
        setState(() {
          _selectedSortLabel = label;
          _orderBy = by;
          _order = order;
        });
        Get.back();
        _loadData();
      },
    );
  }

  // --- FILTER SHEET ---
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
                const SizedBox(height: 20),

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Price Range",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 8),

                RangeSlider(
                  values: tempRange,
                  min: 0,
                  max: _maxFilterLimit,
                  activeColor: accentColor,
                  labels: RangeLabels(
                    "₹${tempRange.start.toInt()}",
                    "₹${tempRange.end.toInt()}",
                  ),
                  onChanged: (values) {
                    setModalState(() => tempRange = values);
                  },
                ),

                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _currentPriceRange = tempRange;
                    });
                    Get.back();
                    _loadData();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Apply Filter",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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

  // --- UI ---
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
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: Colors.black,
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
          // SORT & FILTER BAR
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: [
                // SORT
                Expanded(
                  child: GestureDetector(
                    onTap: _openSortSheet,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Iconsax.sort, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          _selectedSortLabel,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_down, size: 16),
                      ],
                    ),
                  ),
                ),

                Container(height: 20, width: 1, color: Colors.grey.shade300),

                // FILTER
                Expanded(
                  child: GestureDetector(
                    onTap: _openFilterSheet,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Iconsax.filter, size: 18),
                        const SizedBox(width: 6),
                        const Text(
                          "Filter",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
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
              ],
            ),
          ),
          const Divider(height: 1),

          // PRODUCT GRID
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: accentColor),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(14),
                    itemCount: _products.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.58,
                        ),
                    itemBuilder: (_, i) {
                      final product = _products[i];

                      return VerticalProductCard(
                        product: product,
                        availableCatalogues: catalogueController.catalogueNames,

                        // NEW REQUIRED PARAMETER
                        isSelected: _selectedProductIds.contains(product.id),

                        // NEW CALLBACK
                        onSelectionToggle: () {
                          setState(() {
                            if (_selectedProductIds.contains(product.id)) {
                              _selectedProductIds.remove(product.id);
                            } else {
                              _selectedProductIds.add(product.id);
                            }
                          });
                        },

                        onCatalogueSelected: (product, catalogueName, isNew) {
                          if (isNew) {
                            catalogueController.createCatalogueAndAddProduct(
                              catalogueName,
                              product,
                            );
                          } else {
                            catalogueController.addProductToExistingCatalogue(
                              catalogueName,
                              product,
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
