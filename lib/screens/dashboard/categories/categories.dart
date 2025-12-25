import 'dart:async';
import 'dart:ui'; // Required for ImageFilter
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

class CategoriesSection extends StatefulWidget {
  final UserData userData;

  const CategoriesSection({super.key, required this.userData});

  @override
  State<CategoriesSection> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesSection>
    with TickerProviderStateMixin {
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

  final ScrollController _rightScrollController = ScrollController();

  // Design Constants
  final Color _bgRight = const Color(0xFFFAFAFA);
  final Color _bgLeft = Colors.white;
  final Color _textDark = const Color(0xFF1A1A1A);

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _rightScrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // --- SNACKBAR HELPERS ---
  void _showSuccessSnackbar(String title, String message) {
    HapticFeedback.mediumImpact();
    if (Get.isSnackbarOpen) Get.closeAllSnackbars();
    Get.snackbar(
      title,
      message,
      titleText: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
      messageText: Text(
        message,
        style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
      ),
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      borderRadius: 12,
      backgroundColor: const Color(0xFF2C2C2C),
      icon: const Icon(Iconsax.tick_circle, color: accentColor, size: 24),
      duration: const Duration(seconds: 3),
    );
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
          errorMessage = "Failed to load categories.";
        });
      }
    }
  }

  // --- SEARCH LOGIC ---
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
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

  // --- BULK ACTIONS ---
  void _openBulkAddToCatalogueSheet() {
    if (_selectedProductIds.isEmpty) return;

    final List<ProductModel> selectedProducts = _selectedProductIds
        .map((id) => _productCache[id])
        .whereType<ProductModel>()
        .toList();

    final availableCatalogues = catalogueController.catalogueNames;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          children: [
            Container(height: 4, width: 40, color: Colors.grey.shade300),
            const SizedBox(height: 20),
            Text(
              "Add ${selectedProducts.length} items to...",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: availableCatalogues.isEmpty
                  ? Center(
                      child: Text(
                        "No catalogues found.",
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    )
                  : ListView.builder(
                      itemCount: availableCatalogues.length,
                      itemBuilder: (context, index) {
                        final name = availableCatalogues[index];
                        return ListTile(
                          leading: const Icon(Iconsax.folder),
                          title: Text(name),
                          trailing: const Icon(
                            Iconsax.add_circle,
                            color: accentColor,
                          ),
                          onTap: () {
                            for (var p in selectedProducts) {
                              catalogueController.addProductToExistingCatalogue(
                                name,
                                p,
                              );
                            }
                            Navigator.pop(ctx);
                            _showSuccessSnackbar("Success", "Added to $name");
                            setState(() => _selectedProductIds.clear());
                          },
                        );
                      },
                    ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _showCreateNewCatalogueDialogForBulk(selectedProducts);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _textDark,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Create New Catalogue"),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateNewCatalogueDialogForBulk(List<ProductModel> products) {
    final TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("New Catalog"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: "Catalog Name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                catalogueController.createCatalogueAndAddProduct(
                  nameController.text,
                  products.first,
                );
                for (var p in products.skip(1)) {
                  catalogueController.addProductToExistingCatalogue(
                    nameController.text,
                    p,
                  );
                }
                Navigator.pop(ctx);
                _showSuccessSnackbar("Success", "Catalog Created");
                setState(() => _selectedProductIds.clear());
              }
            },
            child: const Text("Create"),
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
          ? const Center(child: CircularProgressIndicator(color: accentColor))
          : errorMessage != null
          ? _buildErrorState()
          : SafeArea(
              child: Stack(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // LEFT RAIL
                      _buildLeftRail(textScaler),

                      // RIGHT CONTENT
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: _bgRight,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(-4, 0),
                              ),
                            ],
                          ),
                          child: RefreshIndicator(
                            color: accentColor,
                            onRefresh: () async {
                              _productFutureCache.clear();
                              await _loadCategories();
                            },
                            child: CustomScrollView(
                              controller: _rightScrollController,
                              physics: const BouncingScrollPhysics(),
                              slivers: [
                                // FIX: Title acts as a normal scrollable item
                                _buildTitleSliver(),

                                // FIX: Sticky Header only contains the Search Bar now (Fixed Height)
                                SliverPersistentHeader(
                                  pinned: true,
                                  delegate: _StickySearchDelegate(
                                    height:
                                        74, // Fixed height prevents overflow
                                    child: _buildStickySearchBar(),
                                  ),
                                ),

                                if (_searchQuery.isEmpty &&
                                    _getChildren(_selectedParentId).isNotEmpty)
                                  SliverPersistentHeader(
                                    pinned: true,
                                    delegate: _StickyFilterDelegate(
                                      height: 60,
                                      child: _buildSubCategoryTabs(
                                        _getChildren(_selectedParentId),
                                      ),
                                    ),
                                  ),
                                _buildRightSideBody(),
                                const SliverPadding(
                                  padding: EdgeInsets.only(bottom: 100),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  _buildAnimatedFloatingBar(),
                ],
              ),
            ),
    );
  }

  // --- LEFT RAIL ---
  Widget _buildLeftRail(TextScaler textScaler) {
    final parents = _getParents();
    final double railWidth = (85 * textScaler.scale(1)).clamp(85, 110);

    return SizedBox(
      width: railWidth,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 20, bottom: 80),
        itemCount: parents.length,
        itemBuilder: (context, index) {
          final cat = parents[index];
          final isSelected = cat.id == _selectedParentId;

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              if (_searchQuery.isNotEmpty) {
                _searchController.clear();
                _onSearchChanged("");
              }
              setState(() {
                _selectedParentId = cat.id;
                _selectedChildId = null;
              });
              if (_rightScrollController.hasClients) {
                _rightScrollController.jumpTo(0);
              }
            },
            child: Container(
              color: Colors.transparent,
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: isSelected ? 36 : 0,
                    width: 4,
                    decoration: const BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(4),
                        bottomRight: Radius.circular(4),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 4,
                      ),
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 48,
                            width: 48,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? accentColor.withOpacity(0.1)
                                  : Colors.grey.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Image.network(
                              cat.imageUrl,
                              errorBuilder: (_, __, ___) => Icon(
                                Iconsax.category,
                                color: isSelected ? accentColor : Colors.grey,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            cat.name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected ? _textDark : Colors.grey,
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

  // --- RIGHT HEADER COMPONENTS ---

  // 1. Scrollable Title (New)
  Widget _buildTitleSliver() {
    final parent = _getSelectedParent();
    if (_searchQuery.isNotEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Container(
        color: _bgRight,
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
        child: Text(
          parent?.name ?? "Categories",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: _textDark,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }

  // 2. Sticky Search Bar (Updated)
  Widget _buildStickySearchBar() {
    return Container(
      color:
          _bgRight, // Background ensures content doesn't show behind when sticky
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      alignment: Alignment.center,
      child: SearchAndFilterBar(
        controller: _searchController,
        onChanged: (String val) => _onSearchChanged(val),
        onClear: () {
          _searchController.clear();
          _onSearchChanged('');
        },
        onFilter: () async {
          final result = await ModernFilterBottomSheet.show(
            context: context,
            currentFilter: _activeFilter,
            accentColor: accentColor,
          );
          if (result != null && mounted) setState(() => _activeFilter = result);
        },
      ),
    );
  }

  // --- SUB TABS ---
  Widget _buildSubCategoryTabs(List<CategoryModel> children) {
    return Container(
      color: _bgRight,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        scrollDirection: Axis.horizontal,
        itemCount: children.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
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
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? _textDark : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? Colors.transparent : Colors.grey.shade300,
                ),
              ),
              child: Text(
                isOverview ? "All" : cat!.name,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- BODY ---
  Widget _buildRightSideBody() {
    if (_searchQuery.isNotEmpty) return _buildSearchResultsGrid();

    final children = _getChildren(_selectedParentId);

    if (children.isEmpty) {
      return _buildProductGrid(
        categoryId: _selectedParentId,
        key: ValueKey("p_$_selectedParentId"),
      );
    }

    if (_selectedChildId != null) {
      return _buildProductGrid(
        categoryId: _selectedChildId!,
        key: ValueKey("c_$_selectedChildId"),
      );
    } else {
      return _buildOverviewSliver(children);
    }
  }

  Widget _buildOverviewSliver(List<CategoryModel> children) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final cat = children[index];
          return _ModernCategorySection(
            key: ValueKey("sec_${cat.id}"),
            category: cat,
            onSeeAll: () => Get.to(
              () => CategoryDetailsPage(
                categoryId: cat.id,
                categoryName: cat.name,
              ),
            ),
            catalogueController: catalogueController,
            selectedProductIds: _selectedProductIds,
            onToggleSelection: _toggleProductSelection,
            onSuccess: _showSuccessSnackbar,
          );
        }, childCount: children.length),
      ),
    );
  }

  Widget _buildProductGrid({required int categoryId, Key? key}) {
    return FutureBuilder<List<ProductModel>>(
      key: key,
      future: _productFutureCache.putIfAbsent(
        categoryId,
        () => ApiService.fetchProductsByCategory(categoryId),
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(child: _SliverSkeletonGrid());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SliverFillRemaining(child: _EmptyState("No products."));
        }
        return _buildSliverGridProducts(snapshot.data!);
      },
    );
  }

  Widget _buildSearchResultsGrid() {
    return FutureBuilder<List<ProductModel>>(
      future: ApiService.searchProducts(_searchQuery),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(child: _SliverSkeletonGrid());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SliverFillRemaining(child: _EmptyState("No results."));
        }
        return _buildSliverGridProducts(snapshot.data!);
      },
    );
  }

  Widget _buildSliverGridProducts(List<ProductModel> rawProducts) {
    List<ProductModel> products = List.from(rawProducts);

    // Filter & Sort Logic
    if (_activeFilter.minPrice != null) {
      products = products
          .where((p) => _parsePrice(p.price) >= _activeFilter.minPrice!)
          .toList();
    }
    if (_activeFilter.maxPrice != null) {
      products = products
          .where((p) => _parsePrice(p.price) <= _activeFilter.maxPrice!)
          .toList();
    }
    if (_activeFilter.sortType == SortType.priceLowToHigh) {
      products.sort(
        (a, b) => _parsePrice(a.price).compareTo(_parsePrice(b.price)),
      );
    } else if (_activeFilter.sortType == SortType.priceHighToLow)
      // ignore: curly_braces_in_flow_control_structures
      products.sort(
        (a, b) => _parsePrice(b.price).compareTo(_parsePrice(a.price)),
      );

    for (final p in products) _productCache[p.id] = p;

    return SliverPadding(
      padding: const EdgeInsets.all(12),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.56,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final p = products[index];
          return VerticalProductCard(
            product: p,
            availableCatalogues: catalogueController.catalogueNames,
            isSelected: _selectedProductIds.contains(p.id),
            onSelectionToggle: () => _toggleProductSelection(p.id),
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
              _showSuccessSnackbar('Success', 'Added to $catalogueName');
            },
          );
        }, childCount: products.length),
      ),
    );
  }

  // --- FLOATING BAR ---
  Widget _buildAnimatedFloatingBar() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 500),
      curve: Curves.elasticOut,
      bottom: _selectedProductIds.isEmpty ? -120 : 30,
      left: 20,
      right: 20,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E).withOpacity(0.9),
                borderRadius: BorderRadius.circular(32),
              ),
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
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "Selected",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 20),
                  InkWell(
                    onTap: _openBulkAddToCatalogueSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "Add to Catalog",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: () => setState(() => _selectedProductIds.clear()),
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _toggleProductSelection(int id) {
    HapticFeedback.selectionClick();
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
      title: Row(
        children: [
          IconButton(
            icon: const Icon(Iconsax.menu_1),
            color: _textDark,
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
          Image.asset(
            'assets/logos/login-logo.png',
            height: 28,
            width: 80,
            fit: BoxFit.contain,
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Iconsax.shopping_bag),
            color: _textDark,
            onPressed: () => Get.to(() => const InventoryPage()),
          ),
          IconButton(
            icon: const Icon(Iconsax.profile_circle),
            color: _textDark,
            onPressed: () {},
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
          const Icon(Iconsax.wifi, size: 40, color: Colors.red),
          const SizedBox(height: 10),
          const Text("Connection Failed"),
          TextButton(onPressed: _loadCategories, child: const Text("Retry")),
        ],
      ),
    );
  }
}

