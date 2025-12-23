import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import 'package:kakiso_reseller_app/controllers/cart_controller.dart';
import 'package:kakiso_reseller_app/controllers/catalouge_controller.dart';
import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/screens/dashboard/product/product_details_page.dart';
import 'package:kakiso_reseller_app/screens/dashboard/widgets/all_product_screen.dart';
import 'package:kakiso_reseller_app/utils/constants.dart';

/// Budget Store section showing products in bands:
/// 0–99, 99–199, 199–299, 299–499, 499–999.
class BudgetStoreSection extends StatefulWidget {
  final List<ProductModel> products;

  /// Optional: parent can show a custom snackbar when added to cart.
  final void Function(ProductModel product)? onProductAddedToCart;

  const BudgetStoreSection({
    super.key,
    required this.products,
    this.onProductAddedToCart,
  });

  @override
  State<BudgetStoreSection> createState() => _BudgetStoreSectionState();
}

class _BudgetStoreSectionState extends State<BudgetStoreSection> {
  final CartController cartController = Get.find<CartController>();
  final CatalogueController catalogueController =
      Get.find<CatalogueController>();

  int _selectedFilterIndex = 0;

  // 🔥 RANGES:
  final List<_PriceFilter> _filters = const [
    _PriceFilter(label: "₹0 – ₹99", minPrice: 0, maxPrice: 99),
    _PriceFilter(label: "₹99 – ₹199", minPrice: 99, maxPrice: 199),
    _PriceFilter(label: "₹199 – ₹299", minPrice: 199, maxPrice: 299),
    _PriceFilter(label: "₹299 – ₹499", minPrice: 299, maxPrice: 499),
    _PriceFilter(label: "₹499 – ₹999", minPrice: 499, maxPrice: 999),
  ];

  void _openAddToCatalogueSheet(ProductModel product) {
    final availableCatalogues = catalogueController.catalogueNames;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              MediaQuery.of(ctx).padding.bottom + 20,
            ),
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

                const Text(
                  'Add product to catalog',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 16),

