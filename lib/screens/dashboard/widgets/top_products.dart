import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/services/api_services.dart';

// --- 1. ProductCard Widget ---
class ProductCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String description;
  final String rank;

  const ProductCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.description,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(10),
                ),
                child: Image.network(
                  imageUrl,
                  height: 190,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 190,
                      width: double.infinity,
                      color: Colors.grey[200],
                      child: Icon(Icons.broken_image, color: Colors.grey[400]),
                    );
                  },
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    'TOP $rank',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 16,
                    fontFamily: 'Poppins',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontFamily: 'Poppins',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- 2. SmallProductCard Widget ---
class SmallProductCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String description;
  final String rank;
  final Color rankColor;

  const SmallProductCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.description,
    required this.rank,
    required this.rankColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(10),
                ),
                child: Image.network(
                  imageUrl,
                  height: 85,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 85,
                      width: double.infinity,
                      color: Colors.grey[200],
                      child: Icon(Icons.broken_image, color: Colors.grey[400]),
                    );
                  },
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: rankColor,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    'TOP $rank',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Poppins',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    fontFamily: 'Poppins',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 10,
                    fontFamily: 'Poppins',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- 3. TopRankingSection Widget (UPDATED WITH TABS) ---
class TopRankingSection extends StatefulWidget {
  const TopRankingSection({super.key});

  @override
  State<TopRankingSection> createState() => _TopRankingSectionState();
}

class _TopRankingSectionState extends State<TopRankingSection> {
  List<ProductModel> _products = [];
  bool _isLoading = true;

  // Tracks the selected tab: 'Top', 'Hot', or 'Popular'
  String _selectedTab = 'Top';

  @override
  void initState() {
    super.initState();
    // Initial fetch for "Top"
    _fetchProductsForTab('Top');
  }

  // Fetch data based on the selected tab
  Future<void> _fetchProductsForTab(String tabName) async {
    setState(() {
      _isLoading = true;
      _selectedTab = tabName;
    });

    try {
      List<ProductModel> products;

      // Map tabs to WooCommerce "orderby" parameters
      if (tabName == 'Top') {
        // Top = Best Sellers (popularity)
        products =
            await ApiService.fetchTopSellingProducts(); // Assuming this fetches by 'popularity'
      } else if (tabName == 'Hot') {
        // Hot = Newest Items (date) - You might need to add a fetchNewestProducts() to ApiService
        // For now, let's reuse fetchProducts which defaults to date usually
        products = await ApiService.fetchProducts();
      } else {
        // Popular = Top Rated (rating) - You might need to add fetchTopRated()
        // For demo, we'll just reuse fetchTopSellingProducts but imagine it's different
        products = await ApiService.fetchTopSellingProducts();
      }

      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      print("Error fetching products for $tabName: $e");
    }
  }

  ProductModel? getProduct(int index) {
    if (index < _products.length) return _products[index];
    return null;
  }

  String _stripHtml(String htmlString) {
    RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    return htmlString.replaceAll(exp, '').trim();
  }

  @override
  Widget build(BuildContext context) {
    final p1 = getProduct(0);
    final p2 = getProduct(1);
    final p3 = getProduct(2);
    final p4 = getProduct(3);
    final p5 = getProduct(4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Header ---
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Title
              Row(
                children: const [
                  Text(
                    'Top',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Ranking',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.pinkAccent,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Iconsax.magic_star, color: Colors.orange, size: 24),
                ],
              ),
              const SizedBox(width: 10),

              // Tabs
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildTabButton('Top'),
                      _buildTabButton('Hot'),
                      _buildTabButton('Popular'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // --- Content ---
        SizedBox(
          height: 300,
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.pinkAccent),
                )
              : _products.isEmpty
              ? const Center(child: Text("No products found."))
              : ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: 8.0),
                  children: [
                    // 1. Top 1 Product (Large Card)
                    if (p1 != null)
                      ProductCard(
                        imageUrl: p1.image,
                        title: p1.name,
                        description: _stripHtml(
                          p1.shortDescription.isEmpty
                              ? p1.name
                              : p1.shortDescription,
                        ),
                        rank: '1',
                      ),

                    // 2. Grid of Smaller Cards (Top 2-5)
                    if (p2 != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Row 1: Rank 2 & 3
                            Row(
                              children: [
                                SmallProductCard(
                                  imageUrl: p2.image,
                                  title: p2.name,
                                  description: _stripHtml(p2.shortDescription),
                                  rank: '2',
                                  rankColor: Colors.pinkAccent,
                                ),
                                if (p3 != null)
                                  SmallProductCard(
                                    imageUrl: p3.image,
                                    title: p3.name,
                                    description: _stripHtml(
                                      p3.shortDescription,
                                    ),
                                    rank: '3',
                                    rankColor: Colors.blueAccent,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Row 2: Rank 4 & 5
                            if (p4 != null)
                              Row(
                                children: [
                                  SmallProductCard(
                                    imageUrl: p4.image,
                                    title: p4.name,
                                    description: _stripHtml(
                                      p4.shortDescription,
                                    ),
                                    rank: '4',
                                    rankColor: Colors.green,
                                  ),
                                  if (p5 != null)
                                    SmallProductCard(
                                      imageUrl: p5.image,
                                      title: p5.name,
                                      description: _stripHtml(
                                        p5.shortDescription,
                                      ),
                                      rank: '5',
                                      rankColor: Colors.purpleAccent,
                                    ),
                                ],
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  // Helper to build clickable tabs
  Widget _buildTabButton(String tabName) {
    final bool isSelected = _selectedTab == tabName;

    return GestureDetector(
      onTap: () => _fetchProductsForTab(tabName),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.pinkAccent.shade100 : Colors.transparent,
          borderRadius: BorderRadius.circular(20), // More rounded look for tabs
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Text(
          tabName,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.w500,
            fontSize: 12,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }
}
