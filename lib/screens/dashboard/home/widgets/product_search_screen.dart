import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

// --- IMPORTS ---
import 'package:kakiso_reseller_app/models/categories.dart';
import 'package:kakiso_reseller_app/screens/dashboard/home/widgets/search_header.dart';
import 'package:kakiso_reseller_app/screens/dashboard/categories/categories_detail_page/categories_detail_page.dart';
import 'package:kakiso_reseller_app/services/api_services.dart';
import 'package:kakiso_reseller_app/utils/constants.dart';

class UniversalSearchPage extends StatefulWidget {
  const UniversalSearchPage({super.key});

  @override
  State<UniversalSearchPage> createState() => _UniversalSearchPageState();
}

class _UniversalSearchPageState extends State<UniversalSearchPage> {
  // Data Store
  List<CategoryModel> _allCategoriesCache = [];

  // Results
  List<SearchResultItem> _searchResults = [];

  // State
  bool _isLoading = false;
  bool _hasSearched = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _preloadCategories();
  }

  // 1. Fetch Categories for Mapping
  Future<void> _preloadCategories() async {
    try {
      final cats = await ApiService.fetchCategories();
      if (mounted) {
        setState(() {
          _allCategoriesCache = cats;
        });
      }
    } catch (_) {
      // Fail silently, will retry during search
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  // --- SEARCH ENGINE ---
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (query.trim().isNotEmpty) {
        _performSmartSearch(query);
      } else {
        setState(() {
          _searchResults = [];
          _hasSearched = false;
        });
      }
    });
  }

  Future<void> _performSmartSearch(String query) async {
    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      // Ensure we have categories for lookup
      if (_allCategoriesCache.isEmpty) {
        _allCategoriesCache = await ApiService.fetchCategories();
      }

      final lowercaseQuery = query.toLowerCase();
      // Using a Map ensures we don't show the same category twice
      final Map<int, SearchResultItem> uniqueResultsMap = {};

      // ---------------------------------------------------------
      // A. Match Category Names DIRECTLY
      // ---------------------------------------------------------
      final matchingCategories = _allCategoriesCache.where((cat) {
        return cat.name.toLowerCase().contains(lowercaseQuery);
      });

      for (var cat in matchingCategories) {
        uniqueResultsMap[cat.id] = SearchResultItem(
          category: cat,
          matchType: MatchType.categoryName,
        );
      }

      // ---------------------------------------------------------
      // B. Match Product Names -> Link to ALL Categories
      // ---------------------------------------------------------
      final matchingProducts = await ApiService.searchProducts(query);

      for (var product in matchingProducts) {
        // Iterate through ALL category IDs this product belongs to
        for (var catId in product.categoryIds) {
          final parentCategory = _allCategoriesCache.firstWhereOrNull(
            (c) => c.id == catId,
          );

          if (parentCategory != null) {
            // If this category is NOT in the list yet, add it.
            // If it IS in the list (e.g. from name match), we keep the name match
            // as it is usually more relevant, or update if you prefer.
            if (!uniqueResultsMap.containsKey(parentCategory.id)) {
              uniqueResultsMap[parentCategory.id] = SearchResultItem(
                category: parentCategory,
                matchType: MatchType.productContent,
                matchedProductExample: product.name,
              );
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          // Convert map to list
          _searchResults = uniqueResultsMap.values.toList();

          // Optional: Sort results. Direct Name matches first, then Product matches.
          _searchResults.sort((a, b) {
            if (a.matchType == b.matchType) return 0;
            return a.matchType == MatchType.categoryName ? -1 : 1;
          });

          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Search Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
            SearchHeader(autoFocus: true, onSearchChanged: _onSearchChanged),
            const SizedBox(height: 12),
            Expanded(child: _buildResultList()),
          ],
        ),
      ),
    );
  }

  Widget _buildResultList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: accentColor));
    }

    if (!_hasSearched) {
      return _buildEmptyState(
        icon: Iconsax.search_normal,
        title: "Search for anything",
        subtitle: "Type 'Jewellery', 'Rings', or a specific product name.",
      );
    }

    if (_searchResults.isEmpty) {
      return _buildEmptyState(
        icon: Iconsax.search_status,
        title: "No results found",
        subtitle: "Try using different keywords.",
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _searchResults.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _searchResults[index];
        return _buildResultCard(item);
      },
    );
  }

  Widget _buildResultCard(SearchResultItem item) {
    final bool isProductMatch = item.matchType == MatchType.productContent;

    return GestureDetector(
      onTap: () {
        Get.to(
          () => CategoryDetailsPage(
            categoryId: item.category.id,
            categoryName: item.category.name,
          ),
          transition: Transition.fadeIn,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Category Image
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    item.category.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      Iconsax.folder,
                      color: Colors.grey.shade300,
                      size: 24,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.category.name,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),

                    if (isProductMatch && item.matchedProductExample != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "Contains \"${item.matchedProductExample}\"",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: accentColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    else
                      Text(
                        "${item.category.count} items",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                  ],
                ),
              ),

              const Icon(Iconsax.arrow_right_3, color: Colors.grey, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
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
                height: 1.5,
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
  final String? matchedProductExample;

  SearchResultItem({
    required this.category,
    required this.matchType,
    this.matchedProductExample,
  });
}
