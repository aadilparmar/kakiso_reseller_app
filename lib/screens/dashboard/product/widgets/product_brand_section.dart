import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/utils/constants.dart';

class ProductBrandSection extends StatelessWidget {
  final ProductModel product;

  const ProductBrandSection({super.key, required this.product});

  String? _extractBrandName() {
    // 1) Prefer the parsed brandName from ProductModel
    if (product.brandName != null && product.brandName!.trim().isNotEmpty) {
      return product.brandName!.trim();
    }

    // 2) Fallback: look in attributes if needed
    for (final attr in product.attributes) {
      final nameLower = attr.name.toLowerCase();
      if (nameLower.contains('brand')) {
        if (attr.options.isNotEmpty) {
          return attr.options.first;
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final brandName = _extractBrandName();

    // If this product does not have any brand-related data, hide the section.
    if (brandName == null || brandName.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          // --- Logo / initials avatar ---
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: _buildBrandAvatar(brandName),
          ),

          const SizedBox(width: 12),

          // --- Brand text ---
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Brand',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF9CA3AF),
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  brandName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'From a trusted catalogue brand',
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'Poppins',
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),

          const Icon(Iconsax.verify5, size: 20, color: accentColor),
        ],
      ),
    );
  }

  Widget _buildBrandAvatar(String brandName) {
    if (product.brandLogoUrl != null &&
        product.brandLogoUrl!.trim().isNotEmpty) {
      // If we have a brand logo URL, show it
      return ClipOval(
        child: Image.network(
          product.brandLogoUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildInitials(brandName),
        ),
      );
    }

    // Fallback: initials avatar
    return _buildInitials(brandName);
  }

  Widget _buildInitials(String brandName) {
    final initials = brandName
        .trim()
        .split(' ')
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0])
        .join()
        .toUpperCase();

    return Stack(
      alignment: Alignment.center,
      children: [
        Text(
          initials,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        Positioned(
          bottom: 4,
          right: 6,
          child: Container(
            width: 14,
            height: 14,
            decoration: const BoxDecoration(
              color: accentColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(Iconsax.star5, size: 10, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
