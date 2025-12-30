import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kakiso_reseller_app/models/categories.dart';

class LeftNavigationRail extends StatefulWidget {
  final List<CategoryModel> parentCategories;
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
      // Increased item extent to accommodate larger images + text
      const double itemHeight = 140.0;
      final double targetOffset = index * itemHeight;
      final double screenHeight = MediaQuery.of(context).size.height;

      if (targetOffset < _scrollController.offset ||
          targetOffset > _scrollController.offset + screenHeight - 200) {
        _scrollController.animateTo(
          targetOffset - (screenHeight / 2) + (itemHeight / 2),
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
    // Increased width to 116 to let the images breathe
    return Container(
      width: 116,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA), // Very subtle cool grey
        border: Border(
          right: BorderSide(color: Colors.grey.shade200, width: 1),
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
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 24),
                itemCount: widget.parentCategories.length,
                itemExtent: 140.0, // Taller items
                itemBuilder: (context, index) {
                  final item = widget.parentCategories[index];
                  final bool isSelected = item.id == widget.selectedCategoryId;

                  // Badge Logic
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
                        HapticFeedback.selectionClick();
                        widget.onCategorySelected(index, item.name, item.id);
                      },
                    ),
                  );
                },
              ),
            ),
          ),

          // Bottom Fade
          Container(
            height: 30,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFFF5F7FA).withOpacity(0),
                  const Color(0xFFF5F7FA),
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
    // We use a transparent container with padding to allow the ripple to fill nicely
    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 8, right: 8),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. The Main Card / Touch Area
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
              splashColor: accentColor.withOpacity(0.1),
              highlightColor: accentColor.withOpacity(0.05),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  // Only show shadow when selected to lift it up
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                          BoxShadow(
                            color: accentColor.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 2. The Big Image (Rounded Square)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutBack,
                        // Significantly bigger dimensions
                        width: isSelected ? 76 : 68,
                        height: isSelected ? 76 : 68,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                            18,
                          ), // Smooth corners
                          boxShadow: isSelected
                              ? [] // No shadow on image if card has shadow
                              : [
                                  // Subtle shadow for unselected items to give depth
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Background color placeholder
                              Container(color: Colors.grey.shade100),
                              // The Image
                              Image.network(
                                item.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Icon(
                                    Icons.image_not_supported_rounded,
                                    size: 28,
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                              ),
                              // Selection Overlay (optional tint)
                              if (isSelected)
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.black.withOpacity(0.04),
                                      width: 1,
                                    ),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // 3. The Label
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            // Slightly bigger font for readability
                            fontSize: isSelected ? 12 : 11,
                            height: 1.1,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? const Color(0xFF2D3748)
                                : const Color(0xFF718096),
                            letterSpacing: -0.2,
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
            ),
          ),

          // 4. Active Indicator (Vertical Pill)
          Positioned(
            left: 0,
            top: 40,
            bottom: 40,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.elasticOut,
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

          // 5. Badge (Sale/New)
          if (badgeText != null)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFF7E5F),
                      Color(0xFFFF5A5F),
                    ], // Nice coral gradient
                  ),
                  borderRadius: BorderRadius.circular(12),
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
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
