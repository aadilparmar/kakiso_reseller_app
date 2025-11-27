import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import 'package:kakiso_reseller_app/controllers/catalouge_controller.dart';
import 'package:kakiso_reseller_app/screens/dashboard/catalogue/catalouge_vertical_products_screen.dart';
import 'package:kakiso_reseller_app/screens/dashboard/catalogue/product_picker_screen.dart';
import 'package:kakiso_reseller_app/utils/constants.dart';

class CatalogueDetailsPage extends StatefulWidget {
  final String catalogueId;

  const CatalogueDetailsPage({super.key, required this.catalogueId});

  @override
  State<CatalogueDetailsPage> createState() => _CatalogueDetailsPageState();
}

class _CatalogueDetailsPageState extends State<CatalogueDetailsPage> {
  final CatalogueController controller = Get.find<CatalogueController>();

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  void _openProductPicker() {
    Get.to(() => ProductPickerScreen(catalogueId: widget.catalogueId));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      color: Colors.white,
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
                  hintText: "Search products in this catalogue...",
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
      final catalogue = controller.getById(widget.catalogueId);

      if (catalogue == null) {
        return Scaffold(
          appBar: AppBar(title: const Text("Catalogue")),
          body: const Center(child: Text("Catalogue not found")),
        );
      }

      // Filter products by search query
      final query = _searchQuery.trim().toLowerCase();
      final allProducts = catalogue.products;
      final filteredProducts = query.isEmpty
          ? allProducts
          : allProducts
                .where((p) => p.name.toLowerCase().contains(query))
                .toList();

      final hasProducts = allProducts.isNotEmpty;
      final isSearchActive = query.isNotEmpty;

      return Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Get.back(),
          ),
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                catalogue.name,
                style: const TextStyle(
                  color: Colors.black,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              Text(
                "${catalogue.products.length} item${catalogue.products.length == 1 ? '' : 's'}",
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontFamily: 'Poppins',
                  fontSize: 12,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Iconsax.add_circle, color: accentColor),
              tooltip: "Add Products",
              onPressed: _openProductPicker,
            ),
            const SizedBox(width: 4),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openProductPicker,
          backgroundColor: accentColor,
          icon: const Icon(Iconsax.add, color: Colors.white),
          label: const Text(
            "Add Products",
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: Column(
          children: [
            _buildSearchBar(),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            Expanded(
              child: !hasProducts
                  // 🌥 REAL EMPTY STATE (no products at all)
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Iconsax.box_remove,
                            size: 60,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "No products in this catalogue.",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Tap \"Add Products\" to start adding items.",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : filteredProducts.isEmpty && isSearchActive
                  // 🔍 SEARCH EMPTY STATE
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
                              "Try another name or clear the search.",
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
                  // 🧾 GRID OF PRODUCTS
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredProducts.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.52,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                          ),
                      itemBuilder: (context, index) {
                        final product = filteredProducts[index];
                        return Stack(
                          children: [
                            CatalogueVerticalProductCard(product: product),
                            Positioned(
                              top: 6,
                              right: 6,
                              child: GestureDetector(
                                onTap: () {
                                  controller.removeProductFromCatalogue(
                                    widget.catalogueId,
                                    product.id.toString(), // ✅ FIXED
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.9),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      );
    });
  }
}
