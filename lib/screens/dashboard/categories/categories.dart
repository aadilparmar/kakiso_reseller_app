import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kakiso_reseller_app/controllers/catalouge_controller.dart';
import 'package:kakiso_reseller_app/controllers/cart_controller.dart';

// --- MODELS & SERVICES ---
import 'package:kakiso_reseller_app/models/categories.dart';
import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/models/user.dart';
import 'package:kakiso_reseller_app/screens/dashboard/categories/categories_detail_page/categories_detail_page.dart';
import 'package:kakiso_reseller_app/screens/dashboard/categories/categories_detail_page/widgets/vertical_product_card_categories.dart';
import 'package:kakiso_reseller_app/screens/dashboard/filter/filter.dart';
import 'package:kakiso_reseller_app/screens/dashboard/home/widgets/home_drawer.dart';
import 'package:kakiso_reseller_app/screens/dashboard/my_cart/my_cart.dart';
import 'package:kakiso_reseller_app/services/api_services.dart';
import 'package:kakiso_reseller_app/utils/constants.dart';
import 'package:kakiso_reseller_app/screens/dashboard/categories/widgets/search_and_filter_bar.dart';

class CategoriesSection extends StatefulWidget {
  final UserData userData;

  const CategoriesSection({super.key, required this.userData});

