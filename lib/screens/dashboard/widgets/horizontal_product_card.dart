import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import 'package:kakiso_reseller_app/controllers/cart_controller.dart'; // For ImageFilter

class HorizontalProductCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String price;
  final String companyName;
  final int? discountPercentage;
  final VoidCallback onAddToCartPressed;

  const HorizontalProductCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.price,
    required this.companyName,
    this.discountPercentage,
    required this.onAddToCartPressed,
  });

  @override
  Widget build(BuildContext context) {
    final bool showDiscount =
        discountPercentage != null && discountPercentage! > 0;
    Get.put(CartController());
    return Container(
      // Slightly wider for better breathing room
      width: 340,
      height: 150,
      margin: const EdgeInsets.only(
        bottom: 12,
        top: 8,
        right: 4,
        left: 4,
      ), // Breathing room for shadow
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          // Soft, multi-layered shadow for depth
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
            // --- 1. BACKGROUND DECORATION (Subtle Gradient) ---
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      const Color(0xFFF9FAFB), // Very subtle grey-blue tint
                    ],
                  ),
                ),
              ),
            ),

            Row(
              children: [
                // --- 2. IMAGE SECTION (Left) ---
                Container(
                  width: 130,
                  height: double.infinity,
                  margin: const EdgeInsets.all(8), // Padding inside the card
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
                        // The Image
                        Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => Container(
                            color: Colors.grey[100],
                            child: const Icon(Icons.image, color: Colors.grey),
                          ),
                        ),
                        // Subtle gradient overlay on image bottom for depth
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

                // --- 3. CONTENT SECTION (Right) ---
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 16, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Top: Brand & Discount
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Brand Tag
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

                            // Discount (Text only to save space, cleaner look)
                            if (showDiscount)
                              Text(
                                '${discountPercentage!}% OFF',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFFF4C5E), // Alert color
                                  fontFamily: 'Poppins',
                                ),
                              ),
                          ],
                        ),

                        // Middle: Title
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827), // Near Black
                            height: 1.3,
                            fontFamily: 'Poppins',
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        // Bottom: Price & Button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (showDiscount)
                                  const Text(
                                    '₹1,499', // Dummy original price
                                    style: TextStyle(
                                      fontSize: 11,
                                      decoration: TextDecoration.lineThrough,
                                      color: Color(0xFF9CA3AF),
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                Text(
                                  price,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF4A317E), // Brand Primary
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
                                  Iconsax
                                      .shopping_bag, // Bag icon feels more "premium retail"
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
