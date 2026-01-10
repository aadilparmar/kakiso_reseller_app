import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/screens/dashboard/categories/categories_detail_page/widgets/vertical_product_card_categories.dart';
import 'package:kakiso_reseller_app/services/api_services.dart';
import 'package:kakiso_reseller_app/controllers/catalouge_controller.dart';
import 'package:kakiso_reseller_app/utils/constants.dart';

class BrandDetailsPage extends StatefulWidget {
  final String brandName;
  final String? brandLogoUrl;

  const BrandDetailsPage({
    super.key,
    required this.brandName,
    this.brandLogoUrl,
  });

  @override
  State<BrandDetailsPage> createState() => _BrandDetailsPageState();
}

class _BrandDetailsPageState extends State<BrandDetailsPage> {
  late Future<List<ProductModel>> _futureProducts;

  // For catalogue actions
  final CatalogueController _catalogueController = Get.put(
    CatalogueController(),
    permanent: true,
  );

  @override
  void initState() {
    super.initState();
    _futureProducts = _loadBrandProducts();
  }

  Future<List<ProductModel>> _loadBrandProducts() async {
    // 1. Get all products (server side pagination)
    final all = await ApiService().fetchAllProductsPaginated(
      perPage: 50,
      maxPages: 10,
      orderBy: 'date',
      order: 'desc',
    );

    // 2. Filter client-side using ProductModel.brandName
    final brandLower = widget.brandName.toLowerCase().trim();

    final filtered = all.where((p) {
      final n = (p.brandName ?? '').toLowerCase().trim();
      return n == brandLower;
    }).toList();

    return filtered;
  }

  // Called from VerticalProductCard when user picks/creates a catalogue
  void _handleCatalogueSelected(
    ProductModel product,
    String catalogueName,
    bool isNewCatalogue,
  ) {
    if (isNewCatalogue) {
      _catalogueController.createCatalogueAndAddProduct(catalogueName, product);
    } else {
      _catalogueController.addProductToExistingCatalogue(
        catalogueName,
        product,
      );
    }

    Get.snackbar(
      'Added to catalogue',
      '"${product.name}" added to "$catalogueName".',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.brandName;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: false,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Get.back(),
        ),
        title: Row(
          children: [
            _buildBrandAvatar(),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Color(0xFF111827),
                ),
              ),
            ),
          ],
        ),
      ),
      body: FutureBuilder<List<ProductModel>>(
        future: _futureProducts,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: accentColor),
            );
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          final products = snapshot.data ?? [];

          if (products.isEmpty) {
            return _buildEmptyState();
          }

          final catalogues = _catalogueController.catalogueNames;

          return Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: GridView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: products.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.64,
              ),
              itemBuilder: (context, index) {
                final product = products[index];

                return VerticalProductCard(
                  product: product,
                  availableCatalogues: catalogues,
                  onCatalogueSelected: _handleCatalogueSelected,
                  isSelected: false, // no bulk selection here
                  onSelectionToggle: null, // hide checkbox
                );
              },
            ),
          );
        },
      ),
    );
  }

  // ----------------------------------------------------------
  // UI helpers
  // ----------------------------------------------------------

  Widget _buildBrandAvatar() {
    final logo = widget.brandLogoUrl?.trim();
    final hasLogo = logo != null && logo.isNotEmpty && logo.startsWith('http');

    if (!hasLogo) {
      final initial = widget.brandName.isNotEmpty
          ? widget.brandName.trim()[0].toUpperCase()
          : 'B';

      return CircleAvatar(
        radius: 16,
        backgroundColor: accentColor.withValues(alpha: 0.1),
        child: Text(
          initial,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: accentColor,
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: 16,
      backgroundColor: Colors.white,
      foregroundImage: NetworkImage(logo),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.shopping_bag_outlined,
              size: 40,
              color: Color(0xFF9CA3AF),
            ),
            SizedBox(height: 12),
            Text(
              "No products found for this brand",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Color(0xFF374151),
              ),
            ),
            SizedBox(height: 6),
            Text(
              "We could not find any products that belong to this brand yet.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Iconsax.warning_2, size: 40, color: Color(0xFFEF4444)),
            const SizedBox(height: 12),
            const Text(
              "Something went wrong",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _futureProducts = _loadBrandProducts();
                });
              },
              icon: const Icon(Iconsax.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
