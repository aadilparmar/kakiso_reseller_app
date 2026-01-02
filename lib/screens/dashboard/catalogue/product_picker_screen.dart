import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_auto_translate/flutter_auto_translate.dart';

import 'package:kakiso_reseller_app/controllers/catalouge_controller.dart';
import 'package:kakiso_reseller_app/models/categories.dart';
import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/services/api_services.dart';
import 'package:kakiso_reseller_app/utils/constants.dart';

class ProductPickerScreen extends StatefulWidget {
  final String catalogueId;

  const ProductPickerScreen({super.key, required this.catalogueId});

  @override
  State<ProductPickerScreen> createState() => _ProductPickerScreenState();
}

class _ProductPickerScreenState extends State<ProductPickerScreen> {
  final CatalogueController catalogueController =
      Get.find<CatalogueController>();

  // --- OPTIMIZED STATE MANAGEMENT ---
  final List<ProductModel> _products = [];
  List<CategoryModel> _categories = [];

  bool _isLoading = true;
  bool _isLoadingCategories = true;
  bool _isLoadingMore = false;

  // Pagination
  int _activeCategoryId = 0; // 0 = All
  bool _hasMore = true;

  // Scroll Controller
  final ScrollController _scrollController = ScrollController();

  // Search
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // OPTIMIZATION: Fire both requests. Don't await one to start the other.
    _fetchCategories();
    _loadProducts(refresh: true);

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // OPTIMIZATION: Increased threshold to 500.
    // Loads next page BEFORE user hits bottom.
    if (_scrollController.hasClients &&
        _scrollController.position.extentAfter < 500 &&
        !_isLoading &&
        !_isLoadingMore &&
        _hasMore) {
      _loadProducts(refresh: false);
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final cats = await ApiService.fetchCategories();
      if (mounted) {
        setState(() {
          _categories = cats;
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingCategories = false);
    }
  }

  Future<void> _loadProducts({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _isLoading = true;
        _hasMore = true;
        _products.clear();
      });
    } else {
      if (_isLoadingMore) return; // Prevent double firing
      setState(() => _isLoadingMore = true);
    }

