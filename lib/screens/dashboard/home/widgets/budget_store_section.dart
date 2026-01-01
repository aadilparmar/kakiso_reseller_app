import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import 'package:kakiso_reseller_app/controllers/cart_controller.dart';
import 'package:kakiso_reseller_app/controllers/catalouge_controller.dart';
import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/screens/dashboard/product/product_details_page.dart';
import 'package:kakiso_reseller_app/screens/dashboard/widgets/all_product_screen.dart';

// --- THEME CONSTANTS ---
class _BudgetTheme {
  static const Color primary = Color(0xFF4A317E);
  static const Color accent = Color(0xFFEB2A7E);
  static const Color green = Color(0xFF059669);
  static const Color bgLight = Color(0xFFF9FAFB);
  static const Color textDark = Color(0xFF1F2937);
  static const Color textGrey = Color(0xFF6B7280);
}

class BudgetStoreSection extends StatefulWidget {
  final List<ProductModel> products;
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
  late final CartController _cartController;
  late final CatalogueController _catalogueController;

  int _selectedFilterIndex = 0;

  final List<_PriceFilter> _filters = const [
    _PriceFilter(label: "Under ₹99", minPrice: 0, maxPrice: 99),
    _PriceFilter(label: "₹99 - ₹199", minPrice: 99, maxPrice: 199),
    _PriceFilter(label: "₹199 - ₹299", minPrice: 199, maxPrice: 299),
    _PriceFilter(label: "₹299 - ₹499", minPrice: 299, maxPrice: 499),
    _PriceFilter(label: "₹499 - ₹999", minPrice: 499, maxPrice: 999),
  ];

  @override
  void initState() {
    super.initState();
    _cartController = Get.isRegistered<CartController>()
        ? Get.find<CartController>()
        : Get.put(CartController());

    _catalogueController = Get.isRegistered<CatalogueController>()
        ? Get.find<CatalogueController>()
        : Get.put(CatalogueController());
  }

  // --- LOGIC HELPERS ---

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

  // --- ACTIONS ---

  void _openAddToCatalogueSheet(ProductModel product) {
    HapticFeedback.lightImpact();
    final availableCatalogues = _catalogueController.catalogueNames;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _CatalogueBottomSheet(
        catalogueNames: availableCatalogues,
        onAddToExisting: (name) {
          _catalogueController.addProductToExistingCatalogue(name, product);
          Navigator.pop(ctx);
          _showSuccessSnackbar(
            'Added to Catalog',
            '"${product.name}" added to "$name".',
          );
        },
        onCreateNew: () {
          Navigator.pop(ctx);
          _showCreateNewCatalogueDialog(product);
        },
      ),
    );
  }

  void _showCreateNewCatalogueDialog(ProductModel product) {
    final TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'New Catalog',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'e.g., Festival Sale',
            filled: true,
            fillColor: Colors.grey.shade50,
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
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              _catalogueController.createCatalogueAndAddProduct(name, product);
              Navigator.pop(ctx);
              _showSuccessSnackbar(
                'Catalog Created',
                '"${product.name}" added to "$name".',
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _BudgetTheme.accent,
              shape: const StadiumBorder(),
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.black87,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 2),
      icon: const Icon(Iconsax.tick_circle, color: Colors.greenAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = _filteredProducts;

    // LOGIC: Check if count > 20
    final bool hasMoreThan20 = products.length > 20;

    // If > 20, take only the first 20 for the grid
    final visibleProducts = hasMoreThan20
        ? products.take(20).toList()
        : products;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Header Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 24,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEB2A7E),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ShaderMask(
                            shaderCallback: (rect) {
                              return const LinearGradient(
                                colors: [
                                  Color.fromARGB(255, 72, 105, 236),
                                  Color.fromARGB(255, 82, 16, 235),
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ).createShader(rect);
                            },
                            child: const Text(
                              'Budget Store',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 2),
                    Text(
                      "High margin deals for you",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _BudgetTheme.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
              _buildBestValueBadge(),
            ],
          ),
        ),

        // 2. Filter Tabs
        SizedBox(
          height: 56,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _filters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              return _FilterTab(
                filter: _filters[index],
                isSelected: index == _selectedFilterIndex,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedFilterIndex = index);
                },
              );
            },
          ),
        ),

        const SizedBox(height: 10),

        // 3. Product Grid with Animation
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: widget.products.isEmpty
                ? _buildEmptyState(
                    icon: Iconsax.box,
                    message: "No products loaded yet.",
                  )
                : visibleProducts.isEmpty
                ? _buildEmptyState(
                    key: ValueKey('empty_$_selectedFilterIndex'),
                    icon: Iconsax.filter_remove,
                    message: "No deals in this range.",
                  )
                : Column(
                    key: ValueKey('grid_$_selectedFilterIndex'),
                    children: [
                      GridView.builder(
                        itemCount: visibleProducts.length,
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.60,
                            ),
                        itemBuilder: (context, index) {
                          final product = visibleProducts[index];
                          return _ResellerProductCard(
                            product: product,
                            parsePrice: _parsePrice,
                            onAddToCart: () {
                              HapticFeedback.lightImpact();
                              _cartController.addToCart(product);
                              widget.onProductAddedToCart?.call(product);
                            },
                            onAddToCatalogue: () =>
                                _openAddToCatalogueSheet(product),
                          );
                        },
                      ),

                      // 4. "VIEW ALL" BUTTON (Only if > 20 products)
                      if (hasMoreThan20) ...[
                        const SizedBox(height: 24),
                        _buildViewAllButton(),
                      ],
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildBestValueBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E8FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE9D5FF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(
            Iconsax.percentage_circle,
            size: 14,
            color: _BudgetTheme.primary,
          ),
          SizedBox(width: 4),
          Text(
            "Best Value",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _BudgetTheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    Key? key,
    required IconData icon,
    required String message,
  }) {
    return Container(
      key: key,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: _BudgetTheme.bgLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewAllButton() {
    final currentLabel = _filters[_selectedFilterIndex].label;

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: () {
          Get.to(
            () => AllProductsScreen(
              // Pass the specific price range name as the title
              title: 'Budget Store ($currentLabel)',
              initialOrderBy: 'price',
              initialOrder: 'asc',
            ),
            transition: Transition.cupertino,
          );
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: _BudgetTheme.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          foregroundColor: _BudgetTheme.primary,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "VIEW ALL $currentLabel DEALS".toUpperCase(),
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Iconsax.arrow_right_1, size: 18),
          ],
        ),
      ),
    );
  }
}

