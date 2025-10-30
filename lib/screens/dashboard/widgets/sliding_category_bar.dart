import 'package:flutter/material.dart';

// --- Colors for the Sort Bar (NEW UI) ---
const Color _barBackgroundColor = Color.fromARGB(
  255,
  73,
  49,
  126,
); // Dark purple
const Color _activeIndicatorColor = Color.fromARGB(
  255,
  255,
  255,
  255,
); // White/light grey pill
const Color _activeItemColor = Color(0xFF4A317E);
const Color _inactiveItemColor = Colors.white;

/// A data model for the categories
class ProductCategory {
  // Allow imageAssetPath and label to be null
  final String? imageAssetPath;
  final String? label;

  ProductCategory({this.imageAssetPath, this.label});
}

/// A horizontally scrolling bar for sorting products by category.
class SlidingCategoryBar extends StatefulWidget {
  final List<ProductCategory> categories;
  final Function(int, String) onCategorySelected;

  const SlidingCategoryBar({
    super.key,
    required this.categories,
    required this.onCategorySelected,
  });

  @override
  State<SlidingCategoryBar> createState() => _SlidingCategoryBarState();
}

class _SlidingCategoryBarState extends State<SlidingCategoryBar>
    with TickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.categories.length,
      vsync: this,
    );

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final index = _tabController.index;
        final label = widget.categories[index].label ?? '';
        widget.onCategorySelected(index, label);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70, // Total height of the bar
      color: _barBackgroundColor,
      padding: const EdgeInsets.only(top: 10.0), // Your existing padding
      child: Align(
        alignment: Alignment.topCenter,
        child: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.center, // Your existing alignment
          // --- Hides both white lines ---
          indicatorColor: Colors.transparent,
          dividerColor: Colors.transparent,

          // Your custom "pill" indicator
          indicator: BoxDecoration(
            color: _activeIndicatorColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: _activeItemColor,
          unselectedLabelColor: _inactiveItemColor,

          // --- Your existing styles ---
          labelStyle: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
            height: 1.1, // Constrains vertical text space
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
            height: 1.1, // Constrains vertical text space
          ),

          // --- Generate the tabs ---
          tabs: widget.categories.map((category) {
            return Tab(
              // --- OVERFLOW FIX: Set the Tab's height property ---
              // This is the correct way to make the tab taller.
              height: 58,
              child: Builder(
                // The Container(height: 58) wrapper was removed
                builder: (BuildContext context) {
                  final Color itemColor = IconTheme.of(context).color!;

                  final bool hasImage =
                      category.imageAssetPath != null &&
                      category.imageAssetPath!.isNotEmpty;

                  // Create the fallback widget
                  final Widget fallbackIcon = Icon(
                    Icons.image_not_supported_outlined,
                    // --- Match fallback icon size ---
                    size: 40,
                    color: itemColor,
                  );

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      hasImage
                          ? Image.asset(
                              category.imageAssetPath!,
                              // --- Make image bigger ---
                              width: 40,
                              height: 40,
                              fit: BoxFit.contain,
                              // Catches "Asset not found" errors
                              errorBuilder: (context, error, stackTrace) {
                                return fallbackIcon;
                              },
                            )
                          : fallbackIcon, // Show fallback if path is null/empty
                      const SizedBox(height: 4.0),
                      Text(
                        category.label ?? '', // Null check
                      ),
                    ],
                  );
                },
              ),
            );
          }).toList(),

          onTap: (index) {
            final label = widget.categories[index].label ?? '';
            widget.onCategorySelected(index, label);
          },
        ),
      ),
    );
  }
}
