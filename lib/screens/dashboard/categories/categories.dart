import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kakiso_reseller_app/screens/dashboard/categories/widgets/left_nav_rail.dart';
import 'package:kakiso_reseller_app/screens/dashboard/tools/tools.dart';
import 'package:kakiso_reseller_app/services/api_services.dart';

// Internal Imports
import 'package:kakiso_reseller_app/models/categories.dart';

import 'widgets/search_and_filter_bar.dart';
import 'widgets/filter_chips_list.dart';
import 'widgets/category_grid.dart';
import 'package:kakiso_reseller_app/screens/dashboard/my_cart/my_cart.dart';

class CategoriesSection extends StatefulWidget {
  const CategoriesSection({super.key});

  @override
  State<CategoriesSection> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesSection> {
  bool isLoading = true;
  List<CategoryModel> _allCategories = [];
  String? errorMessage;

  int selectedIndex = 0;
  String selectedCategoryLabel = 'All';

  // NEW: Track which Parent ID is selected
  int selectedParentId = 0;

  final TextEditingController _searchController = TextEditingController();
  final Set<int> favorites = {};
  final List<String> activeFilters = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await ApiService.fetchCategories();
      setState(() {
        _allCategories = cats;
        isLoading = false;

        // Logic: Find the first Parent Category and select it by default
        if (cats.isNotEmpty) {
          final parents = cats.where((c) => c.parent == 0).toList();
          if (parents.isNotEmpty) {
            selectedCategoryLabel = parents[0].name;
            selectedParentId = parents[0].id; // Set Default Parent ID
          }
        }
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Logic: Show only sub-categories of the selected parent
  List<CategoryModel> get _filteredGrid {
    final q = _searchController.text.toLowerCase().trim();

    return _allCategories.where((cat) {
      // 1. Search Check
      final matchesQuery = q.isEmpty
          ? true
          : cat.name.toLowerCase().contains(q);

      // 2. Parent Check: Is this category a child of the selected left-rail item?
      final isChildOfSelected = cat.parent == selectedParentId;

      return matchesQuery && isChildOfSelected;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                color: accentColor,
                iconSize: 30,
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Image.asset(
                'assets/logos/login-logo.png',
                height: 22,
                fit: BoxFit.contain,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Iconsax.notification_bing),
              color: accentColor,
              iconSize: 30,
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Iconsax.shopping_cart),
              color: accentColor,
              iconSize: 30,
              onPressed: () => Get.to(() => const InventoryPage()),
            ),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: accentColor))
          : errorMessage != null
          ? Center(child: Text("Error: $errorMessage"))
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. LEFT RAIL
                LeftNavigationRail(
                  categories: _allCategories,
                  selectedIndex: selectedIndex,
                  // UPDATE: Receive ID here
                  onCategorySelected: (index, label, id) {
                    setState(() {
                      selectedIndex = index;
                      selectedCategoryLabel = label;
                      selectedParentId = id; // Update the ID to filter the grid
                    });
                  },
                ),

                // 2. RIGHT CONTENT
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SearchAndFilterBar(
                          controller: _searchController,
                          onChanged: () => setState(() {}),
                          onClear: () =>
                              setState(() => _searchController.clear()),
                        ),
                        const SizedBox(height: 12),

                        FilterChipsList(
                          activeFilters: activeFilters,
                          onSelected: (label, isSelected) {
                            setState(() {
                              if (isSelected) {
                                activeFilters.add(label);
                              } else {
                                activeFilters.remove(label);
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 14),

                        // const FeaturedSection(),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                selectedCategoryLabel,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              '${_filteredGrid.length} items',
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // GRID
                        Expanded(
                          child: CategoryGrid(
                            categories: _filteredGrid,
                            favorites: favorites,
                            onFavoriteToggle: (id) {
                              setState(() {
                                if (favorites.contains(id)) {
                                  favorites.remove(id);
                                } else {
                                  favorites.add(id);
                                }
                              });
                            },
                            items: [],
                          ),
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
