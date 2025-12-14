import 'package:flutter/material.dart';
import 'package:kakiso_reseller_app/models/categories.dart';
import 'package:kakiso_reseller_app/screens/dashboard/tools/tools.dart'; // For accentColor

class LeftNavigationRail extends StatelessWidget {
  final List<CategoryModel> categories;
  final int selectedIndex;
  final Function(int index, String label, int id) onCategorySelected;

  const LeftNavigationRail({
    super.key,
    required this.categories,
    required this.selectedIndex,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    // --- CHANGE: Use the full list directly, do not filter by parent ---
    final allCategories = categories;

    return Container(
      width: 96,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: ListView.builder(
        itemCount: allCategories.length,
        itemBuilder: (ctx, idx) {
          final item = allCategories[idx];
          final bool isSelected = idx == selectedIndex;

          return GestureDetector(
            // Pass the item.id correctly
            onTap: () => onCategorySelected(idx, item.name, item.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(6),
              decoration: isSelected
                  ? BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accentColor.withValues(alpha: 0.12),
                          Colors.white,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.12),
                      ),
                    )
                  : null,
              child: Column(
                children: [
                  // Category Image
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: isSelected
                        ? accentColor
                        : Colors.grey.shade100,
                    backgroundImage: NetworkImage(item.imageUrl),
                    onBackgroundImageError: (_, __) => const Icon(Icons.error),
                  ),
                  const SizedBox(height: 6),
                  // Category Name
                  Text(
                    item.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      // Make font bold if selected for better visibility
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.normal,
                      color: isSelected
                          ? const Color.fromARGB(255, 132, 42, 235)
                          : Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
