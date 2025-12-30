// lib/screens/dashboard/categories/categories_detail_page/category_details_page.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import 'package:kakiso_reseller_app/controllers/catalouge_controller.dart';
import 'package:kakiso_reseller_app/models/categories.dart';
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
  // --- STATE ---

  // Active ID (Starts as the main category, changes if a sub-category is clicked)
  late int _activeCategoryId;

  // Products
  List<ProductModel> _products = [];
  bool _isLoadingProducts = true;

  // Sub-Categories (Children of the main category)
  List<CategoryModel> _subCategories = [];
  bool _isLoadingSubCats = true;

  // Filter & Sort
  String _selectedSortLabel = 'Popular';
  String _orderBy = 'popularity';
  String _order = 'desc';
  FilterOptions _activeFilter = FilterOptions();

  // Price Filter
  RangeValues _currentPriceRange = const RangeValues(0, 10000);
  final double _maxFilterLimit = 20000;

  // Bulk Selection
  final Set<int> _selectedProductIds = {};

  // Controllers
  final catalogueController = Get.put(CatalogueController(), permanent: true);

  // Snackbar
  OverlayEntry? _currentSnackbar;

  @override
  void initState() {
    super.initState();
    // Initialize active ID to the passed category
    _activeCategoryId = widget.categoryId;

    _loadData();
  }

  void _loadData() {
    _fetchSubCategories(); // Load the horizontal list (Children of Parent)
    _fetchCategoryProducts(); // Load products for current active ID
  }

  @override
  void dispose() {
    _removeSnackbar();
    super.dispose();
  }

  // --- API CALLS ---

  Future<void> _fetchSubCategories() async {
    setState(() => _isLoadingSubCats = true);
    try {
      // 1. Fetch all categories (or use a specific API if available)
      final allCats = await ApiService.fetchCategories();

      // 2. Filter for children of the MAIN category (widget.categoryId)
      // This list remains constant regardless of which child is selected
      final children = allCats
          .where((c) => c.parent == widget.categoryId)
          .toList();

      if (mounted) {
        setState(() {
          _subCategories = children;
          _isLoadingSubCats = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingSubCats = false);
    }
  }

  Future<void> _fetchCategoryProducts() async {
    setState(() => _isLoadingProducts = true);
    try {
      // Use _activeCategoryId (which might be the parent OR a child)
      final products = await ApiService.fetchProductsByCategory(
        _activeCategoryId,
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
          _isLoadingProducts = false;
          // Clear selections that are no longer visible
          _selectedProductIds.removeWhere(
            (id) => !_products.any((p) => p.id == id),
          );
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingProducts = false);
    }
  }

  // --- HANDLERS ---

  void _onSubCategorySelected(int id) {
    if (_activeCategoryId == id) return; // No change

    setState(() {
      _activeCategoryId = id;
      _isLoadingProducts = true; // Show loader immediately
    });

    _fetchCategoryProducts();
  }

  // --- PREMIUM SNACKBAR ---
  void _removeSnackbar() {
    _currentSnackbar?.remove();
    _currentSnackbar = null;
  }

  void _showPremiumSnackbar({
    required String title,
    required String subtitle,
    String? imageUrl,
  }) {
    _removeSnackbar();
    final overlay = Overlay.of(context);
    _currentSnackbar = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (event) => _removeSnackbar(),
            ),
          ),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Material(
              color: Colors.transparent,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 500),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 50 * (1 - value)),
                    child: Opacity(
                      opacity: value.clamp(0.0, 1.0),
                      child: child,
                    ),
                  );
                },
                child: _buildPremiumSnackbarContent(title, subtitle, imageUrl),
              ),
            ),
          ),
        ],
      ),
    );
    overlay.insert(_currentSnackbar!);
    Future.delayed(const Duration(seconds: 3), () {
      if (_currentSnackbar != null && mounted) _removeSnackbar();
    });
  }

  Widget _buildPremiumSnackbarContent(
    String title,
    String subtitle,
    String? imageUrl,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1F2937).withOpacity(0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              if (imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    width: 45,
                    height: 45,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Iconsax.folder_open,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Iconsax.tick_circle,
                color: Color(0xFF16A34A),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- SORT & FILTER UI ---
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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

  Widget _buildSortOption(String label, String apiOrderBy, String apiOrder) {
    final bool isSelected = _orderBy == apiOrderBy && _order == apiOrder;
    return ListTile(
      title: Text(
        label,
        style: TextStyle(
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
        _fetchCategoryProducts();
      },
    );
  }

  Future<void> _openModernFilter() async {
    final result = await ModernFilterBottomSheet.show(
      context: context,
      currentFilter: _activeFilter,
      accentColor: accentColor,
    );
    if (result != null) {
      setState(() {
        _activeFilter = result;
      });
      _fetchCategoryProducts();
    }
  }

  // --- BULK ACTION ---
  void _openBulkAddToCatalogueSheet() {
    final selectedProducts = _products
        .where((p) => _selectedProductIds.contains(p.id))
        .toList();
    if (selectedProducts.isEmpty) return;

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
                'Add ${selectedProducts.length} items to...',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              if (availableCatalogues.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text("No catalogues found. Create one."),
                  ),
                )
              else
                ...availableCatalogues.map(
                  (name) => ListTile(
                    leading: const Icon(Iconsax.folder),
                    title: Text(name),
                    onTap: () {
                      for (final p in selectedProducts) {
                        catalogueController.addProductToExistingCatalogue(
                          name,
                          p,
                        );
                      }
                      Navigator.pop(ctx);
                      _showPremiumSnackbar(
                        title: 'Success',
                        subtitle: 'Added to $name',
                      );
                      setState(() => _selectedProductIds.clear());
                    },
                  ),
                ),

              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  // Quick inline creation logic for brevity
                  catalogueController.createCatalogueAndAddProduct(
                    "New Collection",
                    selectedProducts.first,
                  );
                  _showPremiumSnackbar(
                    title: 'Success',
                    subtitle: 'Created "New Collection"',
                  );
                },
                child: const Text("Create New Catalog"),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasSelection = _selectedProductIds.isNotEmpty;

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
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // --- 1. SUB-CATEGORIES LIST (Updated Logic) ---
              if (!_isLoadingSubCats && _subCategories.isNotEmpty)
                Container(
                  height: 110,
                  width: double.infinity,
                  color: Colors.white,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    scrollDirection: Axis.horizontal,
                    // +1 for the "All" button
                    itemCount: _subCategories.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(width: 16),
                    itemBuilder: (context, index) {
                      // --- "ALL" BUTTON ---
                      if (index == 0) {
                        final isSelected =
                            _activeCategoryId == widget.categoryId;
                        return GestureDetector(
                          onTap: () =>
                              _onSubCategorySelected(widget.categoryId),
                          child: Column(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                height: 60,
                                width: 60,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? accentColor
                                      : Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? accentColor
                                        : Colors.grey.shade300,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Icon(
                                  Iconsax.category,
                                  size: 24,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "All",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? accentColor
                                      : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // --- SUB-CATEGORY ITEMS ---
                      final subCat = _subCategories[index - 1];
                      final isSelected = _activeCategoryId == subCat.id;

                      return GestureDetector(
                        onTap: () => _onSubCategorySelected(subCat.id),
                        child: Column(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              height: 60,
                              width: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? accentColor
                                      : Colors.grey.shade200,
                                  width: isSelected ? 2 : 1,
                                ),
                                image: DecorationImage(
                                  image: NetworkImage(subCat.imageUrl),
                                  fit: BoxFit.cover,
                                  onError: (_, __) {},
                                ),
                              ),
                              // Show fallback icon if image fails or is empty
                              child: subCat.imageUrl.isEmpty
                                  ? const Icon(Iconsax.image)
                                  : null,
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              width: 60,
                              child: Text(
                                subCat.name,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? accentColor
                                      : Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

              // --- 2. SORT & FILTER BAR ---
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _openSortSheet,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Iconsax.sort, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              _selectedSortLabel,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
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
                    Container(
                      height: 20,
                      width: 1,
                      color: Colors.grey.shade300,
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: _openModernFilter,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Iconsax.filter, size: 18),
                            const SizedBox(width: 8),
                            const Text(
                              "Filter",
                              style: TextStyle(
                                fontSize: 13,
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
              const Divider(height: 1, color: Color(0xFFEEEEEE)),

              // --- 3. PRODUCT GRID ---
              Expanded(
                child: _isLoadingProducts
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
                              _showPremiumSnackbar(
                                title: 'Added to catalog',
                                subtitle:
                                    '"${product.name}" added to "$catalogueName".',
                                imageUrl: product.image,
                              );
                            },
                          );
                        },
                      ),
              ),
              if (hasSelection) const SizedBox(height: 70),
            ],
          ),

          // --- 4. FLOATING BULK BAR ---
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
                        '${_selectedProductIds.length} products selected',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _openBulkAddToCatalogueSheet,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: const Text(
                        'Add to Catalog',
                        style: TextStyle(color: Colors.white, fontSize: 12),
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
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
