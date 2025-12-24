import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
import 'package:kakiso_reseller_app/models/categories.dart';
import 'package:kakiso_reseller_app/screens/dashboard/tools/tools.dart';

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
    // 1. FILTER: Only show Parent Categories (parentId == 0)
    final List<CategoryModel> parentCategories = categories
        .where((item) => item.parent == 0)
        .toList();

    return Container(
      width: 96,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F7), // Very subtle cool grey
        border: Border(
          right: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(
                context,
              ).copyWith(overscroll: false),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 16),
                itemCount: parentCategories.length,
                itemBuilder: (context, index) {
                  final item = parentCategories[index];
                  final bool isSelected = index == selectedIndex;

                  return _CategoryRailItem(
                    item: item,
                    isSelected: isSelected,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onCategorySelected(index, item.name, item.id);
                    },
                  );
                },
              ),
            ),
          ),
          // Safety padding for bottom nav
          const SizedBox(height: kBottomNavigationBarHeight * 0.2),
        ],
      ),
    );
  }
}

class _CategoryRailItem extends StatelessWidget {
  final CategoryModel item;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryRailItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, left: 8, right: 8),
        height: 100, // Fixed height for consistency
        child: Stack(
          children: [
            // BACKGROUND CARD WITH ANIMATION
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
            ),

            // CONTENT
            Align(
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ANIMATED IMAGE CONTAINER
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: isSelected ? 48 : 42,
                    height: isSelected ? 48 : 42,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? Colors.grey.shade100
                            : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        item.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey.shade200,
                          child: Icon(
                            Icons.broken_image_rounded,
                            size: 20,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // TEXT
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        height: 1.2,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected ? accentColor : Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      child: Text(item.name),
                    ),
                  ),
                ],
              ),
            ),

            // ACTIVE INDICATOR (The "Pill" on the left)
            Positioned(
              left: 0,
              top: 25,
              bottom: 25,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                // CHANGED THIS CURVE to avoid negative overshoot
                curve: Curves.easeOutQuart,
                width: isSelected ? 4 : 0,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(4),
                    bottomRight: Radius.circular(4),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
