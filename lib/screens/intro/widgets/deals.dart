import 'package:flutter/material.dart';

class _DealCard extends StatelessWidget {
  final String price;
  final Color accentColor;
  final Color purpleHeaderColor;

  const _DealCard({
    required this.price,
    required this.accentColor,
    required this.purpleHeaderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        // Padding is subtle on the card edge
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          // Slight shadow for a lift effect
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
          children: [
            // The central light purple design
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                // Use a very light purple color for the background element
                color: purpleHeaderColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                // Using a light purple blob placeholder shape
                shape: BoxShape.rectangle,
              ),
              child: Center(
                child: Column(
                  children: [
                    Text(
                      'Under',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: purpleHeaderColor, // Deep purple text
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      price,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: accentColor, // Vibrant pink text
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // See Now Link/Button
            TextButton(
              onPressed: () {
                // Action for seeing the deal
              },
              child: Text(
                'See Now',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: accentColor, // Vibrant pink link
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The main "Best Deals" section.
class KBestDealsSection extends StatelessWidget {
  final Color accentColor;
  final Color purpleHeaderColor;

  const KBestDealsSection({
    super.key,
    required this.accentColor,
    required this.purpleHeaderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // Left-align the title
      children: [
        // Title: Best Deals
        const Padding(
          padding: EdgeInsets.only(bottom: 20.0),
          child: Text(
            'Best Deals',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ),

        // Three Deal Cards in a Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _DealCard(
              price: '₹220',
              accentColor: accentColor,
              purpleHeaderColor: purpleHeaderColor,
            ),
            const SizedBox(width: 10), // Spacing between cards
            _DealCard(
              price: '₹599',
              accentColor: accentColor,
              purpleHeaderColor: purpleHeaderColor,
            ),
            const SizedBox(width: 10), // Spacing between cards
            _DealCard(
              price: '₹999',
              accentColor: accentColor,
              purpleHeaderColor: purpleHeaderColor,
            ),
          ],
        ),
      ],
    );
  }
}