                if (availableCatalogues.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'No catalogs found. Create one to continue.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  )
                else
                  ...availableCatalogues.map(
                    (name) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Iconsax.book, size: 18),
                      title: Text(
                        name,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: const Icon(Iconsax.arrow_right_3, size: 16),
                      onTap: () {
                        catalogueController.addProductToExistingCatalogue(
                          name,
                          product,
                        );
                        Navigator.pop(ctx);

                        Get.snackbar(
                          'Added to catalog',
                          '"${product.name}" added to "$name".',
                          snackPosition: SnackPosition.BOTTOM,
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
                      _showCreateNewCatalogueDialog(product);
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
          ),
        );
      },
    );
  }

  void _showCreateNewCatalogueDialog(ProductModel product) {
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
            style: TextStyle(fontFamily: 'Poppins'),
          ),
          content: TextField(
            controller: nameController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'e.g. Budget Deals',
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;

                catalogueController.createCatalogueAndAddProduct(name, product);

                Navigator.pop(ctx);

                Get.snackbar(
                  'Catalog created',
                  '"${product.name}" added to "$name".',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: accentColor),
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  double? _parsePrice(String value) {
    try {
      final cleaned = value.replaceAll(RegExp(r'[^0-9.]'), '');
      if (cleaned.isEmpty) return null;
      return double.parse(cleaned);
    } catch (_) {
      return null;
    }
  }

  List<ProductModel> get _filteredProducts {
    if (widget.products.isEmpty) return [];
    final filter = _filters[_selectedFilterIndex];

    return widget.products.where((p) {
      final price = _parsePrice(p.price);
      if (price == null) return false;
      return price >= filter.minPrice && price <= filter.maxPrice;
    }).toList();
  }

  bool get _hasMoreThan20 => _filteredProducts.length > 20;

  List<ProductModel> get _visibleProducts =>
      _hasMoreThan20 ? _filteredProducts.take(20).toList() : _filteredProducts;

  @override
  Widget build(BuildContext context) {
    final products = _visibleProducts;

    // --- SCALING LOGIC ---
    final double textScale = MediaQuery.textScalerOf(context).scale(1);
    final double scaleFactor = math.max(1.0, math.min(textScale, 1.4));

    // Dynamic Aspect Ratio:
    // As text gets bigger (scaleFactor increases), the ratio gets smaller
    // (making cards taller) to fit the content.
    final double dynamicAspectRatio = 0.64 / scaleFactor;

    // Scale filter height
    final double filterListHeight = 48 * scaleFactor;
    // ---------------------

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Budget Store",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Handpicked deals under ₹999",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Iconsax.discount_shape,
                      size: 11,
                      color: Color(0xFF4A317E),
                    ),
                    SizedBox(width: 4),
                    Text(
                      "Best value",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF4A317E),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // FILTER CHIPS (tabs style)
          // Scaled height for accessibility
          SizedBox(
            height: filterListHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final bool isSelected = index == _selectedFilterIndex;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedFilterIndex = index;
                    });
                  },
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 88),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? accentColor : Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected
                            ? accentColor
                            : const Color(0xFFD1D5DB),
                        width: 1.2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: accentColor.withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                    child: Center(
                      child: Text(
                        filter.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF111827),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 14),

          // BODY
          if (widget.products.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 26),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: const [
                  Icon(Iconsax.box, size: 26, color: Color(0xFF9CA3AF)),
                  SizedBox(height: 8),
                  Text(
                    "No products loaded yet.",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            )
          else if (products.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 26),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: const [
                  Icon(Iconsax.info_circle, size: 26, color: Color(0xFF9CA3AF)),
                  SizedBox(height: 8),
                  Text(
                    "No products in this price band yet.",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            GridView.builder(
              itemCount: products.length,
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                // DYNAMIC ASPECT RATIO FIX:
                childAspectRatio: dynamicAspectRatio,
              ),
              itemBuilder: (context, index) {
                final product = products[index];
                return _BudgetProductCard(
                  product: product,
                  parsePrice: _parsePrice,
                  scaleFactor: scaleFactor, // Pass scaler down
                  onAddToCart: () {
                    cartController.addToCart(product);
                    widget.onProductAddedToCart?.call(product);
                  },
                  onAddToCatalogue: () {
                    _openAddToCatalogueSheet(product);
                  },
                );
              },
            ),

            if (_hasMoreThan20) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 44 * scaleFactor, // Scaled button height
                child: OutlinedButton(
                  onPressed: () {
                    Get.to(
                      () => const AllProductsScreen(
                        title: 'Budget Store Deals',
                        initialOrderBy: 'price',
                        initialOrder: 'asc',
                      ),
                      transition: Transition.rightToLeft,
                      duration: const Duration(milliseconds: 300),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: accentColor, width: 1.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    "VIEW ALL DEALS",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _PriceFilter {
  final String label;
  final double minPrice;
  final double maxPrice;
  const _PriceFilter({
    required this.label,
    required this.minPrice,
    required this.maxPrice,
  });
}

/// Small vertical card used only in this section.
class _BudgetProductCard extends StatelessWidget {
  final ProductModel product;
  final double? Function(String) parsePrice;
  final VoidCallback onAddToCart;
  final VoidCallback onAddToCatalogue;
  final double scaleFactor; // Received from parent

  const _BudgetProductCard({
    required this.product,
    required this.parsePrice,
    required this.onAddToCart,
    required this.onAddToCatalogue,
    this.scaleFactor = 1.0,
  });

  static const Color kPrimaryColor = Color(0xFF4A317E);
  static const Color kAccentColor = Color(0xFFEB2A7E);

  @override
  Widget build(BuildContext context) {
    final double? basePrice = parsePrice(product.price);
    final double? resellPrice = basePrice != null
        ? (basePrice * 1.3)
        : null; // +30% resell
    final double? mrpPrice = product.regularPrice.isNotEmpty
        ? parsePrice(product.regularPrice)
        : null;
    final double? profit = (resellPrice != null && basePrice != null)
        ? (resellPrice - basePrice)
        : null;

    // Dynamically scale the bottom button height
    final double buttonHeight = 36 * scaleFactor;

    return GestureDetector(
      onTap: () {
        Get.to(
          () => ProductDetailsPage(product: product),
          transition: Transition.fadeIn,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4A317E).withValues(alpha: 0.04),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // IMAGE (Expanded ensures it takes remaining space)
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFF5F3FF), Color(0xFFFDF2FF)],
                      ),
                    ),
                    child: Image.network(
                      product.image,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey.shade50,
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: const Color(
                                  0xFF4A317E,
                                ).withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey.shade100,
                        child: Icon(
                          Iconsax.image,
                          color: Colors.grey.shade300,
                          size: 30,
                        ),
                      ),
                    ),
                  ),

                  // Discount badge
                  if (product.discountPercentage != null &&
                      product.discountPercentage! > 0)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: const LinearGradient(
                            colors: [Colors.black87, Colors.black54],
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Iconsax.flash_1,
                              size: 10,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "-${product.discountPercentage}%",
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // DETAILS SECTION
            // Using flexible/column logic to prevent overflow
            Padding(
              padding: const EdgeInsets.fromLTRB(9, 8, 9, 2),
              child: Text(
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                  height: 1.28,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(9, 0, 9, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (resellPrice != null)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            "Buy at ",
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Poppins',
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          Text(
                            "₹${product.price}",
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: accentColor,
                              height: 1.1,
                            ),
                          ),
                          // Profit chip
                          if (profit != null)
                            Positioned(
                              left: 8,
                              bottom: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE0FBEA),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF22C55E,
                                    ).withValues(alpha: 0.4),
                                    width: 0.6,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Iconsax.trend_up,
                                      size: 11,
                                      color: Color(0xFF16A34A),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "You earn ~₹${profit.toStringAsFixed(0)}",
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF166534),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Text(
                          "Resell ₹${resellPrice!.toStringAsFixed(0)}",
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        if (mrpPrice != null &&
                            product.regularPrice.isNotEmpty &&
                            product.regularPrice != product.price) ...[
                          const SizedBox(width: 6),
                          Text(
                            "MRP ₹${mrpPrice.toStringAsFixed(0)}",
                            style: TextStyle(
                              fontSize: 9.5,
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey.shade500,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // BUTTON ROW (SCALED HEIGHT)
            SizedBox(
              height: buttonHeight,
              child: Row(
                children: [
                  // Add to cart
                  Expanded(
                    child: Material(
                      color: kPrimaryColor,
                      child: InkWell(
                        onTap: onAddToCart,
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Text(
                                  "Add to",
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  "Cart",
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Share / future catalogue
                  Expanded(
                    child: Material(
                      color: Colors.white,
                      child: InkWell(
                        onTap: onAddToCatalogue,
                        child: Container(
                          decoration: BoxDecoration(color: kAccentColor),
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Text(
                                    "Add to",
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Color.fromARGB(255, 249, 249, 249),
                                    ),
                                  ),
                                  Text(
                                    "Catalog",
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Color.fromARGB(255, 255, 255, 255),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
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
}
