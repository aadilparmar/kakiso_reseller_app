// lib/screens/dashboard/widgets/all_product_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import 'package:kakiso_reseller_app/controllers/catalouge_controller.dart';
import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/screens/dashboard/categories/categories_detail_page/widgets/vertical_product_card_categories.dart';
import 'package:kakiso_reseller_app/screens/dashboard/filter/filter.dart';
import 'package:kakiso_reseller_app/screens/dashboard/my_cart/my_cart.dart';
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

  late String _orderBy;
  late String _order;
  String _selectedSortLabel = 'Newest';

  FilterOptions _activeFilter = FilterOptions();

  int? _selectedCategoryId;

  final CatalogueController catalogueController = Get.put(
    CatalogueController(),
    permanent: true,
  );

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
      int? effectiveCatId = _selectedCategoryId;

      // 1. Determine Category for API
      if (_activeFilter.selectedCategoryIds.isNotEmpty) {
        effectiveCatId = _activeFilter.selectedCategoryIds.first;
      }

      // 2. Fetch from API
      if (effectiveCatId != null) {
        products = await ApiService().fetchProductsByCategory(
          effectiveCatId,
          orderBy: _orderBy,
          order: _order,
          minPrice: _activeFilter.minPrice,
          maxPrice: _activeFilter.maxPrice,
          brandIds: _activeFilter.selectedBrandIds, // <--- ADD THIS
        );
      } else {
        products = await ApiService().fetchProducts(
          orderBy: _orderBy,
          order: _order,
          minPrice: _activeFilter.minPrice,
          maxPrice: _activeFilter.maxPrice,
          brandIds: _activeFilter.selectedBrandIds, // <--- ADD THIS
        );
      }

      // 3. Client-Side Filtering (Fallback & Logic Enforcement)
      if (mounted) {
        // Filter: In Stock Only
        if (_activeFilter.inStockOnly) {
          // Assuming product has a property like stock or isAvailable.
          // If not available on model, this check ensures safety.
          // Adjust logic based on actual ProductModel fields.
          // Example: products = products.where((p) => p.stock > 0).toList();
        }

        // Filter: Strict Price Check (Double check API response)
        if (_activeFilter.minPrice != null) {
          products = products
              .where(
                (p) => double.parse(p.price) >= (_activeFilter.minPrice ?? 0),
              )
              .toList();
        }
        if (_activeFilter.maxPrice != null) {
          products = products
              .where(
                (p) =>
                    double.parse(p.price) <=
                    (_activeFilter.maxPrice ?? double.infinity),
              )
              .toList();
        }

        setState(() {
          _products = products;
          _isLoading = false;
          _selectedProductIds.removeWhere(
            (id) => !_products.any((p) => p.id == id),
          );
        });
      }
    } catch (e) {
      debugPrint("Error loading data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openSortSheet() {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
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
        ),
      ),
      isScrollControlled: true,
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

  Future<void> _openModernFilter() async {
    final result = await ModernFilterBottomSheet.show(
      context: context,
      currentFilter: _activeFilter,
      accentColor: accentColor,
    );

    if (!mounted) return;

    if (result != null) {
      setState(() {
        _activeFilter = result;
        _applySortFromFilter();

        if (_activeFilter.selectedCategoryIds.isNotEmpty) {
          _selectedCategoryId = _activeFilter.selectedCategoryIds.first;
        } else {
          _selectedCategoryId = null;
        }
      });
      _loadData();
    }
  }

  void _applySortFromFilter() {
    switch (_activeFilter.sortType) {
      case SortType.priceLowToHigh:
        _orderBy = 'price';
        _order = 'asc';
        _selectedSortLabel = 'Price: Low to High';
        break;
      case SortType.priceHighToLow:
        _orderBy = 'price';
        _order = 'desc';
        _selectedSortLabel = 'Price: High to Low';
        break;
      case SortType.newest:
        _orderBy = 'date';
        _order = 'desc';
        _selectedSortLabel = 'Newest';
        break;
      case SortType.relevance:
        _orderBy = widget.initialOrderBy;
        _order = widget.initialOrder;
        _selectedSortLabel = 'Relevance';
        break;
    }
  }

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
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: availableCatalogues.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, index) {
                          final name = availableCatalogues[index];
                          return Container(
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
                                for (final p in selectedProducts) {
                                  catalogueController
                                      .addProductToExistingCatalogue(name, p);
                                  VerticalProductCard.sessionAddedToCatalog[p
                                          .id] =
                                      name;
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
                          );
                        },
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
            ),
          ),
        );
      },
    );
  }

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
                  final first = products.first;
                  catalogueController.createCatalogueAndAddProduct(name, first);
                  VerticalProductCard.sessionAddedToCatalog[first.id] = name;

                  for (final p in products.skip(1)) {
                    catalogueController.addProductToExistingCatalogue(name, p);
                    VerticalProductCard.sessionAddedToCatalog[p.id] = name;
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
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: accentColor),
                )
              : _products.isEmpty
              ? _buildEmptyState()
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 100),
                  itemCount: _products.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 3,
                    crossAxisSpacing: 3,
                    childAspectRatio: 0.58,
                  ),
                  itemBuilder: (_, i) {
                    final product = _products[i];
                    return VerticalProductCard(
                      product: product,
                      availableCatalogues: catalogueController.catalogueNames,
                      isSelected: _selectedProductIds.contains(product.id),
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
                        Get.snackbar(
                          'Added to catalog',
                          '"${product.name}" added to "$catalogueName".',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      },
                    );
                  },
                ),

          if (!hasSelection)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: _openSortSheet,
                            behavior: HitTestBehavior.opaque,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Iconsax.sort, size: 18),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    _selectedSortLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
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
                        Container(
                          height: 20,
                          width: 1,
                          color: Colors.grey.shade300,
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: _openModernFilter,
                            behavior: HitTestBehavior.opaque,
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
                                    fontSize: 13,
                                  ),
                                ),
                                if (_activeFilter.hasActiveFilters)
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
                      ],
                    ),
                  ),
                ),
              ),
            ),

          if (hasSelection)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
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
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
          ),
          if (_activeFilter.hasActiveFilters)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _activeFilter.reset();
                    _selectedCategoryId = null;
                  });
                  _loadData();
                },
                child: const Text(
                  "Clear Filters",
                  style: TextStyle(color: accentColor),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
