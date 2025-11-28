// lib/screens/dashboard/catalogue/widgets/catalogue_search_empty_state.dart

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class CatalogueSearchEmptyState extends StatelessWidget {
  const CatalogueSearchEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Iconsax.search_normal_1,
              size: 52,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            const Text(
              "No matching catalogues",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Try a different name or clear the search.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
