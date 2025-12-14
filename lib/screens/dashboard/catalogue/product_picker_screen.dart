import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import 'package:kakiso_reseller_app/controllers/catalouge_controller.dart';
import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/screens/dashboard/catalogue/catalouge_vertical_products_screen.dart';
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

  List<ProductModel> _products = [];
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// ✅ NEW: Uses paginated API helper so we truly load *all* products
  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await ApiService.fetchAllProductsPaginated(
        orderBy: 'date',
        order: 'desc',
      );
      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      debugPrint("Error loading products for picker: $e");
    }
  }

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
                  ? "Tap a product to add it to this catalog. $alreadyCount item${alreadyCount == 1 ? '' : 's'} already added."
                  : "Tap a product to add it to this catalog.",
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
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
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

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final catalogue = catalogueController.getById(widget.catalogueId);

      if (catalogue == null) {
        return Scaffold(
          backgroundColor: const Color(0xFFF9FAFB),
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
          body: const Center(child: Text("Catalog not found")),
        );
      }

      final alreadyInCatalogue = catalogue.products;
      final alreadyCount = alreadyInCatalogue.length;

      // Filter products by search
      final query = _searchQuery.trim().toLowerCase();
      final List<ProductModel> filteredProducts = query.isEmpty
          ? _products
          : _products
                .where((p) => p.name.toLowerCase().contains(query))
                .toList();

      final bool isSearchActive = query.isNotEmpty;

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
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: accentColor),
                    )
                  : _products.isEmpty
                  ? RefreshIndicator(
                      onRefresh: _loadProducts,
                      child: ListView(
                        physics:
                            const AlwaysScrollableScrollPhysics(), // to allow pull even if empty
                        children: const [
                          SizedBox(height: 120),
                          Center(
                            child: Text(
                              "No products found.",
                              style: TextStyle(fontFamily: 'Poppins'),
                            ),
                          ),
                        ],
                      ),
                    )
                  : filteredProducts.isEmpty && isSearchActive
                  // Search has no results
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Iconsax.search_normal_1,
                              size: 52,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "No matching products",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Try a different name or clear the search.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  // Main grid with pull-to-refresh
                  : RefreshIndicator(
                      onRefresh: _loadProducts,
                      child: GridView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredProducts.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.58,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                            ),
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          final bool isInCatalogue = alreadyInCatalogue.any(
                            (p) => p.id == product.id,
                          );

                          return Stack(
                            children: [
                              // Card (tap behaviour changes based on isInCatalogue)
                              CatalogueVerticalProductCard(
                                product: product,
                                onTap: () {
                                  if (isInCatalogue) {
                                    Get.snackbar(
                                      "Already added",
                                      "This product is already in this catalog.",
                                      snackPosition: SnackPosition.BOTTOM,
                                    );
                                  } else {
                                    catalogueController.addProductToCatalogue(
                                      widget.catalogueId,
                                      product,
                                    );
                                  }
                                },
                              ),

                              // Dim + badge if already in catalogue
                              if (isInCatalogue)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.55,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              if (isInCatalogue)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade600,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(
                                          Icons.check,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          "Added",
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontFamily: 'Poppins',
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
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
