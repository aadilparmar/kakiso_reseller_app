import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/screens/dashboard/home/widgets/search_header.dart';
import 'package:kakiso_reseller_app/services/api_services.dart';
import 'package:kakiso_reseller_app/utils/constants.dart';
// Import the header we just updated
// Import your Product Detail page

class ProductSearchScreen extends StatefulWidget {
  const ProductSearchScreen({super.key});

  @override
  State<ProductSearchScreen> createState() => _ProductSearchScreenState();
}

class _ProductSearchScreenState extends State<ProductSearchScreen> {
  List<ProductModel> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false; // To track if user has typed anything yet
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  // --- SEARCH LOGIC ---
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // 500ms delay to wait for user to stop typing
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        _performSearch(query);
      } else {
        setState(() {
          _searchResults = [];
          _hasSearched = false;
        });
      }
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      // Call your existing API Service
      final results = await ApiService.searchProducts(query);

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // Optional: Show error snackbar
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          "Search",
          style: TextStyle(color: Colors.black, fontFamily: 'Poppins'),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. The Search Bar (Writable Mode)
            SearchHeader(
              autoFocus: true, // Keyboard pops up immediately
              onSearchChanged: _onSearchChanged,
            ),
            const SizedBox(height: 10),

            // 2. The Results Area
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    // State 1: Loading
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: accentColor));
    }

    // State 2: No Search Yet (Initial State)
    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.search_normal, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 10),
            Text(
              "Type to search products",
              style: TextStyle(color: Colors.grey[500], fontFamily: 'Poppins'),
            ),
          ],
        ),
      );
    }

    // State 3: Searched but No Results
    if (_searchResults.isEmpty) {
      return Center(
        child: Text(
          "No products found",
          style: TextStyle(color: Colors.grey[600], fontFamily: 'Poppins'),
        ),
      );
    }

    // State 4: Show Results
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final product = _searchResults[index];

        // You can use a ListTile or your custom Card widget here
        return GestureDetector(
          onTap: () {
            // Navigate to Product Detail Page
            // Get.to(() => ProductDetailScreen(product: product));
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                // Image
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(12),
                  ),
                  child: Image.network(
                    product.image,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[200],
                      child: const Icon(Icons.error),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "₹${product.price}",
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Iconsax.arrow_right_3, color: Colors.grey),
                const SizedBox(width: 12),
              ],
            ),
          ),
        );
      },
    );
  }
}
