import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kakiso_reseller_app/controllers/catalouge_controller.dart';
import 'package:kakiso_reseller_app/controllers/cart_controller.dart';

// --- MODELS & SERVICES ---
import 'package:kakiso_reseller_app/models/categories.dart';
import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/models/user.dart';
import 'package:kakiso_reseller_app/screens/dashboard/categories/categories_detail_page/widgets/vertical_product_card_categories.dart';
import 'package:kakiso_reseller_app/screens/dashboard/home/home_screen.dart';
import 'package:kakiso_reseller_app/services/api_services.dart';
import 'package:kakiso_reseller_app/utils/constants.dart';

// --- WIDGET IMPORTS ---
import 'package:kakiso_reseller_app/screens/dashboard/categories/widgets/left_nav_rail.dart';
import 'package:kakiso_reseller_app/screens/dashboard/categories/widgets/search_and_filter_bar.dart';
import 'package:kakiso_reseller_app/screens/dashboard/my_cart/my_cart.dart';
import 'package:kakiso_reseller_app/screens/dashboard/home/widgets/home_drawer.dart';
import 'package:kakiso_reseller_app/screens/authentication/login/login.dart';

class CategoriesSection extends StatefulWidget {
  final UserData userData;

  const CategoriesSection({super.key, required this.userData});

