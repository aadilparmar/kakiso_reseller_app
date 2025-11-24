import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kakiso_reseller_app/models/categories.dart';
import 'package:kakiso_reseller_app/screens/dashboard/categories/categories_detail_page/categories_detail_page.dart';
import 'package:kakiso_reseller_app/services/api_services.dart';

// --- IMPORT CATEGORY DETAILS PAGE ---
class CuratedCollections extends StatefulWidget {
  const CuratedCollections({super.key});

  @override
  State<CuratedCollections> createState() => _CuratedCollectionsState();
}

class _CuratedCollectionsState extends State<CuratedCollections> {
  List<CategoryModel> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final data = await ApiService.fetchCategories();
      // We need at least 3 categories for the mosaic
      if (data.length >= 3 && mounted) {
        setState(() {
          _categories = data.take(3).toList(); // Take top 3
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _categories.length < 3) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- HEADER ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              const Text(
                "Curated",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                "Collections",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                  color: Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),

        // --- MOSAIC GRID ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SizedBox(
            height: 280, // Total height of the mosaic
            child: Row(
              children: [
                // --- LEFT COLUMN (1 Tall Card) ---
                Expanded(
                  flex: 5,
                  child: _buildMosaicCard(
                    _categories[0],
                    height: 280,
                    isMain: true,
                  ),
                ),
                const SizedBox(width: 10),

                // --- RIGHT COLUMN (2 Stacked Cards) ---
                Expanded(
                  flex: 4,
                  child: Column(
                    children: [
                      Expanded(
                        child: _buildMosaicCard(_categories[1], height: 135),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: _buildMosaicCard(_categories[2], height: 135),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMosaicCard(
    CategoryModel category, {
    required double height,
    bool isMain = false,
  }) {
    return GestureDetector(
      onTap: () {
        // --- NAVIGATION LOGIC ---
        Get.to(
          () => CategoryDetailsPage(
            categoryId: category.id,
            categoryName: category.name,
          ),
          transition: Transition.fadeIn,
          duration: const Duration(milliseconds: 300),
        );
      },
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Image
              Image.network(
                category.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) =>
                    Container(color: Colors.grey.shade100),
              ),

              // 2. Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),

              // 3. Text Content
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isMain)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: const Text(
                          "EDITOR'S PICK",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    Text(
                      category.name.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: isMain ? 22 : 14,
                        fontFamily: 'Poppins',
                        height: 1.1,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isMain)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Row(
                          children: const [
                            Text(
                              "Shop Now",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons
                                  .arrow_forward, // Using Standard Icon for Safety
                              color: Colors.white70,
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
