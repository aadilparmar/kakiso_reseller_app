import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/utils/constants.dart';

class ProductInfoHeader extends StatelessWidget {
  final ProductModel product;

  const ProductInfoHeader({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- 1. TOP ROW: BRAND & RATING ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // "Best Seller" / Brand Tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accentColor, accentColor.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Iconsax.medal_star, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text(
                    "BEST SELLER",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                      fontFamily: 'Poppins',
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            // Rating Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Iconsax.star1, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    "4.8",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.grey.shade900,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    height: 10,
                    width: 1,
                    color: Colors.grey.shade300,
                  ),
                  Text(
                    "2.3k Reviews",
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // --- 2. PRODUCT NAME ---
        Text(
          product.name,
          style: const TextStyle(
            fontSize: 24,
            fontWeight:
                FontWeight.w700, // Slightly lighter than w800 for readability
            fontFamily: 'Poppins',
            height: 1.3,
            color: Color(0xFF1F2937), // Dark Grey > Pure Black
            letterSpacing: -0.5,
          ),
        ),

        const SizedBox(height: 12),

        // --- 3. PRICE & OFFERS ---
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Main Price
            Text(
              "₹${product.price}",
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                fontFamily: 'Poppins',
                color: Colors.black, // Focus Color
                height: 1.0,
              ),
            ),
            const SizedBox(width: 12),

            // MRP Strikethrough
            if (product.regularPrice.isNotEmpty &&
                product.regularPrice != product.price)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  "MRP ₹${product.regularPrice}",
                  style: TextStyle(
                    fontSize: 14,
                    decoration: TextDecoration.lineThrough,
                    color: Colors.grey.shade400,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            const Spacer(),

            // Discount Badge
            if (product.discountPercentage != null &&
                product.discountPercentage! > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5), // Light Green
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF10B981).withOpacity(0.2),
                  ),
                ),
                child: Text(
                  "${product.discountPercentage}% OFF",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF059669), // Green Text
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 8),

        // --- 4. "INCLUSIVE OF TAXES" SUBTEXT ---
        const Text(
          "Inclusive of all taxes • Free Shipping",
          style: TextStyle(
            color: Color(0xFF10B981), // Green
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
