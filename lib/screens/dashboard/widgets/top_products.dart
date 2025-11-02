import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

// --- 1. ProductCard Widget (for TOP 1 product) ---
class ProductCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String description;
  final String rank;

  const ProductCard({
    super.key,
    required this.imagePath,
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
                child: Image.asset(
                  imagePath,
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

// --- 2. SmallProductCard Widget (CORRECTED) ---
class SmallProductCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String description;
  final String rank;
  final Color rankColor;

  const SmallProductCard({
    super.key,
    required this.imagePath,
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
                child: Image.asset(
                  imagePath,
                  // *** THIS IS THE FIX ***
                  height: 85, // Changed from 100
                  // *** END OF FIX ***
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 85, // Match the new height
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

// --- 3. TopRankingSection Widget (main container) ---
class TopRankingSection extends StatelessWidget {
  const TopRankingSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        //
        // *** THIS IS THE CORRECTED HEADER SECTION ***
        //
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.center, // Align center vertically
            children: [
              // --- Title Row (non-flexible) ---
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
              const SizedBox(width: 10), // Spacing
              // --- Tabs Row (wrapped to prevent overflow) ---
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  // Aligns tabs to the right side
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildRankingTab('Top', Colors.pinkAccent.shade100),
                      _buildRankingTab('Hot', Colors.transparent),
                      _buildRankingTab('Popular', Colors.transparent),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 300,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 8.0),
            children: [
              const ProductCard(
                imagePath: 'assets/images/products/prod_1.png',
                title: 'INFRA MARKET CEMENT',
                description: 'Lorem ipsum dolor sit amet....',
                rank: '1',
              ),
              // Grid of smaller product cards
              Padding(
                padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: const [
                        SmallProductCard(
                          imagePath: 'assets/images/products/prod_2.png',
                          title: 'DSOF Cream',
                          description: 'Lorem ipsum dolor..',
                          rank: '2',
                          rankColor: Colors.pinkAccent,
                        ),
                        SmallProductCard(
                          imagePath: 'assets/images/products/prod_3.png',
                          title: 'PAKL Losan',
                          description: 'Lorem ipsum dolor..',
                          rank: '3',
                          rankColor: Colors.blueAccent,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Row 2 of small cards
                    Row(
                      children: const [
                        SmallProductCard(
                          imagePath: 'assets/images/products/prod_4.png',
                          title: 'DSOF Cream',
                          description: 'Lorem ipsum dolor..',
                          rank: '4',
                          rankColor: Colors.green,
                        ),
                        SmallProductCard(
                          imagePath:
                              'assets/images/products/prod_5.png', // Use asset path
                          title: 'PAKL Losan',
                          description: 'Lorem ipsum dolor..',
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

  // Helper widget for the ranking tabs (Top, Hot, Popular)
  Widget _buildRankingTab(String text, Color backgroundColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(
          color: backgroundColor == Colors.transparent
              ? Colors.grey.shade300
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: backgroundColor == Colors.transparent
              ? Colors.grey.shade700
              : Colors.white,
          fontWeight: FontWeight.w500,
          fontSize: 12,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }
}
