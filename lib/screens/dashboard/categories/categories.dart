// lib/main.dart
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kakiso_reseller_app/screens/dashboard/my_cart/my_cart.dart';

// accent color used across the file

const Color accentColor = Color(0xFFEB2A7E); // vibrant pink

class CategoriesSection extends StatefulWidget {
  const CategoriesSection({super.key});
  @override
  State<CategoriesSection> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesSection>
    with SingleTickerProviderStateMixin {
  int selectedIndex = 0;
  String selectedCategoryLabel = 'Popular'; // <-- new state for header
  final TextEditingController _searchController = TextEditingController();
  final Set<String> favorites = {};
  final List<String> activeFilters = [];

  final List<Map<String, String>> leftCategories = [
    {'image': 'https://i.imgur.com/4Z7b2zI.png', 'label': 'Popular'},
    {
      'image': 'https://i.imgur.com/5zXg2y2.png',
      'label': 'Kurti, Saree & L...',
    },
    {'image': 'https://i.imgur.com/0Xq7g1V.png', 'label': 'Women Western'},
    {'image': 'https://i.imgur.com/E7u1D7R.png', 'label': 'Lingerie'},
    {'image': 'https://i.imgur.com/5u6jL6B.png', 'label': 'Men'},
    {'image': 'https://i.imgur.com/1iQkW2b.png', 'label': 'Kids & Toys'},
    {'image': 'https://i.imgur.com/9yYp7qR.png', 'label': 'Home & Kitchen'},
  ];

  final List<Map<String, String>> gridCategories = [
    {'image': 'https://i.imgur.com/3aXk3kK.png', 'label': 'Smartphones'},
    {'image': 'https://i.imgur.com/lKJiT77.png', 'label': 'Top Brands'},
    {'image': 'https://i.imgur.com/6JcZQ5f.png', 'label': 'Premium Collection'},
    {
      'image': 'https://i.imgur.com/6s9Vqk1.png',
      'label': 'Kurtis & Dress Materials',
    },
    {'image': 'https://i.imgur.com/9HqQY8s.png', 'label': 'Sarees'},
    {'image': 'https://i.imgur.com/3c1t1wM.png', 'label': 'Westernwear'},
    {'image': 'https://i.imgur.com/2Ztq3Kk.png', 'label': 'Jewellery'},
    {'image': 'https://i.imgur.com/7u3m1fG.png', 'label': 'Men Fashion'},
    {'image': 'https://i.imgur.com/8i7F3eY.png', 'label': 'Kids'},
    {'image': 'https://i.imgur.com/0xQj4aP.png', 'label': 'Footwear'},
    {
      'image': 'https://i.imgur.com/4Yp0x5S.png',
      'label': 'Beauty & Personal Care',
    },
    {'image': 'https://i.imgur.com/TU9jK0D.png', 'label': 'Grocery'},
    {'image': 'https://i.imgur.com/5qF8Z0v.png', 'label': 'Accessories'},
    {'image': 'https://i.imgur.com/1f7k7bL.png', 'label': 'Electronics'},
    {
      'image': 'https://i.imgur.com/2mCz8D3.png',
      'label': 'Home Decor & Imp...',
    },
  ];

  final List<String> _allFilters = [
    'Trending',
    'New',
    'Under ₹999',
    'Best Seller',
    'Handmade',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, String>> get _filteredGrid {
    final q = _searchController.text.toLowerCase().trim();
    if (q.isEmpty && activeFilters.isEmpty) return gridCategories;
    return gridCategories.where((g) {
      final label = g['label']!.toLowerCase();
      final matchesQuery = q.isEmpty ? true : label.contains(q);
      final matchesFilters = activeFilters.isEmpty
          ? true
          : activeFilters.any(
              (f) => label.contains(f.toLowerCase().split(' ').first),
            );
      return matchesQuery && matchesFilters;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final double leftRailWidth = 96;
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      // You may add a Drawer if needed (omitted for brevity)
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        // We use 'title' as a full-width container for all elements
        title: Row(
          children: [
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                color: accentColor,
                iconSize: 30,
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
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
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Iconsax.profile_circle),
              color: accentColor,
              iconSize: 30,
              onPressed: () {},
            ),
            const SizedBox(width: 8),
          ],
        ),
        titleSpacing: 0,
        automaticallyImplyLeading: false,
      ),
      body: Row(
        children: [
          // LEFT RAIL
          Container(
            width: leftRailWidth,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: leftCategories.length,
                    itemBuilder: (ctx, idx) {
                      final item = leftCategories[idx];
                      final bool isSelected = idx == selectedIndex;
                      return GestureDetector(
                        onTap: () {
                          // <-- update selected index AND selectedCategoryLabel
                          setState(() {
                            selectedIndex = idx;
                            selectedCategoryLabel =
                                leftCategories[idx]['label']!;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.all(6),
                          decoration: isSelected
                              ? BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      accentColor.withOpacity(0.12),
                                      Colors.white,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: accentColor.withOpacity(0.12),
                                  ),
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
                                    backgroundImage: NetworkImage(
                                      item['image']!,
                                    ),
                                  ),
                                  if (idx == 0)
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: const Color.fromARGB(
                                            255,
                                            148,
                                            45,
                                            251,
                                          ),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black26,
                                              blurRadius: 4,
                                              offset: Offset(0, 1),
                                            ),
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
                              SizedBox(
                                width: leftRailWidth - 18,
                                child: Text(
                                  item['label']!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isSelected
                                        ? const Color.fromARGB(
                                            255,
                                            132,
                                            42,
                                            235,
                                          )
                                        : Colors.black87,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // RIGHT CONTENT
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Search + filter button row
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 255, 255, 255),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 12),
                              const Icon(
                                Iconsax.search_normal,
                                color: Colors.black54,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  onChanged: (_) => setState(() {}),
                                  decoration: const InputDecoration(
                                    hintText: 'Search',
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                              if (_searchController.text.isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.close, size: 20),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () =>
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Filters coming soon'),
                              ),
                            ),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          backgroundColor: const Color.fromARGB(
                            255,
                            255,
                            255,
                            255,
                          ),
                        ),
                        child: Row(
                          children: const [
                            Icon(Iconsax.filter, size: 20),
                            SizedBox(height: 15),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Filter chips
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _allFilters.map((f) {
                        final active = activeFilters.contains(f);
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: FilterChip(
                            label: Text(f),
                            selected: active,
                            onSelected: (v) => setState(
                              () => v
                                  ? activeFilters.add(f)
                                  : activeFilters.remove(f),
                            ),
                            selectedColor: accentColor.withOpacity(0.16),
                            backgroundColor: Colors.grey.shade100,
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Featured section (fixed heights to avoid overflows)
                  SizedBox(
                    height: 150,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Featured On KaKiSo',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {},
                              child: const Text('View all'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // horizontal list with explicit height
                        SizedBox(
                          height: 84, // exact height the cards will fill
                          child: ListView(
                            padding: const EdgeInsets.symmetric(
                              vertical: 6,
                              horizontal: 2,
                            ),
                            scrollDirection: Axis.horizontal,
                            children: const [
                              _FeaturedCard(
                                title: 'Smartphones',
                                subtitle: 'Up to 50% off',
                              ),
                              SizedBox(width: 12),
                              _FeaturedCard(
                                title: 'Top Brands',
                                subtitle: 'Premium picks',
                              ),
                              SizedBox(width: 12),
                              _FeaturedCard(
                                title: 'Premium Collection',
                                subtitle: 'New arrivals',
                              ),
                              SizedBox(width: 12),
                              _FeaturedCard(
                                title: 'Sarees',
                                subtitle: 'Beautiful prints',
                              ),
                              SizedBox(width: 12),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // <-- Dynamic heading: shows the selected left-category label -->
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

                  // Grid of categories/products
                  Expanded(
                    child: GridView.builder(
                      itemCount: _filteredGrid.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: screenWidth > 1100
                            ? 5
                            : (screenWidth > 800
                                  ? 4
                                  : (screenWidth > 600 ? 3 : 2)),
                        mainAxisExtent: 150,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                      ),
                      itemBuilder: (ctx, idx) {
                        final cat = _filteredGrid[idx];
                        final id = cat['label']!;
                        final isFav = favorites.contains(id);
                        return GestureDetector(
                          onTap: () =>
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Open ${cat['label']}')),
                              ),
                          onLongPress: () => setState(() {
                            if (isFav) {
                              favorites.remove(id);
                            } else {
                              favorites.add(id);
                            }
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border.all(color: Colors.grey.shade100),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 12,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Stack(
                                  children: [
                                    Container(
                                      width: 72,
                                      height: 72,
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Image.network(
                                        cat['image']!,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                    Positioned(
                                      right: 2,
                                      top: 0,
                                      child: GestureDetector(
                                        onTap: () => setState(() {
                                          if (isFav) {
                                            favorites.remove(id);
                                          } else {
                                            favorites.add(id);
                                          }
                                        }),
                                        child: CircleAvatar(
                                          radius: 14,
                                          backgroundColor: isFav
                                              ? Colors.red.shade400
                                              : Colors.white,
                                          child: Icon(
                                            isFav
                                                ? Icons.favorite
                                                : Icons.favorite_border,
                                            size: 16,
                                            color: isFav
                                                ? Colors.white
                                                : Colors.black54,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  cat['label']!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Explore',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
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

// --- Featured Card (resilient to tight parent heights) ---
class _FeaturedCard extends StatelessWidget {
  final String title;
  final String subtitle;
  const _FeaturedCard({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      // Fill the height given by the parent SizedBox (e.g. 84)
      height: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accentColor.withOpacity(0.12), Colors.white],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: Image.network(
              'https://i.imgur.com/3aXk3kK.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 10),
          // Use Expanded horizontally; vertically keep minimal size and center content
          Expanded(
            child: Column(
              mainAxisSize:
                  MainAxisSize.min, // IMPORTANT: don't expand vertically
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
