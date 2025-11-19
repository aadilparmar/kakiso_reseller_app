import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class HorizontalProductCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String price; // Current Selling Price
  final String originalPrice; // NEW: Original MRP
  final String companyName;
  final int? discountPercentage;
  final VoidCallback onAddToCartPressed;

  const HorizontalProductCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.price,
    required this.originalPrice, // NEW
    required this.companyName,
    this.discountPercentage,
    required this.onAddToCartPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Show discount if percentage is > 0 AND original price exists
    final bool showDiscount =
        (discountPercentage != null && discountPercentage! > 0);

    return Container(
      width: 340,
      height: 150,
      margin: const EdgeInsets.only(bottom: 12, top: 8, right: 4, left: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A317E).withOpacity(0.06),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // --- BACKGROUND ---
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.white, Color(0xFFF9FAFB)],
                  ),
                ),
              ),
            ),

            Row(
              children: [
                // --- IMAGE SECTION ---
                Container(
                  width: 130,
                  height: double.infinity,
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(4, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => Container(
                            color: Colors.grey[100],
                            child: const Icon(Icons.image, color: Colors.grey),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          height: 40,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.2),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // --- CONTENT SECTION ---
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 16, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Brand & Discount
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Iconsax.verify5,
                                    size: 12,
                                    color: Color(0xFF4A317E),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    companyName.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF6B7280),
                                      fontFamily: 'Poppins',
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (showDiscount)
                              Text(
                                '${discountPercentage!}% OFF',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFFF4C5E),
                                  fontFamily: 'Poppins',
                                ),
                              ),
                          ],
                        ),

                        // Title
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                            height: 1.3,
                            fontFamily: 'Poppins',
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        // Price & Action
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // --- REAL TIME MRP ---
                                if (showDiscount &&
                                    originalPrice.isNotEmpty &&
                                    originalPrice != price)
                                  Text(
                                    originalPrice, // The real MRP from API
                                    style: const TextStyle(
                                      fontSize: 11,
                                      decoration: TextDecoration.lineThrough,
                                      color: Color(0xFF9CA3AF),
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),

                                // Selling Price
                                Text(
                                  price,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF4A317E),
                                    fontFamily: 'Poppins',
                                    height: 1.0,
                                  ),
                                ),
                              ],
                            ),

                            GestureDetector(
                              onTap: onAddToCartPressed,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Iconsax.shopping_cart,
                                  color: Colors.white,
                                  size: 20,
                                ),
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
          ],
        ),
      ),
    );
  }
}
