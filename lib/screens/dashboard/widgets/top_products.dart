// For ImageFilter
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/services/api_services.dart';

// --- 1. THE CHAMPION CARD (#1 RANK) ---
class ChampionProductCard extends StatelessWidget {
  final ProductModel product;

  const ChampionProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      margin: const EdgeInsets.fromLTRB(16, 8, 12, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white,
        // Gold-tinted shadow for the winner
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.network(
              product.image,
              height: double.infinity,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (ctx, err, stack) =>
                  Container(color: Colors.grey[100]),
            ),
          ),

          // Gradient Overlay (Bottom)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 120,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                ),
              ),
            ),
          ),

          // Content (Text)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "BEST SELLER",
                  style: TextStyle(
                    color: const Color(0xFFFFD700), // Gold
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Poppins',
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  "₹${product.price}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),

          // THE CROWN BADGE (#1)
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFFD700),
                    Color(0xFFFDB931),
                  ], // Gold Gradient
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: const [
                  Icon(
                    Iconsax.crown5,
                    size: 16,
                    color: Colors.white,
                  ), // Filled Crown
                  SizedBox(width: 4),
                  Text(
                    "#1",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- 2. THE CHALLENGER CARD (#2 - #5) ---
class StandardRankCard extends StatelessWidget {
  final ProductModel product;
  final int rank;

  const StandardRankCard({
    super.key,
    required this.product,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    // Determine Medal Color
    Color badgeColor;
    if (rank == 2)
      badgeColor = const Color(0xFFC0C0C0); // Silver
    else if (rank == 3)
      badgeColor = const Color(0xFFCD7F32); // Bronze
    else
      badgeColor = const Color(0xFF4A317E); // Brand Color for 4 & 5

    return Container(
      width: 160,
      margin: const EdgeInsets.only(bottom: 10, right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Image Section
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(16),
                ),
                child: Image.network(
                  product.image,
                  height: 90,
                  width: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) =>
                      Container(width: 80, height: 90, color: Colors.grey[100]),
                ),
              ),
              // Rank Badge (Small circle)
              Positioned(
                top: 4,
                left: 4,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: badgeColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      "$rank",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Text Section
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                      color: Color(0xFF111827),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "₹${product.price}",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- 3. MAIN SECTION ---
class TopRankingSection extends StatefulWidget {
  const TopRankingSection({super.key});

  @override
  State<TopRankingSection> createState() => _TopRankingSectionState();
}

class _TopRankingSectionState extends State<TopRankingSection> {
  List<ProductModel> _products = [];
  bool _isLoading = true;
  String _selectedTab = 'Top';

  @override
  void initState() {
    super.initState();
    _fetchProductsForTab('Top');
  }

  Future<void> _fetchProductsForTab(String tabName) async {
    setState(() {
      _isLoading = true;
      _selectedTab = tabName;
    });

    try {
      List<ProductModel> products;
      if (tabName == 'Top') {
        products = await ApiService.fetchTopSellingProducts();
      } else if (tabName == 'Hot') {
        products = await ApiService.fetchProducts();
      } else {
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

  ProductModel? getProduct(int index) =>
      (index < _products.length) ? _products[index] : null;

  @override
  Widget build(BuildContext context) {
    final p1 = getProduct(0);
    final p2 = getProduct(1);
    final p3 = getProduct(2);
    final p4 = getProduct(3);
    getProduct(4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- HEADER & TABS ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: Row(
            children: [
              // Title Group
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Iconsax.cup, color: Colors.orange, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Leaderboard",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  Text(
                    "Top Ranking",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontFamily: 'Poppins',
                      height: 1.1,
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Tabs
              Container(
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [_buildTabButton('Top'), _buildTabButton('Hot')],
                ),
              ),
            ],
          ),
        ),

        // --- CONTENT AREA ---
        const SizedBox(height: 8),

        SizedBox(
          height: 310, // Height of the section
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF4A317E)),
                )
              : _products.isEmpty
              ? const Center(child: Text("No rankings yet."))
              : ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(right: 16), // End padding
                  children: [
                    // 1. THE CHAMPION CARD (#1)
                    if (p1 != null) ChampionProductCard(product: p1),

                    // 2. THE CHALLENGERS GRID (#2-5)
                    if (p2 != null)
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Rank 2
                          StandardRankCard(product: p2, rank: 2),
                          // Rank 3
                          if (p3 != null)
                            StandardRankCard(product: p3, rank: 3),
                          // Rank 4 (if exists, just to fill space, or we can scroll)
                          if (p4 != null)
                            StandardRankCard(product: p4, rank: 4),
                        ],
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildTabButton(String text) {
    final isSelected = _selectedTab == text;
    return GestureDetector(
      onTap: () => _fetchProductsForTab(text),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        margin: const EdgeInsets.all(4),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.grey,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 12,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }
}
