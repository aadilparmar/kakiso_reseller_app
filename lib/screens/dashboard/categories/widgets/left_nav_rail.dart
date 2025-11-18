import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kakiso_reseller_app/screens/dashboard/categories/categories.dart';
import 'package:kakiso_reseller_app/utils/constants.dart' hide accentColor;

class LeftNavigationRail extends StatelessWidget {
  final int selectedIndex;
  final Function(int index, String label) onCategorySelected;

  const LeftNavigationRail({
    super.key,
    required this.selectedIndex,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: ListView.builder(
        itemCount: leftCategoriesData.length,
        itemBuilder: (ctx, idx) {
          final item = leftCategoriesData[idx];
          final bool isSelected = idx == selectedIndex;

          return GestureDetector(
            onTap: () => onCategorySelected(idx, item['label']!),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(6),
              decoration: isSelected
                  ? BoxDecoration(
                      gradient: LinearGradient(
                        colors: [accentColor.withOpacity(0.12), Colors.white],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: accentColor.withOpacity(0.12)),
                    )
                  : null,
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: isSelected
                            ? accentColor
                            : Colors.grey.shade100,
                        backgroundImage: NetworkImage(item['image']!),
                      ),
                      if (idx ==
                          0) // Highlight purely for the first item example
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color.fromARGB(255, 148, 45, 251),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Colors.black26, blurRadius: 4),
                              ],
                            ),
                            child: const Icon(
                              Iconsax.home_trend_up,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item['label']!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
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
