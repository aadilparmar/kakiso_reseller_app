import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kakiso_reseller_app/models/categories.dart';
import 'package:kakiso_reseller_app/screens/dashboard/categories/categories_detail_page/categories_detail_page.dart';
import 'package:kakiso_reseller_app/services/api_services.dart';

// --- IMPORT CATEGORY DETAILS PAGE ---

class StorySection extends StatefulWidget {
  const StorySection({super.key});

  @override
  State<StorySection> createState() => _StorySectionState();
}

class _StorySectionState extends State<StorySection> {
  List<CategoryModel> _stories = [];

  @override
  void initState() {
    super.initState();
    _fetchStories();
  }

  Future<void> _fetchStories() async {
    try {
      final categories = await ApiService.fetchCategories();
      if (mounted) {
        setState(() {
          _stories = categories;
        });
      }
    } catch (e) {
      if (mounted) ;
    }
  }

  // 🔥 NOTE: _openStoryPreview REMOVED – no popup, direct navigation only

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- HEADER ---
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: const [
              // Purple Accent Bar
              SizedBox(
                width: 4,
                height: 24,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: Color(0xFF8134AF)),
                ),
              ),
              SizedBox(width: 8),

              Text(
                'Featured',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
              SizedBox(width: 6),
              Text(
                'Categories',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8134AF),
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),

        // --- HORIZONTAL LIST WITHOUT POPUP ---
        Container(
          height: 115,
          margin: const EdgeInsets.only(top: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 16),
            itemCount: _stories.length,
            itemBuilder: (context, index) {
              final story = _stories[index];

              return GestureDetector(
                onTap: () {
                  // 👇 Directly open CategoryDetailsPage
                  Get.to(
                    () => CategoryDetailsPage(
                      categoryId: story.id,
                      categoryName: story.name,
                    ),
                    transition: Transition.fadeIn,
                    duration: const Duration(milliseconds: 300),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFFF58529),
                              Color(0xFFDD2A7B),
                              Color(0xFF8134AF),
                            ],
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: CircleAvatar(
                            radius: 32,
                            backgroundColor: Colors.grey[100],
                            backgroundImage: NetworkImage(story.imageUrl),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 70,
                        child: Text(
                          story.name,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Poppins',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
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
    );
  }
}
