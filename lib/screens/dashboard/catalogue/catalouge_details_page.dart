import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_auto_translate/flutter_auto_translate.dart';

import 'package:kakiso_reseller_app/controllers/catalouge_controller.dart';
import 'package:kakiso_reseller_app/models/product.dart';
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
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: const InputDecoration(
                  hintText: "Search products in this catalog...",
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
          appBar: AppBar(title: const Text("Catalog")),
          body: const Center(child: Text("Catalog not found")),
        );
      }

      final query = _searchQuery.trim().toLowerCase();
      final allProducts = catalogue.products;
      final filteredProducts = query.isEmpty
          ? allProducts
          : allProducts
                .where((p) => p.name.toLowerCase().contains(query))
                .toList();

      final hasProducts = allProducts.isNotEmpty;
      final isSearchActive = query.isNotEmpty;

      // RESPONSIVE CALCULATIONS
      final size = MediaQuery.of(context).size;
      final textScale = MediaQuery.of(context).textScaleFactor;

      int crossAxisCount = size.width > 600 ? (size.width > 900 ? 4 : 3) : 2;
      double aspectRatio = 0.58;
      // Adjust ratio for text scaling
      if (textScale > 1.1) aspectRatio = 0.52;
      if (textScale > 1.3) aspectRatio = 0.48;

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
                            "No products in this catalog.",
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
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredProducts.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: aspectRatio,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                      ),
                      itemBuilder: (context, index) {
                        final product = filteredProducts[index];
                        return _CatalogueItemCard(
                          product: product,
                          onRemove: () {
                            HapticFeedback.mediumImpact();
                            controller.removeProductFromCatalogue(
                              widget.catalogueId,
                              product.id.toString(),
                            );
                          },
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

class _CatalogueItemCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onRemove;

  const _CatalogueItemCard({required this.product, required this.onRemove});

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
    final double? basePrice = _parsePrice(product.price);
    final double? resellPrice = basePrice != null ? (basePrice * 1.3) : null;
    final double? mrpPrice = product.regularPrice.isNotEmpty
        ? _parsePrice(product.regularPrice)
        : null;
    final double? profit = (resellPrice != null && basePrice != null)
        ? (resellPrice - basePrice)
        : null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 60,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    product.image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade100,
                      child: const Icon(Iconsax.image, color: Colors.grey),
                    ),
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
            Expanded(
              flex: 40,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: kBlack,
                                ),
                              ),
                              const Spacer(),
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  const AutoTranslate(
                                    child: Text(
                                      "Buy ",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    "₹${product.price}",
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: kPrimaryColor,
                                    ),
                                  ),
                                  if (mrpPrice != null && mrpPrice != basePrice)
                                    Text(
                                      " ₹${mrpPrice.toStringAsFixed(0)}",
                                      style: TextStyle(
                                        fontSize: 11,
                                        decoration: TextDecoration.lineThrough,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  const AutoTranslate(
                                    child: Text(
                                      "Resell ",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF88878B),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    "₹${resellPrice?.toStringAsFixed(0)} ",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF88878B),
                                    ),
                                  ),
                                  if (profit != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDCFCE7),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        "+₹${profit.toStringAsFixed(0)}",
                                        style: const TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: kGreen,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      height: 32,
                      child: OutlinedButton(
                        onPressed: onRemove,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.red.shade200),
                          foregroundColor: Colors.red,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.close, size: 16),
                            SizedBox(width: 4),
                            Text(
                              "Remove",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Poppins',
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
          ],
        ),
      ),
    );
  }
}