    try {
      List<ProductModel> newProducts = [];

      // OPTIMIZATION: Minimal logic inside the async gap
      if (_activeCategoryId == 0) {
        newProducts = await ApiService.fetchAllProductsPaginated(
          perPage: 20,
          orderBy: 'date',
          order: 'desc',
        );
      } else {
        newProducts = await ApiService.fetchProductsByCategory(
          _activeCategoryId,
          // page: _page, // Add this if your API supports category pagination
        );
      }

      if (mounted) {
        setState(() {
          if (newProducts.isEmpty) {
            _hasMore = false;
          } else {
            _products.addAll(newProducts);
          }
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  void _onCategorySelected(int id) {
    if (_activeCategoryId == id) return;
    HapticFeedback.selectionClick();
    setState(() {
      _activeCategoryId = id;
    });
    // Immediate reload for new category
    _loadProducts(refresh: true);
  }

  // --- UI COMPONENTS ---

  Widget _buildInfoBanner(int alreadyCount) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Iconsax.info_circle, size: 18, color: accentColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              alreadyCount > 0
                  ? "Tap 'Add' to include products. $alreadyCount item${alreadyCount == 1 ? '' : 's'} already added."
                  : "Tap 'Add' to include products in this catalog.",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const SizedBox(width: 10),
            const Icon(Iconsax.search_normal_1, size: 18, color: Colors.grey),
            const SizedBox(width: 6),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: const InputDecoration(
                  hintText: "Search products...",
                  border: InputBorder.none,
                  isDense: true,
                ),
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryList() {
    if (_isLoadingCategories && _categories.isEmpty) {
      // Shimmer or empty placeholder could go here
      return const SizedBox(height: 110);
    }

    return Container(
      height: 110,
      width: double.infinity,
      color: Colors.white,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          if (index == 0) {
            final isSelected = _activeCategoryId == 0;
            return GestureDetector(
              onTap: () => _onCategorySelected(0),
              child: _buildCategoryItem(
                isSelected: isSelected,
                label: "All",
                icon: Iconsax.category,
              ),
            );
          }

          final cat = _categories[index - 1];
          final isSelected = _activeCategoryId == cat.id;

          return GestureDetector(
            onTap: () => _onCategorySelected(cat.id),
            child: _buildCategoryItem(
              isSelected: isSelected,
              label: cat.name,
              imageUrl: cat.imageUrl,
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryItem({
    required bool isSelected,
    required String label,
    IconData? icon,
    String? imageUrl,
  }) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 60,
          width: 60,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: (icon != null && isSelected) ? accentColor : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? accentColor : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
            image: (imageUrl != null && imageUrl.isNotEmpty)
                ? DecorationImage(
                    // OPTIMIZATION: Cache small icons
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: icon != null
              ? Icon(
                  icon,
                  size: 24,
                  color: isSelected ? Colors.white : Colors.black87,
                )
              : (imageUrl == null || imageUrl.isEmpty)
              ? const Icon(Iconsax.image)
              : null,
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 60,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? accentColor : Colors.black54,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final catalogue = catalogueController.getById(widget.catalogueId);

      if (catalogue == null) {
        return Scaffold(
          backgroundColor: const Color(0xFFF9FAFB),
          appBar: AppBar(title: const Text("Select Products")),
          body: const Center(child: Text("Catalog not found")),
        );
      }

      final alreadyInCatalogue = catalogue.products;
      final alreadyCount = alreadyInCatalogue.length;

      // Search Filtering (Local)
      final query = _searchQuery.trim().toLowerCase();
      final List<ProductModel> displayedList = query.isEmpty
          ? _products
          : _products
                .where((p) => p.name.toLowerCase().contains(query))
                .toList();

      return Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Get.back(),
          ),
          title: const Text(
            "Select Products",
            style: TextStyle(
              color: Colors.black,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: Column(
          children: [
            _buildInfoBanner(alreadyCount),
            _buildSearchBar(),
            _buildCategoryList(),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),

            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: accentColor),
                    )
                  : displayedList.isEmpty
                  ? RefreshIndicator(
                      onRefresh: () async => _loadProducts(refresh: true),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 100),
                          Center(
                            child: Column(
                              children: [
                                Icon(
                                  Iconsax.box_remove,
                                  size: 50,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  "No products found.",
                                  style: TextStyle(fontFamily: 'Poppins'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async => _loadProducts(refresh: true),
                      child: GridView.builder(
                        controller: _scrollController,
                        // OPTIMIZATION: Pre-calculate count to avoid jitter
                        itemCount:
                            displayedList.length + (_isLoadingMore ? 2 : 0),
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.58,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                            ),
                        itemBuilder: (context, index) {
                          if (index >= displayedList.length) {
                            return const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: accentColor,
                              ),
                            );
                          }

                          final product = displayedList[index];
                          final bool isInCatalogue = alreadyInCatalogue.any(
                            (p) => p.id == product.id,
                          );

                          // OPTIMIZATION: RepaintBoundary stops the card from
                          // redrawing when other parts of the screen update.
                          return RepaintBoundary(
                            child: _PickerProductCard(
                              product: product,
                              isAdded: isInCatalogue,
                              onTap: () {
                                if (isInCatalogue) {
                                  HapticFeedback.lightImpact();
                                  Get.snackbar(
                                    "Already Added",
                                    "Product is already in catalog.",
                                    snackPosition: SnackPosition.BOTTOM,
                                    backgroundColor: Colors.black.withOpacity(
                                      0.8,
                                    ),
                                    colorText: Colors.white,
                                    margin: const EdgeInsets.all(16),
                                    borderRadius: 12,
                                    duration: const Duration(
                                      milliseconds: 1500,
                                    ),
                                  );
                                } else {
                                  HapticFeedback.selectionClick();
                                  catalogueController.addProductToCatalogue(
                                    widget.catalogueId,
                                    product,
                                  );
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────
//  LOCAL WIDGET: RICH CARD (OPTIMIZED)
// ─────────────────────────────────────────────────────────────
class _PickerProductCard extends StatelessWidget {
  final ProductModel product;
  final bool isAdded;
  final VoidCallback onTap;

  const _PickerProductCard({
    required this.product,
    required this.isAdded,
    required this.onTap,
  });

  // CONSTANTS
  static const Color kPrimaryColor = Color(0xFF4A317E);
  static const Color kAccentColor = Color(0xFFEB2A7E);
  static const Color kGreen = Color(0xFF16A34A);
  static const Color kBlack = Color(0xFF1F2937);

  double? _parsePrice(String value) {
    try {
      final cleaned = value.replaceAll(RegExp(r'[^0-9.]'), '');
      if (cleaned.isEmpty) return null;
      return double.parse(cleaned);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Logic
    final double? basePrice = _parsePrice(product.price);
    final double? resellPrice = basePrice != null ? (basePrice * 1.3) : null;
    final double? mrpPrice = product.regularPrice.isNotEmpty
        ? _parsePrice(product.regularPrice)
        : null;
    final double? profit = (resellPrice != null && basePrice != null)
        ? (resellPrice - basePrice)
        : null;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isAdded ? kGreen : Colors.grey.withOpacity(0.2),
            width: isAdded ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isAdded
                  ? kGreen.withOpacity(0.15)
                  : Colors.black.withOpacity(0.05),
              blurRadius: isAdded ? 12 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. IMAGE SECTION (65%)
              Expanded(
                flex: 65,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // OPTIMIZATION: cacheWidth 350
                    // This forces Flutter to decode image at smaller size (thumbnail)
                    // saving MASSIVE amounts of RAM and GPU work on scrolling.
                    Image.network(
                      product.image,
                      fit: BoxFit.cover,
                      cacheWidth: 350,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade100,
                        child: const Icon(Iconsax.image, color: Colors.grey),
                      ),
                      loadingBuilder: (ctx, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(color: Colors.grey.shade50);
                      },
                    ),

                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.1),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    if (isAdded)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: kGreen,
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),

                    if (product.discountPercentage != null &&
                        product.discountPercentage! > 0)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: kAccentColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            "${product.discountPercentage}% OFF",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // 2. DETAILS SECTION (35%)
              Expanded(
                flex: 35,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: SizedBox(
                                width: constraints.maxWidth,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: kBlack,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const AutoTranslate(
                                          child: Text(
                                            "Buy ",
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF6B7280),
                                            ),
                                          ),
                                        ),
                                        Text(
                                          "₹${product.price}",
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: kPrimaryColor,
                                          ),
                                        ),
                                        if (mrpPrice != null &&
                                            mrpPrice != basePrice) ...[
                                          const SizedBox(width: 6),
                                          Text(
                                            "₹${mrpPrice.toStringAsFixed(0)}",
                                            style: TextStyle(
                                              fontSize: 13,
                                              decoration:
                                                  TextDecoration.lineThrough,
                                              color: Colors.grey.shade400,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const AutoTranslate(
                                          child: Text(
                                            "Resell ",
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF88878B),
                                            ),
                                          ),
                                        ),
                                        Text(
                                          "₹${resellPrice?.toStringAsFixed(0)}",
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF88878B),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        if (profit != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFDCFCE7),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Iconsax.trend_up,
                                                  size: 10,
                                                  color: kGreen,
                                                ),
                                                const SizedBox(width: 2),
                                                Text(
                                                  "+₹${profit.toStringAsFixed(0)}",
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: kGreen,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        height: 32,
                        child: ElevatedButton(
                          onPressed: onTap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isAdded ? kGreen : kPrimaryColor,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: isAdded
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.check,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      "Added",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                )
                              : const Text(
                                  "Add",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
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
        ),
      ),
    );
  }
}
