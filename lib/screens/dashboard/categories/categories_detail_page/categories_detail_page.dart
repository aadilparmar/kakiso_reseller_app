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
  late int _activeCategoryId;
  List<ProductModel> _products = [];
  bool _isLoadingProducts = true;
  bool _isLoadingMore = false;

  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  List<CategoryModel> _subCategories = [];
  bool _isLoadingSubCats = true;

  String _selectedSortLabel = 'Popular';
  String _orderBy = 'popularity';
  String _order = 'desc';
  FilterOptions _activeFilter = FilterOptions();

  final RangeValues _currentPriceRange = const RangeValues(0, 10000);

  final Set<int> _selectedProductIds = {};

  final catalogueController = Get.put(CatalogueController(), permanent: true);

  OverlayEntry? _currentSnackbar;

  @override
  void initState() {
    super.initState();
    _activeCategoryId = widget.categoryId;
    _scrollController.addListener(_onScroll);
    _loadData();
  }

  void _loadData() {
    _fetchSubCategories();
    _fetchCategoryProducts(refresh: true);
  }

  @override
  void dispose() {
    _removeSnackbar();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingProducts &&
        !_isLoadingMore &&
        _hasMore) {
      _fetchCategoryProducts(refresh: false);
    }
  }

  Future<void> _fetchSubCategories() async {
    setState(() => _isLoadingSubCats = true);
    try {
      final allCats = await ApiService.fetchCategories();
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

  Future<void> _fetchCategoryProducts({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _isLoadingProducts = true;
        _hasMore = true;
        _products.clear();
      });
    } else {
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      // 1. Fetch from API
      List<ProductModel> newProducts = await ApiService.fetchProductsByCategory(
        _activeCategoryId,
        orderBy: _orderBy,
        order: _order,
        minPrice: _activeFilter.minPrice ?? _currentPriceRange.start,
        maxPrice: _activeFilter.maxPrice ?? _currentPriceRange.end,
        brandIds: _activeFilter.selectedBrandIds, // <--- ADD THIS
      );

      // 2. Client-Side Filtering (Enforce In Stock & Strict Price)
      if (_activeFilter.inStockOnly) {
        // newProducts = newProducts.where((p) => p.stock > 0).toList(); // Uncomment if stock model exists
      }

      // Explicit Price Filter (Client Side fallback)
      if (_activeFilter.minPrice != null) {
        newProducts = newProducts
            .where(
              (p) => double.parse(p.price) >= (_activeFilter.minPrice ?? 0),
            )
            .toList();
      }
      if (_activeFilter.maxPrice != null) {
        newProducts = newProducts
            .where(
              (p) =>
                  double.parse(p.price) <=
                  (_activeFilter.maxPrice ?? double.infinity),
            )
            .toList();
      }

      if (mounted) {
        setState(() {
          if (newProducts.isEmpty) {
            _hasMore = false;
          } else {
            if (refresh) {
              _products = newProducts;
            } else {
              _products.addAll(newProducts);
            }
          }

          _isLoadingProducts = false;
          _isLoadingMore = false;

          _selectedProductIds.removeWhere(
            (id) => !_products.any((p) => p.id == id),
          );
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingProducts = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  void _onSubCategorySelected(int id) {
    if (_activeCategoryId == id) return;

    setState(() {
      _activeCategoryId = id;
    });

    _fetchCategoryProducts(refresh: true);
  }

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
        _fetchCategoryProducts(refresh: true);
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
      _fetchCategoryProducts(refresh: true);
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
                                _showPremiumSnackbar(
                                  title: 'Added to catalog',
                                  subtitle:
                                      '${selectedProducts.length} products added to "$name".',
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
                  _showPremiumSnackbar(
                    title: 'Catalog created',
                    subtitle: '${products.length} products added to "$name".',
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
    final selectedCount = _selectedProductIds.length;

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
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
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
                      itemCount: _subCategories.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(width: 16),
                      itemBuilder: (context, index) {
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

                Expanded(
                  child: _isLoadingProducts
                      ? const Center(
                          child: CircularProgressIndicator(color: accentColor),
                        )
                      : _products.isEmpty
                      ? _buildEmptyState()
                      : Column(
                          children: [
                            Expanded(
                              child: GridView.builder(
                                controller: _scrollController,
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
                                        if (_selectedProductIds.contains(
                                          product.id,
                                        )) {
                                          _selectedProductIds.remove(
                                            product.id,
                                          );
                                        } else {
                                          _selectedProductIds.add(product.id);
                                        }
                                      });
                                    },
                                    onCatalogueSelected:
                                        (product, catalogueName, isNew) {
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
                            if (_isLoadingMore)
                              const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: accentColor,
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
                if (hasSelection) const SizedBox(height: 70),
              ],
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
          // Added button to clear filters easily if list is empty due to filtering
          if (_activeFilter.hasActiveFilters)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _activeFilter.reset();
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