// --- SUB-WIDGETS ---

class _FilterTab extends StatelessWidget {
  final _PriceFilter filter;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterTab({
    required this.filter,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? _BudgetTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? _BudgetTheme.primary : Colors.grey.shade300,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _BudgetTheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          filter.label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : _BudgetTheme.textDark,
          ),
        ),
      ),
    );
  }
}

class _ResellerProductCard extends StatelessWidget {
  final ProductModel product;
  final double? Function(String) parsePrice;
  final VoidCallback onAddToCart;
  final VoidCallback onAddToCatalogue;

  const _ResellerProductCard({
    required this.product,
    required this.parsePrice,
    required this.onAddToCart,
    required this.onAddToCatalogue,
  });

  @override
  Widget build(BuildContext context) {
    final double? buyPrice = parsePrice(product.price);
    final double? resellPrice = buyPrice != null ? (buyPrice * 1.3) : null;
    final double? profit = (resellPrice != null && buyPrice != null)
        ? (resellPrice - buyPrice)
        : null;

    return GestureDetector(
      onTap: () => Get.to(
        () => ProductDetailsPage(product: product),
        transition: Transition.fadeIn,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildProductImage(),
                  if (profit != null) _buildProfitBadge(profit),
                  // if (product.discountPercentage != null &&
                  //     product.discountPercentage! > 0)
                  //   // _buildDiscountBadge(product.discountPercentage!),
                ],
              ),
            ),

            // Info
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _BudgetTheme.textDark,
                        height: 1.2,
                      ),
                    ),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (resellPrice != null)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                "Buy ",
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                "₹${product.price}",
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: _BudgetTheme.primary,
                                  height: 1,
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 2),
                        Text(
                          "Resell ₹${resellPrice?.toStringAsFixed(0)}",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),

                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            icon: Iconsax.book_1,
                            color: _BudgetTheme.accent,
                            label: "CATALOG",
                            onTap: onAddToCatalogue,
                            isOutlined: true,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildActionButton(
                            icon: Iconsax.shopping_cart,
                            color: _BudgetTheme.primary,
                            label: "ADD",
                            onTap: onAddToCart,
                            isOutlined: false,
                          ),
                        ),
                      ],
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

  Widget _buildProductImage() {
    return Container(
      color: Colors.grey.shade50,
      child: Image.network(
        product.image,
        fit: BoxFit.cover,
        loadingBuilder: (ctx, child, progress) {
          if (progress == null) return child;
          return Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _BudgetTheme.primary.withOpacity(0.3),
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) =>
            const Center(child: Icon(Iconsax.image, color: Colors.grey)),
      ),
    );
  }

  Widget _buildProfitBadge(double profit) {
    return Positioned(
      top: 8,
      left: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _BudgetTheme.green,
          borderRadius: BorderRadius.circular(6),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Row(
          children: [
            const Icon(Iconsax.trend_up, size: 10, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              "Min. Profit ₹${profit.toStringAsFixed(0)}",
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildDiscountBadge(int percentage) {
  //   return Positioned(
  //     top: 8,
  //     right: 8,
  //     child: Container(
  //       padding: const EdgeInsets.all(5),
  //       decoration: const BoxDecoration(
  //         color: Colors.black87,
  //         shape: BoxShape.circle,
  //       ),
  //       child: Text(
  //         "$percentage% off",
  //         style: const TextStyle(
  //           color: Colors.white,
  //           fontSize: 9,
  //           fontWeight: FontWeight.bold,
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
    required bool isOutlined,
  }) {
    // FIXED MATERIAL ERROR HERE
    return Material(
      color: isOutlined ? Colors.transparent : color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: isOutlined ? BorderSide(color: color) : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 32,
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: isOutlined ? color : Colors.white),
        ),
      ),
    );
  }
}

class _CatalogueBottomSheet extends StatelessWidget {
  final List<String> catalogueNames;
  final Function(String) onAddToExisting;
  final VoidCallback onCreateNew;

  const _CatalogueBottomSheet({
    required this.catalogueNames,
    required this.onAddToExisting,
    required this.onCreateNew,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Text(
            'Select Catalog',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 16),
          if (catalogueNames.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "No active catalogs found.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: catalogueNames.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final name = catalogueNames[i];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      name,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: const Icon(
                      Iconsax.add_circle,
                      color: _BudgetTheme.primary,
                    ),
                    onTap: () => onAddToExisting(name),
                  );
                },
              ),
            ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onCreateNew,
              icon: const Icon(Iconsax.add, size: 20),
              label: const Text('Create New Catalog'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _BudgetTheme.primary,
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
