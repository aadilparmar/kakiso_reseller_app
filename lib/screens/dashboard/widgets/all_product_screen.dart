// lib/screens/dashboard/widgets/all_product_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

// CONTROLLERS
import 'package:kakiso_reseller_app/controllers/catalouge_controller.dart';

// MODELS
import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/models/categories.dart';

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

  // --- CATEGORY FILTER STATE ---
  int? _selectedCategoryId;
  String? _selectedCategoryName;

  // Catalogue controller
  final CatalogueController catalogueController = Get.put(
    CatalogueController(),
    permanent: true,
  );

  // Bulk selection
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
      List<ProductModel> products;

      // If a category is selected, load products for that category only
      if (_selectedCategoryId != null) {
        products = await ApiService.fetchProductsByCategory(
          _selectedCategoryId!,
          orderBy: _orderBy,
          order: _order,
          minPrice: _currentPriceRange.start == 0
              ? null
              : _currentPriceRange.start,
          maxPrice: _currentPriceRange.end == _maxFilterLimit
              ? null
              : _currentPriceRange.end,
        );
      } else {
        // Otherwise global product listing
        products = await ApiService.fetchProducts(
          orderBy: _orderBy,
          order: _order,
          minPrice: _currentPriceRange.start == 0
              ? null
              : _currentPriceRange.start,
          maxPrice: _currentPriceRange.end == _maxFilterLimit
              ? null
              : _currentPriceRange.end,
        );
      }

      if (!mounted) return;

      setState(() {
        _products = products;
        _isLoading = false;

        // Clean selection for products not in current list
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

  // --- CATEGORY SHEET ---
  void _openCategorySheet() {
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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: FutureBuilder<List<CategoryModel>>(
            future: ApiService.fetchCategories(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SizedBox(
                  height: 220,
                  child: Center(
                    child: CircularProgressIndicator(color: accentColor),
                  ),
                );
              }

              if (snapshot.hasError) {
                return SizedBox(
                  height: 220,
                  child: Center(
                    child: Text(
                      'Failed to load categories',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.red.shade400,
                      ),
                    ),
                  ),
                );
              }

              final categories = snapshot.data ?? [];

              return Column(
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
                  const Text(
                    'Filter by Category',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 12),

                  // All Products (no category)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.grey.shade100,
                      child: const Icon(
                        Iconsax.global,
                        size: 16,
                        color: Colors.black87,
                      ),
                    ),
                    title: const Text(
                      'All Products',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: _selectedCategoryId == null
                        ? const Icon(Icons.check, color: accentColor, size: 18)
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedCategoryId = null;
                        _selectedCategoryName = null;
                      });
                      Navigator.pop(ctx);
                      _loadData();
                    },
                  ),

                  const Divider(height: 16),

                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: categories.length,
                      itemBuilder: (_, index) {
                        final category = categories[index];
                        final isSelected = _selectedCategoryId == category.id;

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.grey.shade100,
                            child: const Icon(
                              Iconsax.category,
                              size: 16,
                              color: Colors.black87,
                            ),
                          ),
                          title: Text(
                            category.name,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check,
                                  color: accentColor,
                                  size: 18,
                                )
                              : null,
                          onTap: () {
                            setState(() {
                              _selectedCategoryId = category.id;
                              _selectedCategoryName = category.name;
                            });
                            Navigator.pop(ctx);
                            _loadData();
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        );
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
                        setModalState(
                          () => tempRange = const RangeValues(0, 20000),
                        );
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
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      fontFamily: 'Poppins',
                    ),
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
                      fontFamily: 'Poppins',
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

  // --- BULK ADD TO CATALOGUE SHEET ---
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
                          color: accentColor.withOpacity(0.08),
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

  // --- CREATE NEW CATALOGUE DIALOG (BULK) ---
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
              hintText: 'e.g. Festive Collection',
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
                  // 1) Create new catalogue with first product
                  final first = products.first;
                  catalogueController.createCatalogueAndAddProduct(name, first);

                  // 2) Add remaining products to that new catalogue
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
    final hasSelection = _selectedProductIds.isNotEmpty;
    final selectedCount = _selectedProductIds.length;

    // Label for category chip
    final String categoryLabel =
        _selectedCategoryName ?? 'Categories'; // default label

    final bool categoryActive = _selectedCategoryId != null;

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
      body: Stack(
        children: [
          Column(
            children: [
              // SORT / CATEGORY / FILTER BAR
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
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

                    Container(
                      height: 20,
                      width: 1,
                      color: Colors.grey.shade300,
                    ),

                    // CATEGORY
                    Expanded(
                      child: GestureDetector(
                        onTap: _openCategorySheet,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Iconsax.category, size: 18),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                categoryLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (categoryActive)
                              Container(
                                margin: const EdgeInsets.only(left: 4),
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

                    Container(
                      height: 20,
                      width: 1,
                      color: Colors.grey.shade300,
                    ),

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
                            availableCatalogues:
                                catalogueController.catalogueNames,

                            // selection state for highlight
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

                            // SINGLE PRODUCT CATALOGUE LOGIC
                            onCatalogueSelected:
                                (
                                  ProductModel product,
                                  String catalogueName,
                                  bool isNewCatalogue,
                                ) {
                                  if (isNewCatalogue) {
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

          // STICKY BULK BAR
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
                      color: Colors.black.withOpacity(0.06),
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
                        color: accentColor.withOpacity(0.1),
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
}
