import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import 'package:kakiso_reseller_app/controllers/cart_controller.dart';
import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/screens/dashboard/product/product_details_page.dart';
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

  int _selectedFilterIndex = 0;

  // 🔥 RANGES AS YOU ASKED:
  // 99  → 0–99
  // 199 → 99–199
  // 299 → 199–299
  // 499 → 299–499
  // 999 → 499–999
  final List<_PriceFilter> _filters = const [
    _PriceFilter(label: "₹0 – ₹99", minPrice: 0, maxPrice: 99),
    _PriceFilter(label: "₹99 – ₹199", minPrice: 99, maxPrice: 199),
    _PriceFilter(label: "₹199 – ₹299", minPrice: 199, maxPrice: 299),
    _PriceFilter(label: "₹299 – ₹499", minPrice: 299, maxPrice: 499),
    _PriceFilter(label: "₹499 – ₹999", minPrice: 499, maxPrice: 999),
  ];

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

  @override
  Widget build(BuildContext context) {
    final products = _filteredProducts;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
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
              // const SizedBox(width: 8),
              // Container(
              //   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              //   decoration: BoxDecoration(
              //     color: accentColor.withOpacity(0.06),
              //     borderRadius: BorderRadius.circular(999),
              //     border: Border.all(
              //       color: accentColor.withOpacity(0.18),
              //       width: 0.7,
              //     ),
              //   ),
              //   child: Row(
              //     mainAxisSize: MainAxisSize.min,
              //     children: const [
              //       Icon(Iconsax.trend_up, size: 12, color: accentColor),
              //       SizedBox(width: 4),
              //       Text(
              //         "Resell +30%",
              //         style: TextStyle(
              //           fontFamily: 'Poppins',
              //           fontSize: 10,
              //           fontWeight: FontWeight.w600,
              //           color: accentColor,
              //           letterSpacing: 0.2,
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
              const Spacer(),
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
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
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
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: isSelected
                          ? const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF4A317E), accentColor],
                            )
                          : null,
                      color: isSelected ? null : const Color(0xFFF3F4F6),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : Colors.grey.shade300,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: accentColor.withOpacity(0.22),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Iconsax.tag,
                          size: 14,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          filter.label,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11.5,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF4B5563),
                          ),
                        ),
                      ],
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
          else
            GridView.builder(
              itemCount: products.length,
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.64,
              ),
              itemBuilder: (context, index) {
                final product = products[index];
                return _BudgetProductCard(
                  product: product,
                  parsePrice: _parsePrice,
                  onAddToCart: () {
                    cartController.addToCart(product);
                    widget.onProductAddedToCart?.call(product);
                  },
                );
              },
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

/// Small vertical card used only in this section.
class _BudgetProductCard extends StatelessWidget {
  final ProductModel product;
  final double? Function(String) parsePrice;
  final VoidCallback onAddToCart;

  const _BudgetProductCard({
    required this.product,
    required this.parsePrice,
    required this.onAddToCart,
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
              color: const Color(0xFF4A317E).withOpacity(0.04),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // IMAGE
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
                                color: const Color(0xFF4A317E).withOpacity(0.3),
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
                            color: const Color(0xFF22C55E).withOpacity(0.4),
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

            // NAME
            Padding(
              padding: const EdgeInsets.fromLTRB(9, 8, 9, 2),
              child: Text(
                product.name,
                maxLines: 2,
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

            // PRICES
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
                            "Resell ",
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Poppins',
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          Text(
                            "₹${resellPrice.toStringAsFixed(0)}",
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: accentColor,
                              height: 1.1,
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
                          "Buy ₹${product.price}",
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

            // BUTTON ROW
            SizedBox(
              height: 36,
              child: Row(
                children: [
                  // Add to cart
                  Expanded(
                    child: Material(
                      color: kPrimaryColor,
                      child: InkWell(
                        onTap: onAddToCart,
                        child: const Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,

                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Icon(
                                //   Iconsax.shopping_bag,
                                //   size: 16,
                                //   color: Colors.white,
                                // ),
                                // SizedBox(width: 4),
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
                        onTap: () {
                          // hook share / catalogue here if needed
                        },
                        child: Container(
                          decoration: BoxDecoration(color: kAccentColor),
                          child: const Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Icon(
                                  //   Iconsax.export_3,
                                  //   size: 16,
                                  //   color: accentColor,
                                  // ),
                                  // SizedBox(width: 4),
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
