import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/screens/dashboard/product/product_details_page.dart';
import 'package:kakiso_reseller_app/services/api_services.dart';
import 'package:kakiso_reseller_app/utils/constants.dart';
// Import ProductDetailsPage to allow navigation to the new product

class SimilarProductsSection extends StatefulWidget {
  final String categoryId; // We use this to fetch relevant items

  const SimilarProductsSection({super.key, required this.categoryId});

  @override
  State<SimilarProductsSection> createState() => _SimilarProductsSectionState();
}

class _SimilarProductsSectionState extends State<SimilarProductsSection> {
  List<ProductModel> _similarProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSimilarProducts();
  }

  Future<void> _fetchSimilarProducts() async {
    try {
      // In a real app, you would pass widget.categoryId to the API
      // final products = await ApiService.fetchProductsByCategory(widget.categoryId);

      // For now, we reuse fetchProducts() to simulate recommendations
      final products = await ApiService.fetchProducts();

      if (mounted) {
        setState(() {
          // Take 5 random items or the first 5
          _similarProducts = products.take(5).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_similarProducts.isEmpty && !_isLoading) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- HEADER ---
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 0, vertical: 12),
          child: Text(
            "Similar Products",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
              color: Colors.black87,
            ),
          ),
        ),

        // --- LIST ---
        SizedBox(
          height: 260,
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: accentColor),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _similarProducts.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final product = _similarProducts[index];
                    return _SimilarProductCard(product: product);
                  },
                ),
        ),
      ],
    );
  }
}

// --- INTERNAL CARD WIDGET ---
class _SimilarProductCard extends StatelessWidget {
  final ProductModel product;

  const _SimilarProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to the new product details page
        // preventDuplicates: false allows opening Product B from Product A page
        Get.to(
          () => ProductDetailsPage(product: product),
          preventDuplicates: false,
          transition: Transition.rightToLeft,
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(bottom: 8), // Space for shadow
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. IMAGE
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      product.image,
                      fit: BoxFit.cover,
                      errorBuilder: (c, o, s) =>
                          Container(color: Colors.grey[100]),
                    ),
                    // Discount Tag
                    if (product.discountPercentage != null &&
                        product.discountPercentage! > 0)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            "${product.discountPercentage}% OFF",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // 2. DETAILS
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                        height: 1.2,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (product.regularPrice.isNotEmpty &&
                            product.regularPrice != product.price)
                          Text(
                            "₹${product.regularPrice}",
                            style: TextStyle(
                              fontSize: 11,
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        Text(
                          "₹${product.price}",
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                            fontFamily: 'Poppins',
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
}