  @override
  State<CategoriesSection> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesSection>
    with TickerProviderStateMixin {
  // --- STATE VARIABLES ---
  bool isCategoriesLoading = true;
  bool isProductsLoading = false;

  // Animation Controller for "Waterfall" entry
  late AnimationController _fadeInController;

  List<CategoryModel> _allCategories = [];
  List<ProductModel> _categoryProducts = [];
  List<ProductModel> _displayedProducts = [];
  final Set<int> _selectedProductIds = {};

  String? errorMessage;
  int selectedIndex = 0;
  String selectedCategoryLabel = 'All';
  int selectedCategoryId = 0;

  // --- FILTER & SORT STATE ---
  final TextEditingController _searchController = TextEditingController();

  String _orderBy = 'popularity';
  String _order = 'desc';
  RangeValues _currentPriceRange = const RangeValues(0, 20000);
  final double _maxFilterLimit = 20000;

  final _storage = const FlutterSecureStorage();
  final catalogueController = Get.put(CatalogueController(), permanent: true);
  final CartController cartController = Get.find<CartController>();

  @override
  void initState() {
    super.initState();
    _fadeInController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _loadCategories();
  }

  @override
  void dispose() {
    _fadeInController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // 1. Load Categories
  Future<void> _loadCategories() async {
    try {
      final cats = await ApiService.fetchCategories();
      if (mounted) {
        setState(() {
          _allCategories = cats;
          isCategoriesLoading = false;
          if (cats.isNotEmpty) {
            selectedCategoryLabel = cats[0].name;
            selectedCategoryId = cats[0].id;
            _loadProductsForCategory(selectedCategoryId);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isCategoriesLoading = false;
          errorMessage = e.toString();
        });
      }
    }
  }

  // 2. Load Products with Waterfall Effect
  Future<void> _loadProductsForCategory(int categoryId) async {
    setState(() {
      isProductsLoading = true;
      _categoryProducts = [];
      _displayedProducts = [];
      _selectedProductIds.clear();
    });

    try {
      final products = await ApiService.fetchProductsByCategory(
        categoryId,
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
          _categoryProducts = products;
          _onSearchChanged();
          isProductsLoading = false;
        });
        _fadeInController.forward(from: 0); // Restart animation
      }
    } catch (e) {
      if (mounted) {
        setState(() => isProductsLoading = false);
      }
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _displayedProducts = List.from(_categoryProducts);
      } else {
        _displayedProducts = _categoryProducts.where((p) {
          return p.name.toLowerCase().contains(query);
        }).toList();
      }
      // Clean up selection
      _selectedProductIds.removeWhere(
        (id) => !_displayedProducts.any((p) => p.id == id),
      );
    });
  }

  // --- SELECTION LOGIC ---
  void _toggleSelectAll() {
    final bool allSelected =
        _displayedProducts.isNotEmpty &&
        _displayedProducts.every((p) => _selectedProductIds.contains(p.id));

    setState(() {
      if (allSelected) {
        _selectedProductIds.clear();
      } else {
        _selectedProductIds.addAll(_displayedProducts.map((p) => p.id));
      }
    });
    HapticFeedback.lightImpact();
  }

  // --- QUICK FILTERS ---
  void _applyQuickFilter(String type) {
    HapticFeedback.selectionClick();
    setState(() {
      if (type == 'Under500') {
        _currentPriceRange = const RangeValues(0, 500);
      } else if (type == 'New') {
        _orderBy = 'date';
        _order = 'desc';
      } else if (type == 'Premium') {
        _orderBy = 'price';
        _order = 'desc';
      }
    });
    _loadProductsForCategory(selectedCategoryId);
  }

  // --- DRAWER & UI HELPERS ---
  void _handleDrawerNavigation(String pageId) {
    Navigator.pop(context);
    if (pageId == 'Home' || pageId == 'BusinessDetails') {
      Get.off(() => HomePage(userData: widget.userData));
    }
  }

  Future<void> _showLogoutConfirmation() async {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        title: const Text('Logout', style: TextStyle(fontFamily: 'Poppins')),
        content: const Text(
          'Do you want to log out?',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Get.back();
              await _storage.delete(key: 'authToken');
              Get.offAll(() => const LoginPage());
            },
            child: const Text('Logout', style: TextStyle(color: accentColor)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isAllSelected =
        _displayedProducts.isNotEmpty &&
        _displayedProducts.every((p) => _selectedProductIds.contains(p.id));

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: HomeDrawer(
        userData: widget.userData,
        selectedTitle: 'Categories',
        onNavigate: _handleDrawerNavigation,
        onLogoutPressed: _showLogoutConfirmation,
      ),
      // --- 1. RESTORED APP BAR (Always Visible) ---
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Iconsax.menu_1, color: Colors.black87),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 4.0),
              child: Image.asset(
                'assets/logos/login-logo.png',
                height: 22,
                fit: BoxFit.contain,
              ),
            ),
            const Spacer(),
            // Cart Icon with Badge
            Obx(() {
              final count = cartController.itemCount;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(
                      Iconsax.shopping_bag,
                      color: Colors.black87,
                    ),
                    onPressed: () => Get.to(() => const InventoryPage()),
                  ),
                  if (count > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
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
                      ),
                    ),
                ],
              );
            }),
          ],
        ),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- 2. LEFT NAVIGATION RAIL ---
          if (!isCategoriesLoading && errorMessage == null)
            LeftNavigationRail(
              categories: _allCategories,
              selectedIndex: selectedIndex,
              onCategorySelected: (index, label, id) {
                setState(() {
                  selectedIndex = index;
                  selectedCategoryLabel = label;
                  selectedCategoryId = id;
                });
                _loadProductsForCategory(id);
              },
            ),

          // --- 3. MAIN CONTENT (Search + Grid) ---
          Expanded(
            child: Container(
              color: const Color(0xFFFAFAFA),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // --- SEARCH & FILTERS (Standard Column, No Slivers) ---
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: Column(
                          children: [
                            SearchAndFilterBar(
                              controller: _searchController,
                              onChanged: _onSearchChanged,
                              onClear: () {
                                _searchController.clear();
                                _onSearchChanged();
                              },
                              onFilter: _openFilterSheet,
                            ),
                            const SizedBox(height: 12),
                            // Quick Filter Chips
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  ActionChip(
                                    avatar: Icon(
                                      isAllSelected
                                          ? Iconsax.tick_circle
                                          : Iconsax.add_circle,
                                      size: 16,
                                      color: isAllSelected
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                    label: const Text("Select All"),
                                    backgroundColor: isAllSelected
                                        ? accentColor
                                        : Colors.grey.shade100,
                                    labelStyle: TextStyle(
                                      color: isAllSelected
                                          ? Colors.white
                                          : Colors.black87,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      side: BorderSide.none,
                                    ),
                                    onPressed: _toggleSelectAll,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildQuickFilterChip(
                                    "Under ₹500",
                                    () => _applyQuickFilter('Under500'),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildQuickFilterChip(
                                    "New Arrivals",
                                    () => _applyQuickFilter('New'),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildQuickFilterChip(
                                    "Premium",
                                    () => _applyQuickFilter('Premium'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // --- PRODUCT GRID ---
                      Expanded(
                        child: isProductsLoading
                            ? _buildShimmerGrid()
                            : _displayedProducts.isEmpty
                            ? _buildEmptyState()
                            : _buildProductGrid(),
                      ),
                    ],
                  ),

                  // --- 4. FLOATING "DYNAMIC ISLAND" ACTION BAR ---
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutBack,
                    bottom: _selectedProductIds.isNotEmpty ? 30 : -100,
                    left: 20,
                    right: 20,
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 400),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(40),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Counter Bubble
                            Container(
                              width: 36,
                              height: 36,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${_selectedProductIds.length}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
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
                            const SizedBox(width: 16),
                            Container(
                              height: 20,
                              width: 1,
                              color: Colors.white24,
                            ),
                            const SizedBox(width: 8),

                            // Clear Button
                            IconButton(
                              icon: const Icon(
                                Iconsax.close_circle,
                                color: Colors.white54,
                              ),
                              onPressed: () {
                                setState(() => _selectedProductIds.clear());
                                HapticFeedback.lightImpact();
                              },
                            ),

                            // Add Button
                            Padding(
                              padding: const EdgeInsets.only(right: 4.0),
                              child: ElevatedButton(
                                onPressed: _onAddSelectedToCatalogue,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accentColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  elevation: 0,
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Iconsax.add, size: 18),
                                    SizedBox(width: 6),
                                    Text("Catalog"),
                                  ],
                                ),
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
          ),
        ],
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildQuickFilterChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildProductGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        120,
      ), // Bottom padding for floating bar
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.55,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemCount: _displayedProducts.length,
      itemBuilder: (context, index) {
        final product = _displayedProducts[index];
        final isSelected = _selectedProductIds.contains(product.id);

        return AnimatedBuilder(
          animation: _fadeInController,
          builder: (context, child) {
            final double delay = (index * 0.05).clamp(0.0, 1.0);
            final double start = delay;
            final double end = (delay + 0.3).clamp(0.0, 1.0);

            final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _fadeInController,
                curve: Interval(start, end, curve: Curves.easeOut),
              ),
            );

            final slideAnimation =
                Tween<Offset>(
                  begin: const Offset(0, 0.1),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _fadeInController,
                    curve: Interval(start, end, curve: Curves.easeOut),
                  ),
                );

            return FadeTransition(
              opacity: fadeAnimation,
              child: SlideTransition(position: slideAnimation, child: child),
            );
          },
          child: VerticalProductCard(
            product: product,
            availableCatalogues: catalogueController.catalogueNames,
            isSelected: isSelected,
            onSelectionToggle: () {
              HapticFeedback.selectionClick();
              setState(() {
                if (isSelected) {
                  _selectedProductIds.remove(product.id);
                } else {
                  _selectedProductIds.add(product.id);
                }
              });
            },
            onCatalogueSelected: (p, name, isNew) {
              if (isNew) {
                catalogueController.createCatalogueAndAddProduct(name, p);
              } else {
                catalogueController.addProductToExistingCatalogue(name, p);
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.55,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _ShimmerBlock(borderRadius: 16)),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: _ShimmerBlock(height: 14, width: 100),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: _ShimmerBlock(height: 14, width: 60),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Iconsax.search_status,
              size: 48,
              color: Colors.grey.shade300,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "No products found",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Try adjusting your filters",
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  // --- BOTTOM SHEETS (FILTER & CATALOG) ---
  void _openFilterSheet() {
    RangeValues tempRange = _currentPriceRange;
    String tempOrderBy = _orderBy;
    String tempOrder = _order;

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
                      "Sort & Filter",
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
                          tempOrderBy = 'popularity';
                          tempOrder = 'desc';
                        });
                      },
                      child: const Text(
                        "Reset",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  "Sort By",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildFilterSheetChip(
                      "Popular",
                      'popularity',
                      'desc',
                      tempOrderBy,
                      tempOrder,
                      setModalState,
                      (s, o) {
                        tempOrderBy = s;
                        tempOrder = o;
                      },
                    ),
                    _buildFilterSheetChip(
                      "Newest",
                      'date',
                      'desc',
                      tempOrderBy,
                      tempOrder,
                      setModalState,
                      (s, o) {
                        tempOrderBy = s;
                        tempOrder = o;
                      },
                    ),
                    _buildFilterSheetChip(
                      "Price: Low-High",
                      'price',
                      'asc',
                      tempOrderBy,
                      tempOrder,
                      setModalState,
                      (s, o) {
                        tempOrderBy = s;
                        tempOrder = o;
                      },
                    ),
                    _buildFilterSheetChip(
                      "Price: High-Low",
                      'price',
                      'desc',
                      tempOrderBy,
                      tempOrder,
                      setModalState,
                      (s, o) {
                        tempOrderBy = s;
                        tempOrder = o;
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  "Price Range",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
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
                  inactiveColor: accentColor.withValues(alpha: 0.2),
                  onChanged: (values) =>
                      setModalState(() => tempRange = values),
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
                      setState(() {
                        _currentPriceRange = tempRange;
                        _orderBy = tempOrderBy;
                        _order = tempOrder;
                        _selectedProductIds.clear();
                      });
                      Get.back();
                      _loadProductsForCategory(selectedCategoryId);
                    },
                    child: const Text(
                      "Apply",
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
      isScrollControlled: true,
    );
  }

  Widget _buildFilterSheetChip(
    String label,
    String apiSort,
    String apiOrder,
    String currentSort,
    String currentOrder,
    StateSetter setModalState,
    Function(String, String) onTap,
  ) {
    final bool isSelected =
        (currentSort == apiSort && currentOrder == apiOrder);
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setModalState(() => onTap(apiSort, apiOrder));
      },
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      selectedColor: accentColor,
      backgroundColor: Colors.grey.shade100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? accentColor : Colors.transparent),
      ),
    );
  }

  void _onAddSelectedToCatalogue() {
    if (_selectedProductIds.isEmpty) return;
    final selectedProducts = _displayedProducts
        .where((p) => _selectedProductIds.contains(p.id))
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final availableCatalogues = catalogueController.catalogueNames;
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
                'Add ${selectedProducts.length} items to catalog',
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
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                )
              else
                ...availableCatalogues.map(
                  (name) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
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
                    trailing: const Icon(
                      Iconsax.add_circle,
                      color: accentColor,
                    ),
                    onTap: () {
                      for (final p in selectedProducts)
                        catalogueController.addProductToExistingCatalogue(
                          name,
                          p,
                        );
                      Navigator.pop(ctx);
                      setState(() => _selectedProductIds.clear());
                      Get.snackbar(
                        'Added',
                        'Products added to $name',
                        backgroundColor: Colors.green.shade50,
                        colorText: Colors.green.shade800,
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
                    _showCreateNewCatalogueDialogForSelected(selectedProducts);
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
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCreateNewCatalogueDialogForSelected(
    List<ProductModel> selectedProducts,
  ) {
    final TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'New Catalog',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500),
        ),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Catalog Name',
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
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
              if (nameController.text.isNotEmpty) {
                catalogueController.createCatalogueAndAddProduct(
                  nameController.text,
                  selectedProducts.first,
                );
                for (int i = 1; i < selectedProducts.length; i++)
                  catalogueController.addProductToExistingCatalogue(
                    nameController.text,
                    selectedProducts[i],
                  );
                Navigator.pop(ctx);
                setState(() => _selectedProductIds.clear());
                Get.snackbar(
                  'Created',
                  'Catalog created successfully',
                  backgroundColor: Colors.green.shade50,
                  colorText: Colors.green.shade800,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

// --- SHIMMER ANIMATION WIDGET ---
class _ShimmerBlock extends StatefulWidget {
  final double? height;
  final double? width;
  final double borderRadius;
  const _ShimmerBlock({this.height, this.width, this.borderRadius = 8});
  @override
  State<_ShimmerBlock> createState() => _ShimmerBlockState();
}

class _ShimmerBlockState extends State<_ShimmerBlock>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              colors: [
                Colors.grey.shade200,
                Colors.grey.shade100,
                Colors.grey.shade200,
              ],
              stops: const [0.1, 0.5, 0.9],
              begin: Alignment(-1.0 + (_controller.value * 2), -0.3),
              end: Alignment(1.0 + (_controller.value * 2), 0.3),
            ),
          ),
        );
      },
    );
  }
}
