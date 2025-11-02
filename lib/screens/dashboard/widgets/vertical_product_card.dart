import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

// --- NewArrivalImageCard (Square Image Only) ---
class NewArrivalImageCard extends StatelessWidget {
  final String imagePath;
  final double cardSize; // We'll pass the desired size from the parent

  const NewArrivalImageCard({
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
        borderRadius: BorderRadius.circular(2),
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
        borderRadius: BorderRadius.circular(10),
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

// --- NewArrivalSection (Main Container for this section) ---
class NewArrivalSection extends StatefulWidget {
  const NewArrivalSection({super.key});

  @override
  State<NewArrivalSection> createState() => _NewArrivalSectionState();
}

class _NewArrivalSectionState extends State<NewArrivalSection> {
  // Using a standard controller, as ListView will handle the scrolling
  final ScrollController _scrollController = ScrollController();

  // We'll track page manually for the dots if needed, but PageView is better for dots
  // For simplicity with ListView, let's remove the dot logic for now
  // as it doesn't align well with a free-scrolling list.

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // This fixed card width is key to the "2.5 items" look
    final double cardWidth = 130.0;
    final double horizontalItemSpacing = 16.0; // Space between cards

    //
    // --- THIS IS THE FIX ---
    //
    final double textHeight = 80.0; // Increased from 50.0 to 80.0
    //
    // --- END OF FIX ---
    //

    // Total height needed for one card + its text
    final double totalItemHeight =
        cardWidth + 10 + textHeight; // Card + spacing + text

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
                    'New',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Arrival',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.pinkAccent,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Iconsax.bag_happy, color: Colors.orange, size: 24),
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
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            // Add padding so the list starts from the left edge (like the image)
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: newArrivalProducts.length,
            itemBuilder: (context, index) {
              final product = newArrivalProducts[index];
              return Container(
                // Use margin to create space *between* items
                margin: EdgeInsets.only(
                  right: (index == newArrivalProducts.length - 1)
                      ? 0
                      : horizontalItemSpacing,
                ),
                width: cardWidth, // Set the fixed width for the item
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    NewArrivalImageCard(
                      imagePath: product['image']!,
                      cardSize: cardWidth, // Pass the fixed card width
                    ),
                    const SizedBox(height: 10), // Space between image and text
                    // The text column now fits inside the 80.0px height
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

        // I removed the pagination dots, as they don't work well
        // with a free-scrolling ListView. PageView is required for that.
        // This ListView matches your visual layout of "2.5 items" better.
        const SizedBox(height: 16), // Padding at the bottom
      ],
    );
  }
}