// --- DELEGATES ---

class _StickySearchDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;
  _StickySearchDelegate({required this.height, required this.child});
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => SizedBox.expand(child: child);
  @override
  double get maxExtent => height;
  @override
  double get minExtent => height;
  @override
  bool shouldRebuild(_StickySearchDelegate oldDelegate) => true;
}

class _StickyFilterDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;
  _StickyFilterDelegate({required this.height, required this.child});
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => SizedBox.expand(child: child);
  @override
  double get maxExtent => height;
  @override
  double get minExtent => height;
  @override
  bool shouldRebuild(_StickyFilterDelegate oldDelegate) => true;
}

// --- WIDGETS ---

class _EmptyState extends StatelessWidget {
  final String msg;
  const _EmptyState(this.msg);
  @override
  Widget build(BuildContext context) => Center(
    child: Text(msg, style: TextStyle(color: Colors.grey.shade400)),
  );
}

class _SliverSkeletonGrid extends StatelessWidget {
  const _SliverSkeletonGrid();
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.6,
      ),
      itemBuilder: (_, __) => Container(color: Colors.grey.shade100),
    );
  }
}

class _ModernCategorySection extends StatefulWidget {
  final CategoryModel category;
  final VoidCallback onSeeAll;
  final CatalogueController catalogueController;
  final Set<int> selectedProductIds;
  final Function(int) onToggleSelection;
  final Function(String, String) onSuccess;

  const _ModernCategorySection({
    Key? key,
    required this.category,
    required this.onSeeAll,
    required this.catalogueController,
    required this.selectedProductIds,
    required this.onToggleSelection,
    required this.onSuccess,
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
      }
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!loading && products.isEmpty) return const SizedBox();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.category.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              InkWell(
                onTap: widget.onSeeAll,
                child: const Text(
                  "View All",
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        loading
            ? const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              )
            : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.56,
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
                    onSelectionToggle: () => widget.onToggleSelection(p.id),
                    onCatalogueSelected: (product, catalogueName, isNew) {
                      if (isNew) {
                        widget.catalogueController.createCatalogueAndAddProduct(
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
                      widget.onSuccess('Success', 'Added to $catalogueName');
                    },
                  );
                },
              ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class SearchAndFilterBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onFilter;

  const SearchAndFilterBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.onFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search products...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: const Icon(
                  Iconsax.search_normal,
                  size: 20,
                  color: Colors.grey,
                ),
                suffixIcon: controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: onClear,
                        color: Colors.grey,
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        InkWell(
          onTap: onFilter,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Icon(Iconsax.setting_4, color: Colors.black, size: 22),
          ),
        ),
      ],
    );
  }
}
