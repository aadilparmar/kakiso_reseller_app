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
  List<CategoryModel> _allCategoriesFlat = [];
  // final List<ProductModel> _products = [];
  final Map<int, ProductModel> _productCache = {};
  final Map<int, Future<List<ProductModel>>> _productFutureCache = {};

  // Navigation
  int _selectedParentId = 0;
  int? _selectedChildId;

  final Set<int> _selectedProductIds = {};

  // Controllers
  final TextEditingController _searchController = TextEditingController();
  final catalogueController = Get.put(CatalogueController(), permanent: true);
  final CartController cartController = Get.find<CartController>();
  final ScrollController _rightSideScrollController = ScrollController();

  // Design Constants
  final Color _bgRight = const Color(0xFFF8F9FD);
  final Color _bgLeft = Colors.white;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await ApiService.fetchCategories();
      if (mounted) {
        setState(() {
          _allCategoriesFlat = cats;
          isCategoriesLoading = false;
          final parents = _getParents();
          if (parents.isNotEmpty) {
            _selectedParentId = parents.first.id;
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => isCategoriesLoading = false);
    }
  }

  CategoryModel? _getSelectedParent() {
    try {
      return _allCategoriesFlat.firstWhere((c) => c.id == _selectedParentId);
    } catch (_) {
      return null;
    }
  }

  void _openBulkAddToCatalogueSheet() {
    if (_selectedProductIds.isEmpty) return;

    final List<ProductModel> selectedProducts = _selectedProductIds
        .map((id) => _productCache[id])
        .whereType<ProductModel>()
        .toList(growable: false);

    if (selectedProducts.isEmpty) {
      Get.snackbar(
        'Bulk add failed',
        'No products available for cataloging.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

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

  Widget _buildParentCategoryHeader() {
    final parent = _getSelectedParent();
    if (parent == null) return const SizedBox();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          // Optional icon/image
          // Container(
          //   height: 36,
          //   width: 36,
          //   padding: const EdgeInsets.all(6),
          //   decoration: BoxDecoration(
          //     color: accentColor.withValues(alpha: 0.08),
          //     shape: BoxShape.circle,
          //   ),
          //   child: Image.network(
          //     parent.imageUrl,
          //     fit: BoxFit.contain,
          //     errorBuilder: (_, __, ___) =>
          //         const Icon(Iconsax.category, size: 18),
          //   ),
          // ),
          // const SizedBox(width: 12),
          Expanded(
            child: Text(
              parent.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
                color: Colors.black87,
              ),
            ),
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
    // Get TextScaler to adapt sizes dynamically
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
          : SafeArea(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Responsive Left Rail
                  _buildLeftRail(textScaler),

                  // 2. Main Content Area
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: _bgRight,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(-4, 0),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Column(
                            children: [
                              // Search Header - Wrap in Container to constrain height if needed
                              Container(
                                color: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: SearchAndFilterBar(
                                  controller: _searchController,
                                  onChanged: () {},
                                  onClear: () => _searchController.clear(),
                                  onFilter: () {},
                                ),
                              ),
                              // 🔹 Parent Category Title
                              _buildParentCategoryHeader(),

                              // Dynamic Content
                              Expanded(
                                child: _buildRightSideContent(textScaler),
                              ),
                            ],
                          ),

                          // Floating Action Bar
                          _buildFloatingSelectionBar(textScaler),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // --- 1. LEFT RAIL (Responsive) ---
  Widget _buildLeftRail(TextScaler textScaler) {
    final parents = _getParents();
    // Calculate width based on font scale, keeping a sensible minimum and maximum
    final double railWidth = (80 * textScaler.scale(1)).clamp(80, 110);

    return SizedBox(
      width: railWidth,
      child: Container(
        color: Colors.white,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 16),
          itemCount: parents.length,
          itemBuilder: (context, index) {
            final cat = parents[index];
            final isSelected = cat.id == _selectedParentId;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedParentId = cat.id;
                  _selectedChildId = null;
                  if (_rightSideScrollController.hasClients) {
                    _rightSideScrollController.jumpTo(0);
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 4,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? accentColor.withValues(alpha: 0.08)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected
                      ? Border.all(
                          color: accentColor.withValues(alpha: 0.2),
                          width: 1,
                        )
                      : Border.all(color: Colors.transparent),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min, // prevent expansion
                  children: [
                    // Icon Container
                    AnimatedScale(
                      scale: isSelected ? 1.1 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: accentColor.withValues(alpha: 0.2),
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
                          errorBuilder: (_, __, ___) =>
                              const Icon(Iconsax.category, size: 18),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Responsive Text
                    Flexible(
                      child: Text(
                        cat.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10, // Will scale automatically via system
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
            );
          },
        ),
      ),
    );
  }

  // --- 2. RIGHT SIDE CONTENT ---
  Widget _buildRightSideContent(TextScaler textScaler) {
    final children = _getChildren(_selectedParentId);

    if (children.isEmpty) {
      return _buildProductGrid(categoryId: _selectedParentId);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tabs
        _buildSubCategoryTabs(children, textScaler),

        // Content
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

  Widget _buildSubCategoryTabs(
    List<CategoryModel> children,
    TextScaler textScaler,
  ) {
    // Dynamic height for the tab bar based on text scale
    final double barHeight = (50 * textScaler.scale(1)).clamp(50, 70);

    return Container(
      height: barHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        scrollDirection: Axis.horizontal,
        itemCount: children.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isOverview = index == 0;
          final cat = isOverview ? null : children[index - 1];
          final isSelected = isOverview
              ? _selectedChildId == null
              : _selectedChildId == cat!.id;
          final label = isOverview ? "Overview" : cat!.name;

          return InkWell(
            onTap: () =>
                setState(() => _selectedChildId = isOverview ? null : cat!.id),
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? Colors.black87 : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? Colors.transparent : Colors.grey.shade200,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade700,
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

  Widget _buildOverviewOrDirectory(List<CategoryModel> children) {
    if (children.length < 5) {
      return ListView.builder(
        controller: _rightSideScrollController,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: children.length,
        itemBuilder: (context, index) {
          return _ModernCategorySection(
            category: children[index],
            onSeeAll: () {
              Get.to(
                () => CategoryDetailsPage(
                  categoryId: children[index].id,
                  categoryName: children[index].name,
                ),
              );
            },
            catalogueController: catalogueController,
            selectedProductIds: _selectedProductIds,
            onToggleSelection: _toggleProductSelection,
          );
        },
      );
    } else {
      // Responsive Grid Aspect Ratio Calculation
      return LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final crossAxisCount = width > 600 ? 3 : 2; // 3 columns on tablet
          // Calculate ratio: Width / (Icon Height + Text Height + Padding)
          final ratio = width > 600 ? 1.3 : 1.1;

          return GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: ratio,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
            ),
            itemCount: children.length,
            itemBuilder: (context, index) {
              final cat = children[index];
              return InkWell(
                onTap: () => setState(() => _selectedChildId = cat.id),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade200,
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.05),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Iconsax.folder_open,
                            color: accentColor,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          cat.name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${cat.count} Items",
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    }
  }

  Widget _buildSkeletonGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.65,
      ),
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // --- 3. PRODUCT GRID (Dynamic Ratio) ---
  Widget _buildProductGrid({required int categoryId, Key? key}) {
    return FutureBuilder<List<ProductModel>>(
      key: key,
      future: _productFutureCache.putIfAbsent(
        categoryId,
        () => ApiService.fetchProductsByCategory(categoryId),
      ),

      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSkeletonGrid();
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState();
        }

        final products = snapshot.data!;

        // 🔹 Cache products for cataloguing
        for (final p in products) {
          _productCache[p.id] = p;
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            // Logic to calculate Card Aspect Ratio based on width
            double cardWidth =
                (constraints.maxWidth - 16) / 2; // 2 columns minus spacing
            // Estimate height needed for VerticalProductCard (Image + Title + Price + Catalog Button)
            // Adjust this constant (260) based on your VerticalProductCard's actual content height requirements
            double desiredHeight = 280;
            double childAspectRatio = cardWidth / desiredHeight;

            return GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio:
                    childAspectRatio, // Dynamic ratio prevents overflow
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
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
                      'Added to catalog',
                      '"${product.name}" added to "$catalogueName".',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  },
                );
              },
            );
          },
        );
      },
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
      surfaceTintColor: Colors.white,
      elevation: 0,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Iconsax.menu_1, color: Colors.black),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: const Text(
        "Categories",
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      actions: [
        Obx(() {
          final count = cartController.itemCount;
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  onPressed: () => Get.to(() => const InventoryPage()),
                  icon: const Icon(Iconsax.shopping_bag, color: Colors.black),
                ),
                if (count > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.box_search, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            "No products found",
            style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingSelectionBar(TextScaler textScaler) {
    if (_selectedProductIds.isEmpty) return const SizedBox();

    // Calculate flexible width for the floating bar
    double barWidth = MediaQuery.of(context).size.width * 0.8;
    if (barWidth > 400) barWidth = 400; // Max width cap

    return Positioned(
      bottom: 30,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          width: barWidth,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        "${_selectedProductIds.length}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
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
              InkWell(
                onTap: _openBulkAddToCatalogueSheet, // Handle Add
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Iconsax.add_circle, color: accentColor, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Add to Catalog",
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- MODERN SECTION WIDGET ---
class _ModernCategorySection extends StatefulWidget {
  final CategoryModel category;
  final VoidCallback onSeeAll;
  final CatalogueController catalogueController;
  final Set<int> selectedProductIds;
  final Function(int) onToggleSelection;

  const _ModernCategorySection({
    required this.category,
    required this.onSeeAll,
    required this.catalogueController,
    required this.selectedProductIds,
    required this.onToggleSelection,
  });

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
          products = res.take(6).toList();
          loading = false;
        });

        // 🔹 STEP 5: cache preview products in parent Categories page
        final parentState = context
            .findAncestorStateOfType<_CategoriesPageState>();

        if (parentState != null) {
          for (final p in products) {
            parentState._productCache[p.id] = p;
          }
        }
      }
    } catch (e) {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!loading && products.isEmpty) return const SizedBox();

    return Column(
      children: [
        // Responsive Header
        Padding(
          padding: const EdgeInsets.only(bottom: 12, top: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  widget.category.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                    color: Colors.black87,
                  ),
                ),
              ),
              InkWell(
                onTap: widget.onSeeAll,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0, top: 4, bottom: 4),
                  child: Row(
                    children: const [
                      Text(
                        "View All",
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Icon(Icons.chevron_right, size: 16, color: accentColor),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Grid with Dynamic Aspect Ratio
        loading
            ? _buildShimmerGrid()
            : LayoutBuilder(
                builder: (context, constraints) {
                  double cardWidth = (constraints.maxWidth - 16) / 2;
                  double desiredHeight =
                      280; // Match your ProductCard height needs
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio:
                          cardWidth / desiredHeight, // Responsive Ratio
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
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

                          Get.snackbar(
                            'Added to catalog',
                            '"${product.name}" added to "$catalogueName".',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        },
                      );
                    },
                  );
                },
              ),

        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Divider(color: Colors.grey.shade200, thickness: 1),
        ),
      ],
    );
  }

  Widget _buildShimmerGrid() {
    return SizedBox(
      height: 200,
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.55,
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(
          2,
          (index) => Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}
