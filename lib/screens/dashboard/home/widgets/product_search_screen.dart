import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

// --- IMPORTS ---
import 'package:kakiso_reseller_app/models/categories.dart';
import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/screens/authentication/login/login.dart';
import 'package:kakiso_reseller_app/screens/dashboard/product/product_details_page.dart';
import 'package:kakiso_reseller_app/services/api_services.dart';

// SCREEN IMPORTS
import 'package:kakiso_reseller_app/screens/dashboard/home/widgets/search_header.dart';
import 'package:kakiso_reseller_app/screens/dashboard/categories/categories_detail_page/categories_detail_page.dart';

class UniversalSearchPage extends StatefulWidget {
  const UniversalSearchPage({super.key});

  @override
  State<UniversalSearchPage> createState() => _UniversalSearchPageState();
}

class _UniversalSearchPageState extends State<UniversalSearchPage> {
  // Data Store
  List<CategoryModel> _allCategoriesCache = [];
  List<SearchResultItem> _searchResults = [];

  // State
  bool _isLoading = false;
  bool _hasSearched = false;
  Timer? _debounce;

  // Controller
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _preloadCategories();
  }

  Future<void> _preloadCategories() async {
    try {
      final cats = await ApiService.fetchCategories();
      if (mounted) setState(() => _allCategoriesCache = cats);
    } catch (_) {}
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Increased debounce to 800ms to allow typing full 10-digit SKUs
    _debounce = Timer(const Duration(milliseconds: 800), () {
      if (query.trim().isNotEmpty) {
        _performHybridSearch(query);
      } else {
        setState(() {
          _searchResults = [];
          _hasSearched = false;
        });
      }
    });
  }

  // ─────────────────────────────────────────────────────────────
  //  🔥 HYBRID SEARCH ENGINE (Full 10-digit Support)
  // ─────────────────────────────────────────────────────────────
  Future<void> _performHybridSearch(String query) async {
    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    // Use the full trimmed query. No truncation.
    final cleanQuery = query.trim().toLowerCase();

    // 1. Ensure Cache is Populated
    if (_allCategoriesCache.isEmpty) {
      try {
        _allCategoriesCache = await ApiService.fetchCategories();
      } catch (_) {}
    }

    try {
      // 2. Prepare Parallel Search Tasks
      List<Future<List<ProductModel>>> tasks = [
        // A. Standard Search (Name, Description, partial SKU if indexed)
        ApiService.searchProducts(query),

        // B. SKU Search (EXACT match for full 10-digit codes)
        ApiService.fetchProductsBySku(query),
      ];

      // C. ID Search (Only if query is strictly numeric)
      // This helps if the user types "1402" expecting ID 1402
      if (int.tryParse(cleanQuery) != null) {
        tasks.add(
          ApiService.fetchProductByIdSafe(cleanQuery).then((product) {
            return product != null ? [product] : [];
          }),
        );
      }

      // 3. Execute All Searches
      final results = await Future.wait(tasks);

      // 4. Merge & Deduplicate Results
      final Map<int, ProductModel> uniqueProductsMap = {};

      for (var productList in results) {
        for (var product in productList) {
          // Use ID as key to prevent duplicates
          uniqueProductsMap[product.id] = product;
        }
      }

      List<ProductModel> allFoundProducts = uniqueProductsMap.values.toList();

      // 5. Build Result Map for UI
      final Map<int, SearchResultItem> finalResultsMap = {};

      // --- Match Categories by Name ---
      final matchingCats = _allCategoriesCache.where((cat) {
        return cat.name.toLowerCase().contains(cleanQuery);
      });
      for (var cat in matchingCats) {
        finalResultsMap[cat.id] = SearchResultItem(
          category: cat,
          matchType: MatchType.categoryName,
        );
      }

      // --- Process Products ---
      for (var product in allFoundProducts) {
        String matchLabel = product.name;
        bool isExactMatch = false;

        final String pId = product.id.toString();
        final String pSku = (product.userSku ?? '').toLowerCase();
        final String pCode = (product.uniqueCode ?? '').toLowerCase();

        // STRICT MATCHING LOGIC (No length limits)
        if (pId == cleanQuery) {
          matchLabel = "ID: $pId";
          isExactMatch = true;
        } else if (pSku == cleanQuery) {
          matchLabel = "SKU: ${product.userSku}";
          isExactMatch = true;
        } else if (pCode == cleanQuery) {
          matchLabel = "Code: ${product.uniqueCode}";
          isExactMatch = true;
        } else if (pSku.contains(cleanQuery)) {
          // Partial SKU match - Allowed for any length
          matchLabel = "SKU: ${product.userSku}";
          isExactMatch = true;
        }

        // Helper to add to map
        void addToMap(int key, CategoryModel cat, bool isVirtual) {
          SearchResultItem item =
              finalResultsMap[key] ??
              SearchResultItem(
                category: cat,
                matchType: MatchType.productContent,
                matchedProductExample: matchLabel,
                isExactMatch: isExactMatch,
                isVirtual: isVirtual,
              );

          if (isExactMatch) {
            item.isExactMatch = true;
            item.matchedProductExample = matchLabel;
          }

          // Add to preview list (avoid duplicates)
          if (!item.previewProducts.any((p) => p.id == product.id)) {
            item.previewProducts.add(product);
          }
          finalResultsMap[key] = item;
        }

        // A. Try to map to an existing category
        bool mapped = false;
        for (var catId in product.categoryIds) {
          final existingCat = _allCategoriesCache.firstWhereOrNull(
            (c) => c.id == catId,
          );
          if (existingCat != null) {
            mapped = true;
            addToMap(existingCat.id, existingCat, false);
            break;
          }
        }

        // B. Orphan Handling (Direct Product Match)
        if (!mapped) {
          final int fallbackId = product.categoryIds.isNotEmpty
              ? product.categoryIds.first
              : 0;
          final int uniqueKey = fallbackId == 0 ? -product.id : fallbackId;

          String title = isExactMatch ? "Direct Match" : "Other Results";

          final virtualCat = CategoryModel(
            id: fallbackId,
            name: title,
            imageUrl: product.image,
            count: 1,
            parent: 0,
          );
          addToMap(uniqueKey, virtualCat, true);
        }
      }

      if (mounted) {
        setState(() {
          _searchResults = finalResultsMap.values.toList();

          // SORTING: Exact Matches > Categories with Products > Empty Categories
          _searchResults.sort((a, b) {
            if (a.isExactMatch && !b.isExactMatch) return -1;
            if (!a.isExactMatch && b.isExactMatch) return 1;
            if (a.previewProducts.isNotEmpty && b.previewProducts.isEmpty)
              return -1;
            if (a.previewProducts.isEmpty && b.previewProducts.isNotEmpty)
              return 1;
            return 0;
          });

          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Search Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  UI BUILD
  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          "Discover",
          style: TextStyle(
            color: Colors.black,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.only(bottom: 12),
              child: SearchHeader(
                autoFocus: true,
                onSearchChanged: _onSearchChanged,
              ),
            ),
            Expanded(child: _buildResultList()),
          ],
        ),
      ),
    );
  }

  Widget _buildResultList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: kPrimaryDeep),
      );
    }
    if (!_hasSearched) {
      return _buildEmptyState(
        Iconsax.search_normal,
        "Search for anything",
        "Type 'Jewellery', 'Rings', or a Product ID.",
      );
    }
    if (_searchResults.isEmpty) {
      return _buildEmptyState(
        Iconsax.search_status,
        "No results found",
        "Try checking the ID or SKU.",
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      separatorBuilder: (context, index) => const SizedBox(height: 20),
      itemBuilder: (context, index) => _buildSectionCard(_searchResults[index]),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  SMART SECTION CARD UI
  // ─────────────────────────────────────────────────────────────
  Widget _buildSectionCard(SearchResultItem item) {
    final bool hasProducts = item.previewProducts.isNotEmpty;
    final bool isHighPriority = item.isExactMatch;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isHighPriority
            ? Border.all(color: kPrimaryDeep.withOpacity(0.4), width: 1.5)
            : Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          InkWell(
            onTap: () {
              if (item.isVirtual && item.previewProducts.isNotEmpty) {
                Get.to(
                  () => ProductDetailsPage(product: item.previewProducts.first),
                );
              } else {
                Get.to(
                  () => CategoryDetailsPage(
                    categoryId: item.category.id,
                    categoryName: item.category.name,
                  ),
                );
              }
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        item.category.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Iconsax.category, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                item.category.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            if (isHighPriority)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: kPrimaryDeep,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  "MATCH",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.matchedProductExample ?? "View category",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: isHighPriority
                                ? kPrimaryDeep
                                : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Icon(
                    Iconsax.arrow_right_3,
                    size: 16,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),

          if (hasProducts) const Divider(height: 1, color: Color(0xFFEEEEEE)),

          // PRODUCTS CAROUSEL
          if (hasProducts)
            SizedBox(
              height: 200,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                scrollDirection: Axis.horizontal,
                itemCount: item.previewProducts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return _buildMiniProductCard(item.previewProducts[index]);
                },
              ),
            ),
          if (!hasProducts) const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _buildMiniProductCard(ProductModel product) {
    return GestureDetector(
      onTap: () => Get.to(() => ProductDetailsPage(product: product)),
      child: Container(
        width: 130,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(13),
                ),
                child: Stack(
                  children: [
                    Container(
                      color: Colors.grey.shade50,
                      width: double.infinity,
                      height: double.infinity,
                      child: Image.network(
                        product.image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Iconsax.image, color: Colors.grey),
                        ),
                      ),
                    ),
                    if (product.userSku != null)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 2,
                            horizontal: 4,
                          ),
                          color: Colors.black.withOpacity(0.6),
                          child: Text(
                            "SKU: ${product.userSku}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "₹${product.price}",
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: kPrimaryDeep,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: Colors.grey[400]),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[800],
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
                fontFamily: 'Poppins',
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- HELPER CLASSES ---
enum MatchType { categoryName, productContent }

class SearchResultItem {
  final CategoryModel category;
  final MatchType matchType;
  String? matchedProductExample;
  bool isExactMatch;
  final bool isVirtual;
  final List<ProductModel> previewProducts = [];

  SearchResultItem({
    required this.category,
    required this.matchType,
    this.matchedProductExample,
    this.isExactMatch = false,
    this.isVirtual = false,
  });
}
