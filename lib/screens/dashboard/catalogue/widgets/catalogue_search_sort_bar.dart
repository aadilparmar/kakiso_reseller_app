// lib/screens/dashboard/catalogue/widgets/catalogue_search_sort_bar.dart

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kakiso_reseller_app/screens/dashboard/catalogue/catalogue_sort.dart';

class CatalogueSearchAndSortBar extends StatelessWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final CatalogueSort currentSort;
  final ValueChanged<CatalogueSort> onSortChanged;

  const CatalogueSearchAndSortBar({
    super.key,
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.currentSort,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      color: Colors.white,
      child: Row(
        children: [
          // Search box
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 10),
                  const Icon(
                    Iconsax.search_normal_1,
                    size: 18,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      onChanged: onSearchChanged,
                      decoration: const InputDecoration(
                        hintText: "Search catalogs...",
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (searchQuery.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => onSearchChanged(''),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Sort dropdown
          PopupMenuButton<CatalogueSort>(
            tooltip: "Sort",
            onSelected: onSortChanged,
            itemBuilder: (context) => buildCatalogueSortMenuItems(),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Iconsax.sort, size: 18, color: Colors.black87),
                  const SizedBox(width: 6),
                  Text(
                    catalogueSortLabel(currentSort),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    size: 16,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