  @override
  State<CategoriesSection> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesSection> {
  // --- STATE ---
  bool isCategoriesLoading = true;
  String? errorMessage;
  List<CategoryModel> _allCategoriesFlat = [];

  // Caching
  final Map<int, ProductModel> _productCache = {};
  final Map<int, Future<List<ProductModel>>> _productFutureCache = {};

  // Filters & Search
  FilterOptions _activeFilter = FilterOptions();
  String _searchQuery = "";
  Timer? _debounce;

  // Navigation & Selection
  int _selectedParentId = 0;
  int? _selectedChildId;
  final Set<int> _selectedProductIds = {};

  // Controllers
  final TextEditingController _searchController = TextEditingController();
  final catalogueController = Get.put(CatalogueController(), permanent: true);
  final CartController cartController = Get.find<CartController>();
  final ScrollController _rightSideScrollController = ScrollController();

  // Design Constants
  final Color _bgRight = const Color(0xFFF4F6F9);
  final Color _bgLeft = Colors.white;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _rightSideScrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      isCategoriesLoading = true;
      errorMessage = null;
    });

    try {
      final cats = await ApiService.fetchCategories();
      if (mounted) {
        setState(() {
          _allCategoriesFlat = cats;
          isCategoriesLoading = false;
          final parents = _getParents();
          if (parents.isNotEmpty && _selectedParentId == 0) {
            _selectedParentId = parents.first.id;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isCategoriesLoading = false;
          errorMessage =
              "Failed to load categories. Please check your connection.";
        });
      }
    }
  }

  // --- SEARCH LOGIC ---
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _searchQuery = query;
          _selectedChildId = null; // Reset sub-cat selection on search
        });
      }
    });
  }

  CategoryModel? _getSelectedParent() {
    try {
      return _allCategoriesFlat.firstWhere((c) => c.id == _selectedParentId);
    } catch (_) {
      return null;
    }
  }

  double _parsePrice(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }

  // --- BULK ACTION SHEETS ---
  void _openBulkAddToCatalogueSheet() {
    if (_selectedProductIds.isEmpty) return;

    final List<ProductModel> selectedProducts = _selectedProductIds
        .map((id) => _productCache[id])
        .whereType<ProductModel>()
        .toList(growable: false);

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
            boxShadow: [BoxShadow(blurRadius: 20, color: Colors.black12)],
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
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(Iconsax.copy_success, color: accentColor),
                  const SizedBox(width: 8),
                  Text(
                    'Add ${selectedProducts.length} Items',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (availableCatalogues.isEmpty)
                _buildNoCataloguesView()
              else
                ...availableCatalogues.map(
                  (name) =>
                      _buildCatalogueListTile(ctx, name, selectedProducts),
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

  Widget _buildNoCataloguesView() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Icon(Iconsax.folder_open, size: 30, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            "No catalogs found",
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCatalogueListTile(
    BuildContext ctx,
    String name,
    List<ProductModel> products,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade100),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Iconsax.book, color: accentColor, size: 18),
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
            fontSize: 14,
          ),
        ),
        trailing: const Icon(
          Iconsax.arrow_right_3,
          size: 16,
          color: Colors.grey,
        ),
        onTap: () {
          for (final p in products) {
            catalogueController.addProductToExistingCatalogue(name, p);
          }
          Navigator.pop(ctx);
          Get.snackbar(
            'Success',
            '${products.length} products added to "$name".',
            snackPosition: SnackPosition.BOTTOM,
          );
          setState(() => _selectedProductIds.clear());
        },
      ),
    );
  }

  void _showCreateNewCatalogueDialogForBulk(List<ProductModel> products) {
    final TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'New Catalog',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: nameController,
          autofocus: true,
          style: const TextStyle(fontFamily: 'Poppins'),
          decoration: InputDecoration(
            labelText: 'Catalog Name',
            hintText: 'e.g. Summer Collection',
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty && products.isNotEmpty) {
                catalogueController.createCatalogueAndAddProduct(
                  name,
                  products.first,
                );
                for (final p in products.skip(1)) {
                  catalogueController.addProductToExistingCatalogue(name, p);
                }
                Navigator.pop(ctx);
                Get.snackbar(
                  'Success',
                  'Catalog "$name" created.',
                  snackPosition: SnackPosition.BOTTOM,
                );
                setState(() => _selectedProductIds.clear());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  List<CategoryModel> _getParents() =>
      _allCategoriesFlat.where((c) => c.parent == 0).toList();
  List<CategoryModel> _getChildren(int parentId) =>
      _allCategoriesFlat.where((c) => c.parent == parentId).toList();

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);

    return Scaffold(
      backgroundColor: _bgLeft,
      drawer: HomeDrawer(
        userData: widget.userData,
        selectedTitle: 'Categories',
        onNavigate: (id) {},
        onLogoutPressed: () {},
      ),
      appBar: _buildModernAppBar(),
      body: isCategoriesLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? _buildErrorState()
          : SafeArea(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. IMPROVED LEFT RAIL
                  _buildLeftRail(textScaler),

                  // 2. MAIN CONTENT AREA
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: _bgRight,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(-2, 0),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Column(
                            children: [
                              // Header Area
                              Container(
                                color: Colors.white,
                                padding: const EdgeInsets.only(
                                  left: 16,
                                  right: 16,
                                  top: 12,
                                  bottom: 8,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SearchAndFilterBar(
                                      controller: _searchController,
                                      onChanged: () => _onSearchChanged(
                                        _searchController.text,
                                      ),
                                      onClear: () {
                                        _searchController.clear();
                                        _onSearchChanged('');
                                      },
                                      onFilter: () async {
                                        final result =
                                            await ModernFilterBottomSheet.show(
                                              context: context,
                                              currentFilter: _activeFilter,
                                              accentColor: accentColor,
                                            );
                                        if (result != null && mounted)
                                          setState(
                                            () => _activeFilter = result,
                                          );
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    _buildDynamicHeader(),
                                  ],
                                ),
                              ),

                              // Content Area
                              Expanded(
                                child: RefreshIndicator(
                                  onRefresh: () async {
                                    _productFutureCache.clear();
                                    await _loadCategories();
                                  },
                                  color: accentColor,
                                  child: _buildRightSideContent(textScaler),
                                ),
                              ),
                            ],
                          ),

                          // Animated Floating Selection Bar
                          _buildAnimatedFloatingBar(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // --- 1. LEFT RAIL ---
  Widget _buildLeftRail(TextScaler textScaler) {
    final parents = _getParents();
    final double railWidth = (85 * textScaler.scale(1)).clamp(85, 110);

    return SizedBox(
      width: railWidth,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 10, bottom: 80),
        itemCount: parents.length,
        itemBuilder: (context, index) {
          final cat = parents[index];
          final isSelected = cat.id == _selectedParentId;

          return GestureDetector(
            onTap: () {
              if (_searchQuery.isNotEmpty) {
                _searchController.clear();
                _searchQuery = "";
              }
              setState(() {
                _selectedParentId = cat.id;
                _selectedChildId = null;
                if (_rightSideScrollController.hasClients) {
                  _rightSideScrollController.jumpTo(0);
                }
              });
            },
            child: Container(
              height: 100,
              margin: const EdgeInsets.only(bottom: 0),
              child: Stack(
                children: [
                  // Active Indicator (Vertical Bar)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 200),
                    left: 0,
                    top: isSelected ? 15 : 40,
                    bottom: isSelected ? 15 : 40,
                    width: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? accentColor : Colors.transparent,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(4),
                          bottomRight: Radius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  // Main Content
                  Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: isSelected ? railWidth - 10 : railWidth - 20,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? accentColor.withValues(alpha: 0.05)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedScale(
                            scale: isSelected ? 1.05 : 1.0,
                            duration: const Duration(milliseconds: 200),
                            child: Container(
                              height: 44,
                              width: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                border: Border.all(
                                  color: isSelected
                                      ? accentColor.withValues(alpha: 0.2)
                                      : Colors.grey.shade100,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: accentColor.withValues(
                                            alpha: 0.15,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : [],
                              ),
                              padding: const EdgeInsets.all(8),
                              child: Image.network(
                                cat.imageUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Icon(
                                  Iconsax.category,
                                  size: 20,
                                  color: isSelected ? accentColor : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Text(
                              cat.name,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? accentColor
                                    : Colors.grey.shade600,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- 2. RIGHT SIDE HEADER ---
  Widget _buildDynamicHeader() {
    if (_searchQuery.isNotEmpty) {
      return Text(
        "Found results for \"$_searchQuery\"",
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
          color: Colors.black87,
        ),
      );
    }
    final parent = _getSelectedParent();
    return Text(
      parent?.name ?? "Categories",
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        fontFamily: 'Poppins',
        color: Colors.black87,
      ),
    );
  }

  // --- 3. RIGHT SIDE CONTENT LOGIC ---
  Widget _buildRightSideContent(TextScaler textScaler) {
    if (_searchQuery.isNotEmpty) {
      return _buildSearchResultsGrid(key: ValueKey("search_$_searchQuery"));
    }

    final children = _getChildren(_selectedParentId);

    if (children.isEmpty) {
      // Direct Parent -> Products
      return _buildProductGrid(
        categoryId: _selectedParentId,
        key: ValueKey(_selectedParentId),
      );
    }

    return Column(
      children: [
        _buildSubCategoryTabs(children, textScaler),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _selectedChildId != null
                ? _buildProductGrid(
                    categoryId: _selectedChildId!,
                    key: ValueKey(_selectedChildId),
                  )
                : _buildOverviewOrDirectory(children),
          ),
        ),
      ],
    );
  }

  // --- TABS (Sub-Categories) ---
  Widget _buildSubCategoryTabs(
    List<CategoryModel> children,
    TextScaler textScaler,
  ) {
    return Container(
      height: 60,
      width: double.infinity,
      color: Colors.white,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        scrollDirection: Axis.horizontal,
        itemCount: children.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final isOverview = index == 0;
          final cat = isOverview ? null : children[index - 1];
          final isSelected = isOverview
              ? _selectedChildId == null
              : _selectedChildId == cat!.id;

          return GestureDetector(
            onTap: () =>
                setState(() => _selectedChildId = isOverview ? null : cat!.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 0),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? Colors.black87 : Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isSelected ? Colors.transparent : Colors.grey.shade300,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: Text(
                isOverview ? "All" : cat!.name,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 13,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- OVERVIEW / DIRECTORY ---
  Widget _buildOverviewOrDirectory(List<CategoryModel> children) {
    if (children.length < 6) {
      return ListView.builder(
        controller: _rightSideScrollController,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: children.length,
        itemBuilder: (context, index) {
          // KEY FIX: Unique key forces rebuild on parent change
          return _ModernCategorySection(
            key: ValueKey(children[index].id),
            category: children[index],
            onSeeAll: () => Get.to(
              () => CategoryDetailsPage(
                categoryId: children[index].id,
                categoryName: children[index].name,
              ),
            ),
            catalogueController: catalogueController,
            selectedProductIds: _selectedProductIds,
            onToggleSelection: _toggleProductSelection,
          );
        },
      );
    } else {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.1,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
        ),
        itemCount: children.length,
        itemBuilder: (context, index) {
          final cat = children[index];
          return InkWell(
            onTap: () => setState(() => _selectedChildId = cat.id),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Iconsax.folder_open,
                      color: accentColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    cat.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    "${cat.count} Items",
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }

  // --- PRODUCT GRIDS ---
  Widget _buildProductGrid({required int categoryId, Key? key}) {
    return FutureBuilder<List<ProductModel>>(
      key: key,
      future: _productFutureCache.putIfAbsent(
        categoryId,
        () => ApiService.fetchProductsByCategory(categoryId),
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return _buildSkeletonGrid();
        if (snapshot.hasError)
          return _buildErrorInline(snapshot.error.toString());
        if (!snapshot.hasData || snapshot.data!.isEmpty)
          return _buildEmptyState();
        return _buildResponsiveGrid(snapshot.data!);
      },
    );
  }

  Widget _buildSearchResultsGrid({Key? key}) {
    return FutureBuilder<List<ProductModel>>(
      key: key,
      future: ApiService.searchProducts(_searchQuery),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return _buildSkeletonGrid();
        if (snapshot.hasError)
          return _buildErrorInline(snapshot.error.toString());
        if (!snapshot.hasData || snapshot.data!.isEmpty)
          return _buildEmptyState();
        return _buildResponsiveGrid(snapshot.data!);
      },
    );
  }

  Widget _buildResponsiveGrid(List<ProductModel> rawProducts) {
    List<ProductModel> products = List.from(rawProducts);

    if (_activeFilter.minPrice != null)
      products = products
          .where((p) => _parsePrice(p.price) >= _activeFilter.minPrice!)
          .toList();
    if (_activeFilter.maxPrice != null)
      products = products
          .where((p) => _parsePrice(p.price) <= _activeFilter.maxPrice!)
          .toList();

    switch (_activeFilter.sortType) {
      case SortType.priceLowToHigh:
        products.sort(
          (a, b) => _parsePrice(a.price).compareTo(_parsePrice(b.price)),
        );
        break;
      case SortType.priceHighToLow:
        products.sort(
          (a, b) => _parsePrice(b.price).compareTo(_parsePrice(a.price)),
        );
        break;
      case SortType.newest:
        products.sort((a, b) => b.id.compareTo(a.id));
        break;
      case SortType.relevance:
        break;
    }

    for (final p in products) {
      _productCache[p.id] = p;
    }

    if (products.isEmpty)
      return _buildEmptyState("No products match your filters.");

    return LayoutBuilder(
      builder: (context, constraints) {
        double cardWidth = (constraints.maxWidth - 16) / 2;
        double desiredHeight = 280;
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 120),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: cardWidth / desiredHeight,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            return VerticalProductCard(
              product: products[index],
              availableCatalogues: catalogueController.catalogueNames,
              isSelected: _selectedProductIds.contains(products[index].id),
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
                  'Success',
                  'Added to "$catalogueName".',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            );
          },
        );
      },
    );
  }

  // --- 4. FLOATING ACTION BAR (FIXED) ---
  Widget _buildAnimatedFloatingBar() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutBack,
      bottom: _selectedProductIds.isEmpty ? -100 : 30,
      left: 16,
      right: 16,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF222222),
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left side: Count + "Selected"
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        "${_selectedProductIds.length}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Flexible(
                      child: Text(
                        "Selected",
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Right side: Actions
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Add to Catalog Button
                  InkWell(
                    onTap: _openBulkAddToCatalogueSheet,
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: const [
                          Text(
                            "Add to Catalog",
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Iconsax.add, color: Colors.black, size: 16),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Close Button (The Cross)
                  InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _selectedProductIds.clear();
                      });
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- STATES & LOADING ---
  Widget _buildSkeletonGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.65,
      ),
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 10,
                      width: 80,
                      color: Colors.grey.shade100,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 10,
                      width: 40,
                      color: Colors.grey.shade100,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState([String msg = "No products found."]) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.box_search, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            msg,
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 16,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Iconsax.wifi, size: 60, color: Colors.redAccent),
          const SizedBox(height: 16),
          const Text(
            "Connection Issue",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage ?? "Something went wrong.",
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadCategories,
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
            ),
            child: const Text("Retry"),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorInline(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          "Error: $error",
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }

  // --- UTILS ---
  void _toggleProductSelection(int id) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_selectedProductIds.contains(id)) {
        _selectedProductIds.remove(id);
      } else {
        _selectedProductIds.add(id);
      }
    });
  }

  AppBar _buildModernAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Row(
        children: [
          const SizedBox(width: 8),
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Iconsax.menu_1),
              color: accentColor,
              iconSize: 28,
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          Image.asset(
            'assets/logos/login-logo.png',
            height: 40,
            width: 90,
            fit: BoxFit.contain,
          ),
          const Spacer(),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Iconsax.shopping_cart),
                color: accentColor,
                iconSize: 28,
                onPressed: () => Get.to(() => const InventoryPage()),
              ),
              Positioned(
                right: 6,
                top: 6,
                child: Obx(() {
                  final count = cartController.itemCount;
                  if (count == 0) return const SizedBox.shrink();
                  return Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Center(
                      child: Text(
                        count > 99 ? '99+' : '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Iconsax.profile_circle),
            color: accentColor,
            iconSize: 28,
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// --- CHILD WIDGET: Modern Category Section ---
class _ModernCategorySection extends StatefulWidget {
  final CategoryModel category;
  final VoidCallback onSeeAll;
  final CatalogueController catalogueController;
  final Set<int> selectedProductIds;
  final Function(int) onToggleSelection;

  const _ModernCategorySection({
    Key? key,
    required this.category,
    required this.onSeeAll,
    required this.catalogueController,
    required this.selectedProductIds,
    required this.onToggleSelection,
  }) : super(key: key);

  @override
  State<_ModernCategorySection> createState() => _ModernCategorySectionState();
}

class _ModernCategorySectionState extends State<_ModernCategorySection> {
  List<ProductModel> products = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  void _fetch() async {
    try {
      final res = await ApiService.fetchProductsByCategory(widget.category.id);
      if (mounted) {
        setState(() {
          products = res.take(4).toList();
          loading = false;
        });

        final parentState = context
            .findAncestorStateOfType<_CategoriesPageState>();
        if (parentState != null) {
          for (final p in products) parentState._productCache[p.id] = p;
        }
      }
    } catch (e) {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!loading && products.isEmpty) return const SizedBox();

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.category.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                ),
              ),
              TextButton(
                onPressed: widget.onSeeAll,
                child: const Text(
                  "See All",
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          loading
              ? _buildShimmer()
              : LayoutBuilder(
                  builder: (context, constraints) {
                    double width = (constraints.maxWidth - 12) / 2;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: width / 260,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final p = products[index];
                        return VerticalProductCard(
                          product: p,
                          availableCatalogues:
                              widget.catalogueController.catalogueNames,
                          isSelected: widget.selectedProductIds.contains(p.id),
                          onSelectionToggle: () =>
                              widget.onToggleSelection(p.id),
                          onCatalogueSelected: (product, catalogueName, isNew) {
                            if (isNew) {
                              widget.catalogueController
                                  .createCatalogueAndAddProduct(
                                    catalogueName,
                                    product,
                                  );
                            } else {
                              widget.catalogueController
                                  .addProductToExistingCatalogue(
                                    catalogueName,
                                    product,
                                  );
                            }
                          },
                        );
                      },
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return SizedBox(
      height: 200,
      child: Row(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(4),
              color: Colors.grey.shade100,
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(4),
              color: Colors.grey.shade100,
            ),
          ),
        ],
      ),
    );
  }
}
