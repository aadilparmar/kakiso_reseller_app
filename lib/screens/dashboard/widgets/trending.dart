import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

// --- TrendingImageCard (Square Image Only) ---
class TrendingImageCard extends StatelessWidget {
  final String imagePath;
  final double cardSize; // We'll pass the desired size from the parent

  const TrendingImageCard({
    super.key,
    required this.imagePath,
    this.cardSize = 130.0, // Default size
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: cardSize,
      height: cardSize, // Make it square
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(2), // This is 2
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        // --- FIX: Changed from 10 to 2 to match the container ---
        borderRadius: BorderRadius.circular(2),
        child: Image.asset(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[200],
              child: Icon(Icons.broken_image, color: Colors.grey[400]),
            );
          },
        ),
      ),
    );
  }
}

// --- Trending (Main Container for this section) ---
class TrendingProducts extends StatefulWidget {
  const TrendingProducts({super.key});

  @override
  State<TrendingProducts> createState() => _TrendingProductsState();
}

class _TrendingProductsState extends State<TrendingProducts> {
  //
  // --- Controller is now correctly initialized ---
  //
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double cardWidth = 130.0;
    final double horizontalItemSpacing = 16.0;
    final double textHeight = 80.0;
    final double totalItemHeight = cardWidth + 10 + textHeight;

    final List<Map<String, String>> newArrivalProducts = [
      {
        'image': 'assets/images/products/prod_6.png',
        'title': 'Kids Soft Toys Collection',
        'description': 'Lorem ipsum dolor sit amet....',
      },
      {
        'image': 'assets/images/products/prod_7.png',
        'title': 'Soft Plush Monkey Toy',
        'description': 'Lorem ipsum dolor sit amet....',
      },
      {
        'image': 'assets/images/products/prod_8.jpg',
        'title': 'Art & Craft Supply Kit',
        'description': 'Lorem ipsum dolor sit amet....',
      },
      {
        'image': 'assets/images/products/prod_9.jpg',
        'title': 'Building Blocks Fun Set',
        'description': 'Lorem ipsum dolor sit amet....',
      },
      {
        'image': 'assets/images/products/prod_10.jpg',
        'title': 'Teddy Bear with Accessories',
        'description': 'Lorem ipsum dolor sit amet....',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header: "New Arrival" and "See all"
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Text(
                    'Trending on',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'KakiSo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.pinkAccent,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Iconsax.trend_up, color: Colors.green, size: 24),
                ],
              ),
              GestureDetector(
                onTap: () {},
                child: const Text(
                  'See all',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.pinkAccent,
                    fontFamily: 'Poppins',
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Horizontal Product List
        SizedBox(
          height: totalItemHeight, // Use the calculated total height
          child: ListView.builder(
            controller: _scrollController, // Now correctly initialized
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: newArrivalProducts.length,
            itemBuilder: (context, index) {
              final product = newArrivalProducts[index];
              return Container(
                margin: EdgeInsets.only(
                  right: (index == newArrivalProducts.length - 1)
                      ? 0
                      : horizontalItemSpacing,
                ),
                width: cardWidth, // Set the fixed width for the item
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TrendingImageCard(
                      imagePath: product['image']!,
                      cardSize: cardWidth, // Pass the fixed card width
                    ),
                    const SizedBox(height: 10), // Space between image and text
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product['title']!,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            fontFamily: 'Poppins',
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          product['description']!,
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
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16), // Padding at the bottom
      ],
    );
  }
}
