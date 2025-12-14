import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/screens/dashboard/product/brand/brand_details_page.dart';

class ProductBrandSection extends StatelessWidget {
  final ProductModel product;

  const ProductBrandSection({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final String? brandName = product.brandName;
    final String? brandLogoUrl = product.brandLogoUrl;

    final bool hasName = brandName != null && brandName.trim().isNotEmpty;
    final bool hasLogo =
        brandLogoUrl != null &&
        brandLogoUrl.trim().isNotEmpty &&
        brandLogoUrl.trim().startsWith('http');

    if (!hasName && !hasLogo) {
      return const SizedBox.shrink();
    }

    final String displayName = hasName ? brandName.trim() : 'Brand';

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        // 🔹 Navigate to BrandDetailsPage
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BrandDetailsPage(
              brandName: displayName,
              brandLogoUrl: hasLogo ? brandLogoUrl.trim() : null,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            // avatar / logo
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipOval(
                child: _buildLogoOrInitials(
                  displayName,
                  hasLogo ? brandLogoUrl.trim() : null,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // text
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
                    displayName,
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
                    'Tap to see more from this brand',
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'Poppins',
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Iconsax.arrow_right_3,
              size: 18,
              color: Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoOrInitials(String brandName, String? logoUrl) {
    if (logoUrl != null && logoUrl.isNotEmpty && logoUrl.startsWith('http')) {
      return Image.network(
        logoUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildInitialsAvatar(brandName),
      );
    }
    return _buildInitialsAvatar(brandName);
  }

  Widget _buildInitialsAvatar(String brandName) {
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
      ],
    );
  }
}
