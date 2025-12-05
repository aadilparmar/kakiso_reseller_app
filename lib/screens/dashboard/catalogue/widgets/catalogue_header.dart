// lib/screens/dashboard/catalogue/widgets/catalogue_header.dart

import 'package:flutter/material.dart';

class CatalogueHeader extends StatelessWidget {
  final int totalCatalogues;
  final int totalProducts;

  const CatalogueHeader({
    super.key,
    required this.totalCatalogues,
    required this.totalProducts,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "My Catalog",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            "$totalCatalogues cat • $totalProducts items",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
