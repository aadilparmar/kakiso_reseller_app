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
        // Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildTag("BEST SELLER", accentColor),
            Row(
              children: [
                const Icon(Iconsax.star1, color: Colors.amber, size: 18),
                const SizedBox(width: 4),
                Text(
                  "4.8",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.grey.shade900,
                  ),
                ),
                Text(
                  " (120)",
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Product Name
        Text(
          product.name,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            fontFamily: 'Poppins',
            height: 1.2,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),

        // Price Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "₹${product.price}",
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                fontFamily: 'Poppins',
                color: accentColor,
                height: 1.0,
              ),
            ),
            const SizedBox(width: 12),
            if (product.regularPrice.isNotEmpty &&
                product.regularPrice != product.price)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  "₹${product.regularPrice}",
                  style: TextStyle(
                    fontSize: 18,
                    decoration: TextDecoration.lineThrough,
                    color: Colors.grey.shade400,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            const Spacer(),
            if (product.discountPercentage != null &&
                product.discountPercentage! > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "${product.discountPercentage}% SAVE",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.green,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
          fontFamily: 'Poppins',
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
