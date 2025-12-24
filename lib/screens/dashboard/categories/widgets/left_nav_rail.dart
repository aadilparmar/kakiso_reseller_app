import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kakiso_reseller_app/models/categories.dart';

class LeftNavigationRail extends StatefulWidget {
  final List<CategoryModel> parentCategories;
  // Use ID for selection logic, not list index, for safer database mapping
  final int selectedCategoryId;
  final Function(int index, String label, int id) onCategorySelected;
  final Color accentColor;

  const LeftNavigationRail({
    super.key,
    required this.parentCategories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
    this.accentColor = const Color(0xFF6C63FF),
  });

  @override
  State<LeftNavigationRail> createState() => _LeftNavigationRailState();
}

class _LeftNavigationRailState extends State<LeftNavigationRail> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // Post-frame callback to scroll to the initially selected item
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
  }

  @override
  void didUpdateWidget(covariant LeftNavigationRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCategoryId != widget.selectedCategoryId) {
      _scrollToSelected();
    }
  }

  void _scrollToSelected() {
    final index = widget.parentCategories.indexWhere(
      (c) => c.id == widget.selectedCategoryId,
    );

    if (index != -1 && _scrollController.hasClients) {
      // 112.0 is the itemExtent defined below
      const double itemHeight = 112.0;
      final double targetOffset = index * itemHeight;
      final double screenHeight = MediaQuery.of(context).size.height;

      // Only scroll if the item is likely out of view
      if (targetOffset < _scrollController.offset ||
          targetOffset > _scrollController.offset + screenHeight - 200) {
        _scrollController.animateTo(
          targetOffset - (screenHeight / 2) + (itemHeight / 2), // Center it
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100, // Slightly wider for better touch targets
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC), // Softer grey/blue tint
        border: Border(
          right: BorderSide(color: Colors.grey.shade200, width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(
                context,
              ).copyWith(overscroll: false),
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 24),
                itemCount: widget.parentCategories.length,
                // ⚡ OPTIMIZATION: Kept fixed extent for performance
                itemExtent: 112.0,
                itemBuilder: (context, index) {
                  final item = widget.parentCategories[index];
                  final bool isSelected = item.id == widget.selectedCategoryId;

                  // Example Logic: Add a badge if the name contains specific keywords
                  // In a real app, this would come from the model (e.g., item.badgeText)
                  String? badgeText;
                  if (item.name.toLowerCase().contains('sale'))
                    badgeText = 'SALE';
                  if (item.name.toLowerCase().contains('new'))
                    badgeText = 'NEW';

                  return RepaintBoundary(
                    child: _CategoryRailItem(
                      item: item,
                      isSelected: isSelected,
                      accentColor: widget.accentColor,
                      badgeText: badgeText,
                      onTap: () {
                        HapticFeedback.lightImpact(); // lighter feedback is more premium
                        widget.onCategorySelected(index, item.name, item.id);
                      },
                    ),
                  );
                },
              ),
            ),
          ),
          // Optional: Bottom fading indicator if list is long
          Container(
            height: 20,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFFF7F9FC).withOpacity(0),
                  const Color(0xFFF7F9FC),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryRailItem extends StatelessWidget {
  final CategoryModel item;
  final bool isSelected;
  final VoidCallback onTap;
  final Color accentColor;
  final String? badgeText;

  const _CategoryRailItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.accentColor,
    this.badgeText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 8, right: 8),
      // Material & InkWell allows for standard ripple effects
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: accentColor.withOpacity(0.1),
          highlightColor: accentColor.withOpacity(0.05),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // BACKGROUND & ACTIVE STATE
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? accentColor.withOpacity(0.1)
                        : Colors.transparent,
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: accentColor.withOpacity(0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // IMAGE CONTAINER
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: isSelected ? 50 : 44,
                        height: isSelected ? 50 : 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? Colors.grey.shade50
                              : Colors.white,
                          boxShadow: isSelected
                              ? []
                              : [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                        ),
                        child: ClipOval(
                          child: Padding(
                            padding: const EdgeInsets.all(
                              2.0,
                            ), // Padding inside circle
                            child: ClipOval(
                              child: Image.network(
                                item.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.image_not_supported_outlined,
                                  size: 20,
                                  color: Colors.grey.shade300,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // LABEL
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: isSelected ? 11 : 10,
                            height: 1.2,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? accentColor
                                : Colors.grey.shade500,
                            letterSpacing: isSelected ? 0 : 0.2,
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
              ),

              // ACTIVE INDICATOR (Left bar)
              Positioned(
                left: 0,
                top: 30,
                bottom: 30,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutQuart,
                  width: isSelected ? 3 : 0,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(4),
                      bottomRight: Radius.circular(4),
                    ),
                  ),
                ),
              ),

              // NOTIFICATION BADGE (If applicable)
              if (badgeText != null)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5A5F), // Coral red for alerts
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF5A5F).withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      badgeText!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
