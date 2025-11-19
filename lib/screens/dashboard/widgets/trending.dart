import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/services/api_services.dart';

// --- 1. THE TRENDING CARD (HYPE STYLE) ---
class TrendingCard extends StatelessWidget {
  final ProductModel product;
  final int index;

  const TrendingCard({super.key, required this.product, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(
        right: 16,
        bottom: 12,
        top: 4,
      ), // Room for shadow
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(
              0xFF4A317E,
            ).withOpacity(0.1), // Brand purple shadow
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- IMAGE & BADGE ---
          Stack(
            children: [
              // Image Container
              Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  color: Colors.grey[50],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: Image.network(
                    product.image,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) =>
                        const Icon(Icons.image, color: Colors.grey),
                  ),
                ),
              ),

              // Rank Watermark (01, 02...)
              Positioned(
                top: 8,
                left: 10,
                child: Text(
                  "${index + 1}".padLeft(2, '0'),
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: Colors.white.withOpacity(
                      0.8,
                    ), // Semi-transparent on image
                    fontFamily: 'Poppins',
                    shadows: [
                      Shadow(
                        blurRadius: 4,
                        color: Colors.black26,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),

              // "Hot" Flame Icon
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Iconsax.flag,
                    color: Colors.orange,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),

          // --- DETAILS ---
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                    fontFamily: 'Poppins',
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Price & Action
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "₹${product.price}",
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4A317E), // Brand Color
                        fontFamily: 'Poppins',
                      ),
                    ),
                    // Mini Add Button
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- 2. MAIN SECTION ---
class TrendingProducts extends StatefulWidget {
  const TrendingProducts({super.key});

  @override
  State<TrendingProducts> createState() => _TrendingProductsState();
}

class _TrendingProductsState extends State<TrendingProducts> {
  late final ScrollController _scrollController;
  List<ProductModel> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _fetchTrendingProducts();
  }

  Future<void> _fetchTrendingProducts() async {
    try {
      final products = await ApiService.fetchTrendingProducts();
      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      print("Error fetching trending products: $e");
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- HEADER ---
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'Trending on',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'KakiSo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800, // Extra bold for emphasis
                      color: Color(0xFFEB2A7E), // Brand Pink
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Animated-looking Icon container
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Iconsax.trend_up,
                      color: Colors.orange,
                      size: 20,
                    ),
                  ),
                ],
              ),
              // Styled "View All"
              Text(
                'View All',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[500],
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),

        // --- HORIZONTAL LIST ---
        SizedBox(
          height: 270, // Height tailored for the new card
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFEB2A7E)),
                )
              : _products.isEmpty
              ? const Center(child: Text("No trending items."))
              : ListView.builder(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: 16), // Left padding
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    return TrendingCard(product: product, index: index);
                  },
                ),
        ),
      ],
    );
  }
}
