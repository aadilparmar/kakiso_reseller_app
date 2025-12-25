// lib/screens/dashboard/categories/categories_detail_page/category_details_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import 'package:kakiso_reseller_app/controllers/catalouge_controller.dart';
import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/screens/dashboard/categories/categories_detail_page/widgets/vertical_product_card_categories.dart';
import 'package:kakiso_reseller_app/screens/dashboard/filter/filter.dart';
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
  FilterOptions _activeFilter = FilterOptions();

  // Catalogue controller
  final catalogueController = Get.put(CatalogueController(), permanent: true);

  // // Price Filter Range (Default 0 to 10,000)
  RangeValues _currentPriceRange = const RangeValues(0, 10000);
  final double _maxFilterLimit = 20000;

  // Selected product IDs for checkbox state in cards (bulk)
  final Set<int> _selectedProductIds = {};

  @override
  void initState() {
    super.initState();
    _fetchCategoryProducts();
  }

  Future<void> _fetchCategoryProducts() async {
    setState(() => _isLoading = true);
    try {
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

          // Clear selections that are not present anymore
          _selectedProductIds.removeWhere(
            (id) => !_products.any((p) => p.id == id),
          );
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint("Error loading products: $e");
    }
  }

  void _applySortFromFilter() {
    switch (_activeFilter.sortType) {
      case SortType.priceLowToHigh:
        _orderBy = 'price';
        _order = 'asc';
        break;

      case SortType.priceHighToLow:
        _orderBy = 'price';
        _order = 'desc';
        break;

      case SortType.newest:
        _orderBy = 'date';
        _order = 'desc';
        break;

      case SortType.relevance:
        _orderBy = 'popularity';
        _order = 'desc';
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
  Future<void> _openModernFilter() async {
    final result = await ModernFilterBottomSheet.show(
      context: context,
      currentFilter: _activeFilter,
      accentColor: accentColor,
    );

    if (!mounted || result == null) return;

    setState(() {
      _activeFilter = result;
      _applySortFromFilter();
    });

    _fetchCategoryProducts();
  }

  // --- 3. BULK ADD TO CATALOGUE SHEET ---
  void _openBulkAddToCatalogueSheet() {
    if (_selectedProductIds.isEmpty) return;

    final selectedProducts = _products
        .where((p) => _selectedProductIds.contains(p.id))
        .toList(growable: false);

    final availableCatalogues = catalogueController.catalogueNames;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Add ${selectedProducts.length} products to catalog',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 16),

              if (availableCatalogues.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Iconsax.folder_open,
                        size: 30,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "No catalogs found",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Create a new catalog to start saving products.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...availableCatalogues.map(
                  (name) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Iconsax.book,
                          color: accentColor,
                          size: 18,
                        ),
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                          fontSize: 14,
                        ),
                      ),
                      subtitle: const Text(
                        "Tap to add selected products",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      trailing: const Icon(
                        Iconsax.arrow_right_3,
                        size: 16,
                        color: Colors.grey,
                      ),
                      onTap: () {
                        // Existing catalogue: just forward all selected products
                        for (final p in selectedProducts) {
                          catalogueController.addProductToExistingCatalogue(
                            name,
                            p,
                          );
                        }

                        Navigator.pop(ctx);

                        Get.snackbar(
                          'Added to catalog',
                          '${selectedProducts.length} products added to "$name".',
                          snackPosition: SnackPosition.BOTTOM,
                        );

                        setState(() {
                          _selectedProductIds.clear();
                        });
                      },
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showCreateNewCatalogueDialogForBulk(selectedProducts);
                  },
                  icon: const Icon(Iconsax.add_circle, size: 20),
                  label: const Text('Create New Catalog'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- 4. CREATE NEW CATALOGUE DIALOG (BULK) ---
  void _showCreateNewCatalogueDialogForBulk(List<ProductModel> products) {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'New Catalog',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
            ),
          ),
          content: TextField(
            controller: nameController,
            autofocus: true,
            style: const TextStyle(fontFamily: 'Poppins'),
            decoration: InputDecoration(
              labelText: 'Catalog Name',
              hintText: 'e.g. Diwali Collection',
              filled: true,
              fillColor: const Color.fromARGB(185, 250, 250, 250),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(color: accentColor),
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              style: TextButton.styleFrom(foregroundColor: Colors.grey),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isNotEmpty && products.isNotEmpty) {
                  // 1) Create catalogue with first product
                  final first = products.first;
                  catalogueController.createCatalogueAndAddProduct(name, first);

                  // 2) Add remaining products to this new catalogue
                  for (final p in products.skip(1)) {
                    catalogueController.addProductToExistingCatalogue(name, p);
                  }

                  Navigator.pop(ctx);

                  Get.snackbar(
                    'Catalog created',
                    '${products.length} products added to "$name".',
                    snackPosition: SnackPosition.BOTTOM,
                  );

                  setState(() {
                    _selectedProductIds.clear();
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasSelection = _selectedProductIds.isNotEmpty;
    final int selectedCount = _selectedProductIds.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
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
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // --- 1. SORT & FILTER BAR ---
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                child: Row(
                  children: [
                    // Sort
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

                    Container(
                      height: 20,
                      width: 1,
                      color: Colors.grey.shade300,
                    ),

                    // Filter
                    Expanded(
                      child: GestureDetector(
                        onTap: _openModernFilter,
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
              const Divider(height: 1, color: Color(0xFFEEEEEE)),

              // --- 2. PRODUCT GRID ---
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: accentColor),
                      )
                    : _products.isEmpty
                    ? _buildEmptyState()
                    : GridView.builder(
                        padding: const EdgeInsets.all(10),
                        itemCount: _products.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.58,
                              mainAxisSpacing: 3,
                              crossAxisSpacing: 3,
                            ),
                        itemBuilder: (context, index) {
                          final product = _products[index];

                          return VerticalProductCard(
                            product: product,
                            availableCatalogues:
                                catalogueController.catalogueNames,
                            isSelected: _selectedProductIds.contains(
                              product.id,
                            ),
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
                                catalogueController
                                    .createCatalogueAndAddProduct(
                                      catalogueName,
                                      product,
                                    );
                              } else {
                                catalogueController
                                    .addProductToExistingCatalogue(
                                      catalogueName,
                                      product,
                                    );
                              }

                              Get.snackbar(
                                'Added to catalog',
                                '"${product.name}" added to "$catalogueName".',
                                snackPosition: SnackPosition.BOTTOM,
                              );
                            },
                          );
                        },
                      ),
              ),

              if (hasSelection) const SizedBox(height: 70),
            ],
          ),

          // --- 3. STICKY BULK BAR ---
          if (hasSelection)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Icon(
                        Iconsax.tick_circle,
                        color: accentColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '$selectedCount products selected',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _openBulkAddToCatalogueSheet,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: const Text(
                        'Add to Catalog',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
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
